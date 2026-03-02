{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.server.matrix-rtc;

  livekitKeyFile = "/run/livekit.key";
in
{
  options.server.matrix-rtc = {
    enable = lib.mkEnableOption "Livekit for Element Call";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "livekit.${config.domain}";
    };
    homeservers = lib.mkOption {
      type = lib.types.listOf lib.types.nonEmptyStr;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    services.livekit = {
      enable = true;
      openFirewall = true;
      # settings = {
      #   rtc.use_external_ip = true;
      # };
      settings.room.auto_create = false;
      keyFile = livekitKeyFile;
    };
    services.lk-jwt-service = {
      enable = true;
      # can be on the same virtualHost as synapse
      livekitUrl = "wss://${cfg.domain}/livekit/sfu";
      keyFile = livekitKeyFile;
    };
    # generate the key when needed
    systemd.services.livekit-key = {
      before = [
        "lk-jwt-service.service"
        "livekit.service"
      ];
      wantedBy = [ "multi-user.target" ];
      path = with pkgs; [
        livekit
        coreutils
        gawk
      ];
      script = ''
        echo "Key missing, generating key"
        echo "lk-jwt-service: $(livekit-server generate-keys | tail -1 | awk '{print $3}')" > "${livekitKeyFile}"
      '';
      serviceConfig.Type = "oneshot";
      unitConfig.ConditionPathExists = "!${livekitKeyFile}";
    };

    services.nginx.virtualHosts.${cfg.domain} = {
      enableACME = true;
      forceSSL = true;
      locations = {
        "^~ /livekit/jwt/" = {
          priority = 400;
          proxyPass = "http://[::1]:${toString config.services.lk-jwt-service.port}/";
        };
        "^~ /livekit/sfu/" = {
          extraConfig = ''
            proxy_send_timeout 120;
            proxy_read_timeout 120;
            proxy_buffering off;

            proxy_set_header Accept-Encoding gzip;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
          '';

          priority = 400;
          proxyPass = "http://[::1]:${toString config.services.livekit.settings.port}/";
          proxyWebsockets = true;
        };
      };
    };

    # restrict access to livekit room creation to a homeserver
    systemd.services.lk-jwt-service.environment.LIVEKIT_FULL_ACCESS_HOMESERVERS =
      lib.concatStringsSep "," cfg.homeservers;

  };
}

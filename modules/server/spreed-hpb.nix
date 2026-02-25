{
  config,
  lib,
  ...
}:
let
  cfg = config.server.spreed-hpb;
in
{
  options.server.spreed-hpb = {
    enable = lib.mkEnableOption "High performance backend for Nextcloud Talk";
    hashkeyFile = lib.mkOption {
      type = lib.types.path;
    };
    blockkeyFile = lib.mkOption {
      type = lib.types.path;
    };
    internalsecretFile = lib.mkOption {
      type = lib.types.path;
    };
    nextcloudsecretFile = lib.mkOption {
      type = lib.types.path;
    };
  };

  config = lib.mkIf cfg.enable {
    server.turn.enable = true;

    impermanence.directories = [ config.services.nextcloud-spreed-signaling.stateDir ];

    services.nextcloud-spreed-signaling = {
      enable = true;
      hostName = "talk.${config.domain}";
      configureNginx = true;
      settings = {
        http.listen = "127.0.0.1:9000";
        turn = {
          servers = [
            "turn:${config.server.turn.realm}:3478?transport=udp"
            "turn:${config.server.turn.realm}:3478?transport=tcp"
          ];
          secretFile = config.server.turn.secretFile;
        };
        clients.internalsecretFile = cfg.internalsecretFile;
        sessions = {
          hashkeyFile = cfg.hashkeyFile;
          blockkeyFile = cfg.blockkeyFile;
        };
      };
      backends.nextcloud = {
        urls = [
          "https://nc.kirottu.com"
        ];
        secretFile = cfg.nextcloudsecretFile;
      };
    };

    services.nginx.virtualHosts.${config.services.nextcloud-spreed-signaling.hostName} = {
      enableACME = true;
      forceSSL = true;
    };
  };
}

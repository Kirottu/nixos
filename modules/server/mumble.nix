{
  config,
  lib,
  pkgs,
  myPkgs,
  ...
}:
let
  cfg = config.server.mumble;
  mumzicState = "/var/lib/mumzic";
in
{
  options.server.mumble = {
    enable = lib.mkEnableOption "Murmur for Mumble";
    musicbot.enable = lib.mkEnableOption "Music bot";
  };

  config = lib.mkIf cfg.enable {
    impermanence.directories = [
      config.services.murmur.stateDir
    ]
    ++ lib.optional cfg.musicbot.enable mumzicState;

    services.murmur =

      let
        certDir = config.security.acme.certs.${config.domain}.directory;
      in
      {
        enable = true;
        openFirewall = true;
        sslCert = "${certDir}/full.pem";
        sslKey = "${certDir}/key.pem";
        welcometext = "Epämäärämääräistä möminää ja suolaista paskapuhumista.";
        bandwidth = 128000;
      };

    security.acme.certs.${config.domain}.reloadServices = [ "murmur.service" ];

    users.users."murmur".extraGroups = [ "nginx" ];

    # services.botamusique = lib.mkIf cfg.botamusique.enable {
    #   enable = true;
    #   settings.bot = {
    #     username = "MANKKA SAATANA";
    #     comment = "Jumalauta jätkät halusitte radion niin tässähän se olis";
    #   };
    # };

    users.users."mumzic" = lib.mkIf cfg.musicbot.enable {
      description = "Mumzic";
      home = mumzicState;
      createHome = true;
      uid = 116; # Free
      group = "mumzic";
    };
    users.groups."mumzic" = lib.mkIf cfg.musicbot.enable {
      gid = 116; # Free
    };

    systemd.services.mumzic = lib.mkIf cfg.musicbot.enable {
      after = [
        "network.target"
        "murmur.service"
      ];
      wantedBy = [ "multi-user.target" ];

      environment.HOME = "/var/lib/mumzic";

      serviceConfig = {
        ExecStart = "${
          lib.getExe (pkgs.callPackage myPkgs.mumzic { })
        } -username 'MANKKA SAATANA' -server ${config.domain}";
        Restart = "always"; # the bot exits when the server connection is lost

        User = "mumzic";
        Group = "mumzic";
        WorkingDirectory = "/var/lib/mumzic";
        RuntimeDirectory = "mumzic";
        RuntimeDirectoryMode = "0700";

        # Hardening
        CapabilityBoundingSet = [ "" ];
        IPAddressDeny = [
          "link-local"
          "multicast"
        ];
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        ProcSubset = "pid";
        PrivateDevices = true;
        PrivateUsers = true;
        PrivateTmp = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "strict";
        RestrictNamespaces = true;
        RestrictRealtime = true;
        ReadWritePaths = [
          mumzicState
        ];
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
        ];
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service @resources"
          "~@privileged"
        ];
        UMask = "0077";
      };
    };
  };
}

{
  lib,
  config,
  pkgs,
  ...
}:
let
  ncDomain = "nc.${config.domain}";
  collaboraDomain = "collabora.${config.domain}";
in
{
  config = {
    impermanence.directories = [
      "/var/lib/nextcloud"
    ];

    sops.secrets = {
      "nextcloud/adminpass" = {
        sopsFile = ../../secrets/server.yaml;
      };
      "nextcloud/dbpass" = {
        sopsFile = ../../secrets/server.yaml;
      };
    };

    services.nextcloud = {
      enable = true;
      package = pkgs.nextcloud31;
      https = true;
      hostName = ncDomain;
      maxUploadSize = "5G";
      database.createLocally = true;
      configureRedis = true;
      settings = {
        overwriteprotocol = "https";
      };
      config = {
        adminuser = "Kirottu";
        adminpassFile = config.sops.secrets."nextcloud/adminpass".path;
        dbtype = "pgsql";
      };
      autoUpdateApps.enable = true;
      extraApps = {
        inherit (pkgs.nextcloud31Packages.apps)
          calendar
          maps
          richdocuments
          ;
      };
    };

    services.collabora-online = {
      enable = true;
      settings = {
        ssl = {
          enable = false;
          termination = true;
        };

        net = {
          listen = "loopback";
          post_allow.host = [ "::1" ];
        };

        storage.wopi = {
          "@allow" = true;
          host = [ ncDomain ];
        };

        server_name = collaboraDomain;
      };
    };

    services.nginx = {
      virtualHosts.${ncDomain} = {
        forceSSL = true;
        enableACME = true;
      };

      virtualHosts.${collaboraDomain} = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://[::1]:${toString config.services.collabora-online.port}";
          proxyWebsockets = true; # collabora uses websockets
        };
      };
    };
  };
}

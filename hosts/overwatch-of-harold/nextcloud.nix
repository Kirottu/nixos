{
  lib,
  config,
  pkgs,
  ...
}:
let
  ncDomain = "nc.${config.domain}";
  collaboraDomain = "collabora.${config.domain}";
  wopiUpdater = "nextcloud-update-wopi";
  service-notifier = "nextcloud-service-notify@";

  cfg = config.nextcloud;
in
{
  options.nextcloud = {
    enable = lib.mkEnableOption "Nextcloud";
    monitoredServices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

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
      package = pkgs.nextcloud32;
      https = true;
      hostName = ncDomain;
      maxUploadSize = "5G";
      database.createLocally = true;
      configureRedis = true;
      phpOptions = {
        "opcache.interned_strings_buffer" = "12";
      };
      settings = {
        overwriteprotocol = "https";
        log_type = "file";
        loglevel = 2;
      };
      config = {
        adminuser = "Kirottu";
        adminpassFile = config.sops.secrets."nextcloud/adminpass".path;
        dbtype = "pgsql";
      };
      autoUpdateApps.enable = true;
      extraApps = {
        inherit (config.services.nextcloud.package.packages.apps)
          calendar
          deck
          richdocuments
          ;
      };
      poolSettings = {
        pm = "dynamic";
        "pm.max_children" = "120";
        "pm.max_requests" = "500";
        "pm.max_spare_servers" = "86";
        "pm.min_spare_servers" = "28";
        "pm.start_servers" = "28";
        "php_admin_value[memory_limit]" = "1G";
      };
      notify_push = {
        enable = true;
        bendDomainToLocalhost = true;
      };
    };

    # systemd.timers.${wopiUpdater} = {
    #   wantedBy = [ "timers.target" ];
    #   timerConfig = {
    #     OnBootSec = config.services.ddclient.interval;
    #     OnUnitInactiveSec = config.services.ddclient.interval;
    #     Unit = "${wopiUpdater}.service";
    #   };
    # };

    systemd.services = {
      # ${wopiUpdater} = {
      #   path = [
      #     config.services.nextcloud.occ
      #     pkgs.curl
      #   ];
      #   script = ''
      #     curr_wopi=$(nextcloud-occ config:app:get richdocuments wopi_allowlist)
      #     public_ip=$(curl -s https://api.ipify.org)

      #     if [ "$public_ip" = "" ]; then
      #       echo "Not connected to the internet"

      #     elif [[ "$curr_wopi" == *"$public_ip"* ]]; then
      #       echo "WOPI allow up to date"

      #     else
      #       echo "Setting WOPI allow list"
      #       nextcloud-occ config:app:set richdocuments wopi_allowlist --value="$public_ip"

      #     fi
      #   '';
      #   after = [ "network.target" ];
      #   serviceConfig = {
      #     Type = "oneshot";
      #   };
      # };
      ${service-notifier} = {
        environment.SERVICE_ID = "%i";
        path = [
          config.services.nextcloud.occ
          pkgs.systemd
        ];
        script = ''
          STATUS=$(systemctl status "$SERVICE_ID" ||:)

          nextcloud-occ notification:generate \
            "${config.services.nextcloud.config.adminuser}" \
            "systemd service $SERVICE_ID failed" \
            -l "$STATUS"
        '';
      };
    }
    // (lib.genAttrs cfg.monitoredServices (service: {
      onFailure = [ "${service-notifier}%i.service" ];
    }));

    # systemd.services.nixos-upgrade = lib.mkIf config.system.autoUpgrade.enable {
    #   onFailure = [ "${service-notifier}%i.service" ];
    # };

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

        logging.disable_server_audit = true;

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

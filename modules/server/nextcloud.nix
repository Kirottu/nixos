{
  lib,
  config,
  pkgs,
  ...
}:
let
  collaboraDomain = "collabora.${config.domain}";
  wopiUpdater = "nextcloud-update-wopi";
  service-notifier = "nextcloud-service-notify@";

  cfg = config.server.nextcloud;
in
{
  options.server.nextcloud = {
    enable = lib.mkEnableOption "Nextcloud";
    monitoredServices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "nc.${config.domain}";
    };
    adminPass = lib.mkOption {
      type = lib.types.path;
    };
    dbPass = lib.mkOption {
      type = lib.types.path;
    };
    emailPass = lib.mkOption {
      type = lib.types.path;
    };
  };

  config = lib.mkIf cfg.enable {
    impermanence.directories = [
      config.services.nextcloud.home
    ];

    services.nextcloud = {
      enable = true;
      package = pkgs.nextcloud33;
      https = true;
      hostName = cfg.domain;
      maxUploadSize = "5G";
      database.createLocally = true;
      configureRedis = true;
      secrets = {
        mail_smtppassword = cfg.emailPass;
      };
      phpOptions = {
        "opcache.interned_strings_buffer" = "12";
      };
      settings = {
        overwriteprotocol = "https";
        log_type = "file";
        loglevel = 2;

        mail_smtpsecure = "ssl";
        mail_smtpport = config.server.stalwart.automation.port;
        mail_smtpname = "noreply";
        mail_from_address = "noreply";
        mail_domain = config.domain;
        mail_smtphost = config.server.stalwart.hostname;
        mail_smtpauth = true;
        enabledPreviewProviders = [
          "OC\\Preview\\PNG"
          "OC\\Preview\\JPEG"
          "OC\\Preview\\GIF"
          "OC\\Preview\\BMP"
          "OC\\Preview\\XBitmap"
          "OC\\Preview\\Krita"
          "OC\\Preview\\WebP"
          "OC\\Preview\\MarkDown"
          "OC\\Preview\\TXT"
          "OC\\Preview\\OpenDocument"
          "OC\\Preview\\Movie"
          "OC\\Preview\\MP4"
          "OC\\Preview\\AVI"
          "OC\\Preview\\MKV"
          "OC\\Preview\\WEBM"
        ];
      };
      config = {
        adminuser = "Kirottu";
        adminpassFile = cfg.adminPass;
        dbtype = "pgsql";
      };
      # appstoreEnable = true;
      # autoUpdateApps.enable = true;
      extraApps = {
        inherit (config.services.nextcloud.package.packages.apps)
          calendar
          deck
          richdocuments
          # memories
          user_oidc
          spreed
          # tasks
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

    environment.systemPackages = [
      pkgs.ffmpeg-headless
    ];

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
          host = [ cfg.domain ];
        };

        logging.disable_server_audit = true;

        server_name = collaboraDomain;
      };
    };

    services.nginx = {
      virtualHosts.${cfg.domain} = {
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

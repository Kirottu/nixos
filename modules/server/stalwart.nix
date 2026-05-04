{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.server.stalwart;
  port = 9002;
  smtp-automation = "smtp-automation";
  directory-automation = "in-memory";
  directory-oidc = "keycloak";
in
{
  options.server.stalwart = {
    enable = lib.mkEnableOption "Stalwart";
    hostname = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "mail.${config.domain}";
    };
    adminPassFile = lib.mkOption {
      type = lib.types.path;
    };
    dbPassFile = lib.mkOption {
      type = lib.types.path;
    };
    webmailSecretPath = lib.mkOption {
      type = lib.types.path;
    };
    automation = {
      principals = lib.mkOption {
        type = lib.types.listOf lib.types.attrs;
        default = [ ];
      };
      port = lib.mkOption {
        type = lib.types.number;
        default = 466;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    impermanence.directories = [
      config.services.stalwart.dataDir
      {
        directory = "/var/lib/roundcube";
        user = "roundcube";
        group = "roundcube";
      }
    ];

    services.stalwart = {
      enable = true;
      openFirewall = true;
      stateVersion = "25.11";
      settings = lib.mkForce {
        server = {
          hostname = cfg.hostname;
          listener = {
            smtp = {
              protocol = "smtp";
              bind = "[::]:25";
            };
            smpts = {
              protocol = "smtp";
              bind = "[::]:465";
              tls.implicit = true;
            };
            submission = {
              protocol = "smtp";
              bind = "[::]:587";
            };
            ${smtp-automation} = {
              protocol = "smtp";
              bind = "[::]:${toString cfg.automation.port}";
              tls.implicit = true;
            };
            imaps = {
              protocol = "imap";
              bind = "[::]:993";
              tls.implicit = true;
            };
            web = {
              protocol = "http";
              bind = "[::1]:${toString port}";
            };
          };
        };
        certificate.default = {
          cert = "%{file:${config.security.acme.certs.${cfg.hostname}.directory}/cert.pem}%";
          private-key = "%{file:${config.security.acme.certs.${cfg.hostname}.directory}/key.pem}%";
        };
        lookup.default = {
          hostname = cfg.hostname;
          domain = config.domain;
        };
        storage = {
          encryption = {
            enable = true;
            append = true;
          };
          data = "postgresql";
          blob = "postgresql";
          fts = "postgresql";
          lookup = "postgresql";
          directory = "keycloak";
          # directory = "in-memory";
          # directory = "internal";
        };
        store."postgresql" = {
          type = "postgresql";
          host = "localhost";
          port = 5432;
          database = "stalwart_mail";
          user = "stalwart_mail";
          password = "%{file:${cfg.dbPassFile}}%";
          compression = "lz4";
        };
        directory.${directory-oidc} = {
          type = "oidc";
          timeout = "1s";
          endpoint.url = "https://${config.server.keycloak.hostname}/realms/main/protocol/openid-connect/userinfo";
          endpoint.method = "userinfo";
          fields.email = "email";
          fields.username = "preferred_username";
          fields.full-name = "name";
        };
        directory.${directory-automation} = {
          type = "memory";
          principals = cfg.automation.principals;
        };

        session.auth = {
          directory = [
            {
              "if" = "listener == '${smtp-automation}'";
              "then" = "'${directory-automation}'";
            }
            {
              "else" = "'${directory-oidc}'";
            }
          ];
        };

        authentication.fallback-admin = {
          user = "admin";
          secret = "%{file:${cfg.adminPassFile}}%";
        };
        http = {
          use-x-forwarded = true;
        };
        resolver.public-suffix = [
          "file://${pkgs.publicsuffix-list}/share/publicsuffix/public_suffix_list.dat"
        ];
        spam-filter.resource = "file://${config.services.stalwart.package.spam-filter}/spam-filter.toml";
        webadmin = {
          path = "/var/cache/stalwart-mail";
          resource = "file://${config.services.stalwart.package.webadmin}/webadmin.zip";
        };
        # tracer.journal = {
        #   type = "journal";
        #   level = "trace";
        #   enable = true;
        # };
        tracer.log = {
          type = "log";
          path = "/var/lib/stalwart-mail/logs";
          prefix = "stalwart.log";
          rotate = "daily";
          level = "info";
          ansi = false;
          enable = true;
        };
      };
    };

    # Access to TLS keys & shared secrets
    users.users = {
      stalwart-mail.extraGroups = [
        "nginx"
        "keys"
      ];
      nginx.extraGroups = [ "keys" ];
    };

    services.roundcube = {
      enable = true;
      package = pkgs.roundcube.overrideAttrs rec {
        version = "1.7-rc6";
        src = pkgs.fetchurl {
          url = "https://github.com/roundcube/roundcubemail/releases/download/${version}/roundcubemail-${version}-complete.tar.gz";
          sha256 = "sha256-xop89EwvI63HazKDqtsJw9KSG9JO/sHp4U5XknySQmU=";
        };
        patches = [ ];
        installPhase = ''
          mkdir $out
          cp -r * $out/
          ln -sf /etc/roundcube/config.inc.php $out/config/config.inc.php
          rm -rf $out/installer
        '';
      };
      hostName = cfg.hostname;
      configureNginx = true;
      extraConfig = ''
        $config['imap_host'] = 'ssl://${cfg.hostname}';
        $config['smtp_host'] = 'ssl://${cfg.hostname}';

        $config['oauth_provider'] = 'generic';
        $config['oauth_provider_name'] = 'Keycloak';
        $config['oauth_client_id'] = 'roundcube';
        $config['oauth_config_uri'] = 'https://${config.server.keycloak.hostname}/realms/main/.well-known/openid-configuration';
        $config['oauth_identity_fields'] = ['preferred_username'];
        $config['oauth_scope'] = 'openid email profile';
        $config['oauth_client_secret'] = file_get_contents('${cfg.webmailSecretPath}');
        $config['oauth_login_redirect'] = true;
      '';
    };

    services.nginx.virtualHosts.${cfg.hostname} = {
      root = lib.mkForce "${config.services.roundcube.package}/public_html";

      locations."~ ^(/.well-known|/jmap)" = {
        proxyPass = "http://[::1]:${toString port}";
        recommendedProxySettings = true;
      };
    };
  };
}

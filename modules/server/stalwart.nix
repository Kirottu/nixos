{
  config,
  lib,
  ...
}:
let
  cfg = config.server.stalwart;
  port = 9002;
in
{
  options.server.stalwart = {
    enable = lib.mkEnableOption "Stalwart";
    hostname = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "mail.${config.domain}";
    };
    # adminHost = lib.mkOption {
    #   type = lib.types.nonEmptyStr;
    #   default = "admin.mail.${config.domain}";
    # };
    adminPassFile = lib.mkOption {
      type = lib.types.path;
    };
    dbPassFile = lib.mkOption {
      type = lib.types.path;
    };
    webmailSecret = lib.mkOption {
      type = lib.types.nonEmptyStr;
    };
    # principals = lib.mkOption {
    #   type = lib.types.listOf lib.types.attrs;
    #   default = [ ];
    # };
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
      settings = {
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
        # Currently, Stalwart's and other clients' OIDC support is barebones as best. It'll have to wait
        directory."keycloak" = {
          type = "oidc";
          timeout = "1s";
          endpoint.url = "https://${config.server.keycloak.hostname}/realms/main/protocol/openid-connect/userinfo";
          endpoint.method = "userinfo";
          fields.email = "email";
          fields.username = "preferred_username";
          fields.full-name = "name";
          lookup.domains = [ config.domain ];
        };
        # directory."in-memory" = {
        #   type = "memory";
        #   principals = cfg.principals;
        # };
        directory."internal" = {
          type = "internal";
          store = "postgresql";
        };
        authentication.fallback-admin = {
          user = "admin";
          secret = "%{file:${cfg.adminPassFile}}%";
        };
        http = {
          use-x-forwarded = true;
        };
      };
    };

    # Access to TLS keys & shared secrets
    users.users.stalwart-mail.extraGroups = [
      "nginx"
      # "keys"
    ];

    # A bit hacky but it must be done, the default NixOS module doesn't provide a way to set secrets
    sops.templates."roundcube-config" = lib.mkIf config.security.sops.enable {
      content = ''
        $config['oauth_client_secret'] = '${config.sops.placeholder.${cfg.webmailSecret}}';
      '';
      path = "/etc/roundcube/default.inc.php";
    };

    services.roundcube = {
      enable = true;
      hostName = cfg.hostname;
      configureNginx = true;
      extraConfig = ''
        $config['imap_host'] = 'ssl://${cfg.hostname}';
        $config['smtp_host'] = 'ssl://${cfg.hostname}';

        $config['oauth_provider'] = 'generic';
        $config['oauth_provider_name'] = 'Keycloak';
        $config['oauth_client_id'] = 'roundcube';
        $config['oauth_config_uri'] = 'https://${config.server.keycloak.hostname}/realms/main/.well-known/openid-configuration';
        $config['oauth_scope'] = 'email profile openid';
        $config['oauth_login_redirect'] = true;
      '';
    };

    # services.nginx.virtualHosts.${cfg.adminHost} = {
    #   forceSSL = true;
    #   enableACME = true;
    #   locations."/" = {
    #     proxyPass = "http://[::1]:${toString port}";
    #     recommendedProxySettings = true;
    #   };
    # };
  };
}

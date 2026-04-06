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
    adminPassFile = lib.mkOption {
      type = lib.types.path;
    };
    dbPassFile = lib.mkOption {
      type = lib.types.path;
    };
    # principals = lib.mkOption {
    #   type = lib.types.listOf lib.types.attrs;
    #   default = [ ];
    # };
  };

  config = lib.mkIf cfg.enable {
    impermanence.directories = [ config.services.stalwart.dataDir ];

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
          # directory = "keycloak";
          # directory = "in-memory";
          directory = "internal";
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
        # directory."keycloak" = {
        #   type = "oidc";
        #   timeout = "1s";
        #   endpoint.url = "https://${config.server.keycloak.hostname}/realms/main/protocol/openid-connect/userinfo";
        #   endpoint.method = "userinfo";
        #   fields.email = "email";
        #   fields.username = "preferred_username";
        #   fields.full-name = "name";
        #   lookup.domains = [ config.domain ];
        # };
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

    services.nginx.virtualHosts.${cfg.hostname} = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://[::1]:${toString port}";
        recommendedProxySettings = true;
      };
    };
  };
}

{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.server.keycloak;
  port = 9001;
in
{
  options.server.keycloak = {
    enable = lib.mkEnableOption "Keycloak IDP";
    hostname = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "idp.${config.domain}";
    };
  };

  config = lib.mkIf cfg.enable {
    services.keycloak = {
      enable = true;
      settings = {
        http-enabled = true;
        http-port = port;
        hostname = "https://${cfg.hostname}";
        hostname-admin = "http://localhost:${toString port}";
        proxy-headers = "xforwarded";
      };
      initialAdminPassword = "changeme";
      plugins = [
        pkgs.keycloak.plugins.junixsocket-common
        pkgs.keycloak.plugins.junixsocket-native-common
      ];
      database = {
        host = "/run/postgresql";
      };
    };

    services.nginx.virtualHosts.${cfg.hostname} = {
      enableACME = true;
      forceSSL = true;
      locations."~ ^(/realms|/resources|/.well-known)" = {
        proxyPass = "http://[::1]:${toString port}";
        recommendedProxySettings = true;
      };
    };

    services.postgresql = {
      ensureDatabases = [ config.services.keycloak.database.name ];
      ensureUsers = [
        {
          name = config.services.keycloak.database.username;
          ensureDBOwnership = true;
        }
      ];
    };
  };
}

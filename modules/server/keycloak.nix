{
  config,
  lib,
  pkgs,
  myPkgs,
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
      plugins = [
        pkgs.keycloak.plugins.junixsocket-common
        pkgs.keycloak.plugins.junixsocket-native-common
        # pkgs.keycloak.plugins.keycloak-restrict-client-auth
        (pkgs.callPackage ({
          maven,
          lib,
          fetchFromGitHub,
        }:

        maven.buildMavenPackage rec {
          pname = "keycloak-restrict-client-auth";
          version = "26.1.0";

          src = fetchFromGitHub {
            owner = "sventorben";
            repo = "keycloak-restrict-client-auth";
            tag = "v${version}";
            hash = "sha256-nQ2AwXhSUu5RY/BbxXE2OXgEb7Zf6FfrGP5tfbgAXk8=";
          };

          mvnHash = "sha256-Q/UKZ4oe7T2pVRb8U0SoyvxUMgUn9grlDJPxlU9wLg4=";

          installPhase = ''
            runHook preInstall
            install -Dm444 -t "$out" target/keycloak-restrict-client-auth.jar
            runHook postInstall
          '';

          meta = {
            homepage = "https://github.com/sventorben/keycloak-restrict-client-auth";
            description = "Keycloak authenticator to restrict authorization on clients";
            license = lib.licenses.mit;
            maintainers = with lib.maintainers; [ leona ];
          };
        }) {})
        # (pkgs.callPackage myPkgs.keycloak-unique-validator { })
      ];
      database = {
        host = "/run/postgresql";
      };
    };

    users.users."keycloak" = {
      extraGroups = [ "keys" ];
      group = "keycloak";
      isSystemUser = true;
    };
    users.groups."keycloak" = { };

    services.nginx.virtualHosts.${cfg.hostname} = {
      enableACME = true;
      forceSSL = true;
      locations."~ ^(/realms|/resources|/.well-known)" = {
        proxyPass = "http://[::1]:${toString port}";
        recommendedProxySettings = true;
      };
      # Redirect requests at the root to the account management portal for the main realm
      locations."/" = {
        return = "301 https://${cfg.hostname}/realms/main/account";
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

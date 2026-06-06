{
  config,
  lib,
  pkgs,
  ...
}:
let
  vwDomain = "vw.${config.domain}";
  cfg = config.server.vaultwarden;
in
{
  options.server.vaultwarden = {
    enable = lib.mkEnableOption "Vaultwarden";
    secrets = lib.mkOption {
      type = lib.types.path;
    };
  };

  config = lib.mkIf cfg.enable {
    impermanence.directories = [
      "/var/lib/vaultwarden"
    ];

    services.vaultwarden = {
      enable = true;
      environmentFile = cfg.secrets;
      config = {
        DOMAIN = "https://${vwDomain}";
        # SIGNUPS_ALLOWED = false;

        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = 8222;
        ROCKET_LOG = "critical";

        SSO_ENABLED = true;
        SSO_ONLY = true;
        SSO_AUTHORITY = "https://${config.server.keycloak.hostname}/realms/main";
        SSO_CLIENT_ID = "vaultwarden";
        SSO_SCOPES = "openid profile email offline_access";
        # SSO_CLIENT_SECRET = <defined in secrets>;

        SMTP_HOST = "${config.server.stalwart.hostname}";
        SMTP_PORT = config.server.stalwart.automation.port;
        SMTP_SECURITY = "force_tls";
        SMTP_FROM = "noreply@${config.domain}";
        SMTP_USERNAME = "noreply";
        # SMTP_PASSWORD = <defined in secrets>;
      };
    };

    services.nginx.virtualHosts.${vwDomain} = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT}";
        recommendedProxySettings = true;
      };
      locations."/admin" = {
        return = 404;
      };
    };

    server.borg.jobs."vaultwarden" =
      let
        tmpDir = "${config.server.borg.tmpDir}/vaultwarden";
      in
      {
        startAt = "weekly";
        readWritePaths = [ tmpDir ];
        preHook = ''
          mkdir -p ${tmpDir}
          ${pkgs.sqlite}/bin/sqlite3 /var/lib/vaultwarden/db.sqlite3 "VACUUM INTO '${tmpDir}/db.sqlite3'"
          if [ -d /var/lib/vaultwarden/attachments ]; then
              cp -r /var/lib/vaultwarden/attachments ${tmpDir}/attachments
          fi

          chown -R vaultwarden:vaultwarden ${tmpDir}
        '';
        paths = [ tmpDir ];
        postHook = ''
          rm -r ${tmpDir}
        '';
      };
  };
}

{
  config,
  lib,
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
        SIGNUPS_ALLOWED = false;

        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = 8222;
        ROCKET_LOG = "critical";

        # SSO_ENABLED = true;
        # SSO_ONLY = true;

        SMTP_HOST = "${config.server.stalwart.hostname}";
        SMTP_PORT = 465;
        SMTP_SECURITY = "force_tls";
        SMTP_FROM = "Vaultwarden";
        SMTP_USERNAME = "noreply";
        # SMTP_PASSWORD = <defined in secrets>;
      };
    };

    services.nginx.virtualHosts.${vwDomain} = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT}";
      };
    };
  };
}

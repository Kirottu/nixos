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

  config = {
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

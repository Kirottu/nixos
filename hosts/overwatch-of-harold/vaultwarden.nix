{
  config,
  ...
}:
let
  vwDomain = "vw.${config.domain}";
in
{
  config = {
    impermanence.directories = [
      "/var/lib/vaultwarden"
    ];

    sops.secrets."vaultwarden/env".sopsFile = ../../secrets/server.yaml;

    services.vaultwarden = {
      enable = true;
      environmentFile = config.sops.secrets."vaultwarden/env".path;
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

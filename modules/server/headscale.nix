{
  config,
  lib,
  ...
}:
let
  cfg = config.server.headscale;
  port = 9003;
in
{
  options.server.headscale = {
    enable = lib.mkEnableOption "Headscale control server";
    hostname = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "headscale.${config.domain}";
    };
    tailnet = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "tailnet.${config.domain}";
    };
    clientSecret = lib.mkOption {
      type = lib.types.path;
    };
  };

  config = lib.mkIf cfg.enable {
    impermanence.directories = [
      {
        directory = "/var/lib/headscale";
        user = "headscale";
        group = "headscale";
      }
    ];

    services.headscale = {
      enable = true;
      address = "[::1]";
      inherit port;
      settings = {
        server_url = "https://${cfg.hostname}";
        dns = {
          base_domain = cfg.tailnet;
          nameservers.global = [
            "1.1.1.1"
            "1.0.0.1"
          ];
        };
        oidc = {
          client_id = "headscale";
          client_secret_path = cfg.clientSecret;
          pkce.enabled = true;
          issuer = "https://${config.server.keycloak.hostname}/realms/main";
        };
        # coTURN already occupies the STUN port, oh well.
        derp.server.enabled = false;
      };
    };

    users.users.headscale.extraGroups = [ "keys" ];

    services.nginx.virtualHosts.${cfg.hostname} = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://[::1]:${toString port}";
        recommendedProxySettings = true;
        proxyWebsockets = true;
      };
    };
  };
}

{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.server.forgejo;
in
{
  options.server.forgejo = {
    enable = lib.mkEnableOption "Forgejo";
    domain = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "git.${config.domain}";
    };
    clientSecretFile = lib.mkOption {
      type = lib.types.path;
    };
  };

  config = lib.mkIf cfg.enable {
    impermanence.directories = [
      {
        directory = config.services.forgejo.stateDir;
        user = config.services.forgejo.user;
        group = config.services.forgejo.group;
      }
    ];

    services.openssh.settings.AllowUsers = [ config.services.forgejo.user ];

    services.forgejo = {
      enable = true;
      package = pkgs.forgejo;
      database.type = "postgres";
      settings = {
        server = {
          DOMAIN = cfg.domain;
          ROOT_URL = "https://${cfg.domain}";
          HTTP_PORT = 8084;
          SSH_PORT = lib.head config.services.openssh.ports;
        };
        openid = {
          ENABLE_OPENID_SIGNIN = false;
          ENABLE_OPENID_SIGNUP = true;
          WHITELISTED_URIS = config.server.keycloak.hostname;
        };
        service = {
          DISABLE_REGISTRATION = false;
          ALLOW_ONLY_EXTERNAL_REGISTRATION = true;
          SHOW_REGISTRATION_BUTTON = false;
        };
      };
    };

    systemd.services.forgejo.preStart =
      let
        cmd = lib.getExe config.services.forgejo.package;
      in
      ''
        ${cmd} admin auth add-oauth \
          --provider=openidConnect \
          --name=keycloak \
          --key=forgejo \
          --secret="$(cat ${cfg.clientSecretFile})" \
          --auto-discover-url=https://${config.server.keycloak.hostname}/realms/main/.well-known/openid-configuration \
          --scopes="email profile groups" || true
      '';

    services.nginx.virtualHosts.${cfg.domain} = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.forgejo.settings.server.HTTP_PORT}";
        recommendedProxySettings = true;
      };
    };
  };
}

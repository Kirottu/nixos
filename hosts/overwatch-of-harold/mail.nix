{ config, lib, ... }:
let
  mxName = "mx1.${config.domain}";
  webPort = 8000;
in
{
  options.mail.enable = lib.mkEnableOption "Mail";
  config = lib.mkIf config.mail.enable {
    impermanence.directories = [ "/var/lib/stalwart-mail" ];

    users.users."stalwart-mail".extraGroups = [ "nginx" ];

    services.stalwart-mail = {
      enable = true;
      openFirewall = true;
      settings = {
        server = {
          hostname = mxName;
          tls = {
            enable = true;
            implicit = true;
          };
          listener = {
            smpt = {
              protocol = "smtp";
              bind = "[::]:25";
            };
            smpts = {
              protocol = "smtp";
              bind = "[::]:465";
              tls = true;
            };
            imaps = {
              bind = "[::]:993";
              protocol = "imap";
              tls = true;
            };
            web = {
              protocol = "http";
              bind = "[::1]:${toString webPort}";
            };
          };
        };
        lookup.default = {
          hostname = mxName;
          domain = config.domain;
        };
        certificate.default = {
          cert = "%{file:/var/lib/acme/${config.domain}/cert.pem}%";
          private-key = "%{file:/var/lib/acme/${config.domain}/key.pem}%";
        };
        authentication.fallback-admin = {
          user = "admin";
          secret = "admin";
        };
      };
    };

    services.nginx.virtualHosts."mail.${config.domain}" = {

      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://[::1]:${toString webPort}";
      };
    };
  };
}

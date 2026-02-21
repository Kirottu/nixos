{ config, lib, ... }:
{
  config = {
    impermanence.directories = [ "/var/lib/acme" ];
    security.acme = {
      acceptTerms = true;
      defaults.email = "arnovaara@kirottu.com";
    };

    # services.nginx = {
    #   enable = true;
    #   virtualHosts.${config.domain} = {
    #     forceSSL = true;
    #     enableACME = true;
    #     reuseport = true;
    #   };
    # };

    users.users."nginx".extraGroups = [ "acme" ];
  };
}

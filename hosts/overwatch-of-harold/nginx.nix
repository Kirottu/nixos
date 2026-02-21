{ config, lib, ... }:
{
  config = {
    impermanence.directories = [ "/var/lib/acme" ];

    services.nginx = {
      enable = true;
      # virtualHosts.${config.domain} = {
      #   forceSSL = true;
      #   enableACME = true;
      #   reuseport = true;
      # };
    };

    users.users."nginx".extraGroups = [ "acme" ];
  };
}

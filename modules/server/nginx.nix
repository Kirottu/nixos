{ config, lib, ... }:
{
  config = lib.mkIf (config.devices.class == "server") {
    impermanence.directories = [ "/var/lib/acme" ];

    services.nginx = {
      enable = true;
      experimentalZstdSettings = true;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;
    };

    users.users."nginx".extraGroups = [ "acme" ];
  };
}

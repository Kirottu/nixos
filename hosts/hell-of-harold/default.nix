{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./hardware-config.nix
    ./synapse.nix
    ../../modules
  ];

  config = {
    devices.class = "server";
    domain = "kirottu.com";

    synapse.enable = true;

    impermanence = {
      enable = true;
      directories = [
        "/var/lib/postgresql"
      ];
    };

    services.postgresql = {
      enable = true;
    };

    services.nginx = {
      enable = true;
      virtualHosts."${config.domain}" = {
        enableACME = true;
        forceSSL = true;
      };
    };

    networking.hostName = "hell-of-harold";

    boot.loader.grub.enable = true;
    boot.loader.grub.device = "/dev/sda";

    hm.programs.helix.enable = lib.mkForce false;
    environment.systemPackages = [ pkgs.neovim ];

    system.stateVersion = "25.11";
    hm.home.stateVersion = "25.11";
  };
}

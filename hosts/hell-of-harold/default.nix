{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./hardware-config.nix
    ../../modules
  ];

  config = {
    devices.class = "server";
    domain = "kirottu.com";

    networking.hostName = "hell-of-harold";

    boot.loader.grub.enable = true;
    boot.loader.grub.device = "/dev/sda";

    hm.programs.helix.enable = lib.mkForce false;
    environment.systemPackages = [ pkgs.neovim ];

    system.stateVersion = "25.05";
    hm.home.stateVersion = "25.05";
  };
}

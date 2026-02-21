{
  config,
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

    system.stateVersion = "25.05";
    hm.home.stateVersion = "25.05";
  };
}

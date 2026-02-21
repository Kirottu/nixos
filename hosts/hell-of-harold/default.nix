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

    system.stateVersion = "25.11";
    hm.home.stateVersion = "25.11";
  };
}

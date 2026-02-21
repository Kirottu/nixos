{ lib, ... }:
{
  options.devices = {
    class = lib.mkOption {
      description = "Class of device";
      type = lib.types.enum [
        "desktop"
        "laptop"
        "server"
      ];
    };
  };

  imports = [
    ./desktop.nix
    ./laptop.nix
    ./graphical.nix
    ./server.nix
    ./base.nix
  ];
}

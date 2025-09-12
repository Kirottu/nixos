{
  config,
  lib,
  pkgs,
  myPkgs,
  ...
}:
{

  options.wiibt.enable = lib.mkEnableOption "Wii BT support for Dolphin Emulator";

  config = lib.mkIf config.wiibt.enable {
    boot.extraModulePackages = [
      ((pkgs.callPackage myPkgs.wii-btusb { kernel = config.boot.kernelPackages.kernel; }))
    ];
  };
}

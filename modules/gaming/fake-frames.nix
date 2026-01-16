{
  config,
  pkgs,
  lib,
  myPkgs,
  ...
}:
{
  options.gaming.fake-frames.enable = lib.mkEnableOption "Fake frames";

  config = lib.mkIf config.gaming.fake-frames.enable {
    environment.systemPackages = [
      (pkgs.callPackage myPkgs.lsfg-vk)
    ];
  };
}

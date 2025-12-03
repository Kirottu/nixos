{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.openrazer.enable = lib.mkEnableOption "Openrazer";

  config = lib.mkIf config.openrazer.enable {
    hardware.openrazer.enable = true;
    environment.systemPackages = with pkgs; [
      openrazer-daemon
      polychromatic
    ];
    mainUser.extraGroups = [ "openrazer" ];
  };
}

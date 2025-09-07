{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (config.devices.class == "laptop") {
    battery.enable = true;
    boot.kernelPackages = pkgs.linuxPackages_latest;
    services.printing = {
      enable = true;
      drivers = [ pkgs.samsung-unified-linux-driver ];
    };
  };
}

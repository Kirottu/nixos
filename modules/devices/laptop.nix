{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (config.devices.class == "laptop") {
    battery.enable = true;
    services.printing = {
      enable = true;
      drivers = [ pkgs.samsung-unified-linux-driver ];
    };
  };
}

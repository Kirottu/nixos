{ config, lib, ... }:
{
  options.bluetooth.enable = lib.mkEnableOption "Bluetooth";

  config = lib.mkIf config.bluetooth.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      input = {
        General = {
          # Fix PS3 controller connection
          ClassicBondedOnly = false;
        };
      };
    };

    services.blueman.enable = true;

    hm.services.blueman-applet.enable = true;

    impermanence.directories = lib.mkIf config.impermanence.enable [
      "/var/lib/bluetooth"
    ];
  };
}

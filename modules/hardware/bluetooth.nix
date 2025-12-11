{
  config,
  lib,
  ...
}:
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

    # hm.services.blueman-applet.enable = true;

    systemd.user.services.blueman-applet = {
      description = "Blueman applet";
      requires = [ "tray.target" ];
      after = [
        "graphical-session.target"
        "tray.target"
      ];
      partOf = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
    };

    impermanence.directories = lib.mkIf config.impermanence.enable [
      "/var/lib/bluetooth"
    ];
  };
}

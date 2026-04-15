{ lib, config, ... }:
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
    graphical = lib.mkOption {
      type = lib.types.bool;
      default = config.devices.class == "desktop" || config.devices.class == "laptop";
    };
  };
}

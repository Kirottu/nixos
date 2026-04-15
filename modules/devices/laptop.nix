{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (config.devices.class == "laptop") {
    battery.enable = true;
    services.scx = {
      enable = true;
      scheduler = "scx_lavd";
      extraArgs = [
        "--autopower"
      ];
      package = pkgs.scx.rustscheds;
    };
    services.printing = {
      enable = true;
      drivers = [ pkgs.samsung-unified-linux-driver ];
    };
  };
}

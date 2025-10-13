{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (config.devices.class == "desktop") {
    networking.firewall.enable = false;

    services.scx = {
      enable = true;
      scheduler = "scx_lavd";
      extraArgs = [
        "--autopower"
      ];
      package = pkgs.scx.rustscheds;
    };

    powerManagement.cpuFreqGovernor = "performance";
  };
}

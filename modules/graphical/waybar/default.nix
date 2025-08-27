{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
{
  options.graphical.waybar = {
    enable = lib.mkEnableOption "Waybar";
  };

  config = lib.mkIf config.graphical.waybar.enable {
    hm.programs.waybar =
      let
        theme = import ./${config.theming.theme}.nix {
          inherit
            config
            lib
            inputs
            pkgs
            ;
        };
      in
      {
        package = pkgs.waybar.overrideAttrs {
          patches = [
            ./disable_layer_switching.patch
          ];
        };
        enable = true;
        systemd = {
          enable = true;
          target = "graphical-session.target";
        };
        settings = theme.settings;
        style = theme.style;
      };
  };
}

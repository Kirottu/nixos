{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.graphical.wayle;
in
{
  options.graphical.wayle.enable = lib.mkEnableOption "Wayle";

  config = lib.mkIf cfg.enable {
    hm.services.wayle = {
      enable = true;
      settings = {
        bar = {
          location = "top";
          layout = [
            {
              desktop = {
                monitor = "*";
                left = [ "niri-workspaces" ];
                center = [ "clock" ];
                right = [ "systray" ];
              };
              laptop = {
                monitor = "*";
                left = [
                  "niri-workspaces"
                  "battery"
                ];
                center = [ "clock" ];
                right = [
                  "brightness"
                  "volume"
                  "systray"
                ];
              };
            }
            .${config.devices.class}
          ];
        };

        modules.niri-workspaces = {
          # display-mode = "icon";
          workspace-map = {
            "chat".label = "󰭹";
            "web-dp1".label = "󰖟";
            "web-dp2".label = "󰖟";
            "web-dp3".label = "󰖟";
            "games".label = "󰸻";
          };
        };

        modules.clock = {
          format = "%H:%M";
          left-click = "dropdown:calendar";
          right-click = "dropdown:weather";
        };

        # modules.volume.middle-click = "wayle audio output-mute";
        # modules.volume.scroll-up = "wayle audio output-inc";
        # modules.volume.scroll-down = "wayle audio output-dec";

        styling = {
          rounding = "full";
          palette = {
            bg = "#ffffffa0";
            fg = "#000000";
            elevated = config.theming.themeAttrs.focus;

          };
        };
      };
    };
  };
}

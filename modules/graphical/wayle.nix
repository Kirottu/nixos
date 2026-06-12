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
    hm.services.wayle.settings =
      let
        deviceClass = config.devices.class;
      in
      {
        bar = {
          location = "top";
          layout = [
            {
              monitor = "*";
              left = [ "niri-workspaces" ];
              center = [ "clock" ];
              right = [
                "brightness"
                "volume"
                "systray"
              ];
            }
            (lib.mkIf (deviceClass == "laptop") {
              extends = "*";
              right = [
                "battery"
                "volume"
                "systray"
              ];
            })
            (lib.mkIf (deviceClass == "desktop") {
              extends = "*";
            })
          ];
        };

        modules.niri-workspaces = {
          label-strategy = "name-only";
          workspace-map."1".icon = "󰭹";
          workspace-map."2" = {
            icon = "󰖟";
            label = "web-dp1";
          };
          workspace-map."3" = {
            icon = "󰖟";
            label = "web-dp2";
          };
          workspace-map."4".label = "games";
          workspace-map."5".icon = "󰢔";
        };

        modules.clock = {
          format = "%H:%M";
          left-click = "dropdown:calendar";
          right-click = "dropdown:weather";
        };

        modules.battery.thresholds = [
          {
            below = 40;
            icon-color = "yellow";
          }
          {
            below = 20;
            icon-color = "#99ccff";
          }
        ];

        modules.brightness.thresholds = [
          {
            below = 20;
            icon-color = "#99ccff";
          }
        ];

        modules.volume.middle-click = "wayle audio output-mute";
        modules.volume.scroll-up = "wayle audio output-inc";
        modules.volume.scroll-down = "wayle audio output-dec";

        modules.systray.tray-item-override = [
          {
            name = "discord*";
            icon = "tb-discord-symbolic";
          }
          {
            name = "*spotify*";
            icon = "tb-spotify-symbolic";
          }
          {
            name = "*steam*";
            icon = "steam-symbolic";
          }
        ];

        styling.stylesheet = ''
          window {
            background-color: #ffffffa0;
            border-radius: 20px;
          }

          .container {
            background: transparent;
          }

          window {
            border-radius: 20px;
            color: black;
          }

          .item,
          .clock,
          .battery,
          .brightness,
          .volume {
            background: transparent;
            border-radius: 20px;
          }

          .focused {
            background-color: #99ccff;
          }
        '';
      };
  };
}

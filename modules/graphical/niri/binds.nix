{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  cfg = config.graphical.niri;
in
{
  config.hm.wayland.windowManager.niri.settings.binds = lib.mkIf cfg.enable (

    lib.mkMerge (
      [
        {
          # Application binds
          "Mod+Return" = {
            spawn = "alacritty";
          };
          "Mod+F4" = {
            spawn = [
              "${lib.getExe pkgs.playerctl}"
              "play-pause"
            ];
          };

          "Mod+Shift+S" = {
            spawn = [
              "systemctl"
              "suspend"
            ];
          };
          "Mod+Shift+L" = {
            spawn = [
              "loginctl"
              "lock-session"
            ];
          };

          # Window management
          "Mod+Shift+Q" = {
            close-window = [ ];
          };

          "Mod+Up" = {
            focus-column-left = [ ];
          };
          "Mod+Down" = {
            focus-column-right = [ ];
          };
          "Mod+Left" = {
            focus-monitor-left = [ ];
          };
          "Mod+Right" = {
            focus-monitor-right = [ ];
          };

          "Mod+Shift+Up" = {
            move-column-left = [ ];
          };
          "Mod+Shift+Down" = {
            move-column-right = [ ];
          };
          "Mod+Shift+Left" = {
            move-column-to-monitor-left = [ ];
          };
          "Mod+Shift+Right" = {
            move-column-to-monitor-right = [ ];
          };

          "Mod+Ctrl+Up" = {
            focus-workspace-up = [ ];
          };
          "Mod+Ctrl+Down" = {
            focus-workspace-down = [ ];
          };
          "Mod+Shift+Ctrl+Up" = {
            move-column-to-workspace-up = [ ];
          };
          "Mod+Shift+Ctrl+Down" = {
            move-column-to-workspace-down = [ ];
          };

          "Mod+F" = {
            maximize-column = [ ];
          };
          "Mod+Shift+F" = {
            fullscreen-window = [ ];
          };

          "Mod+Comma" = {
            set-column-width = "-10%";
          };
          "Mod+Period" = {
            set-column-width = "+10%";
          };

          "Print" = {
            screenshot = [ ];
          };
          "Shift+Print" = {
            screenshot-screen = [ ];
          };
          "Mod+Shift+E" = {
            quit = [ ];
          };
        }
        {
          desktop = { };
          laptop = {
            "Mod+F1" = {
              spawn = [
                "wpctl"
                "set-mute"
                "@DEFAULT_SINK@"
                "toggle"
              ];
            };
            "Mod+F2" = {
              spawn = [
                "wpctl"
                "set-volume"
                "@DEFAULT_SINK@"
                "5%-"
              ];
            };
            "Mod+F3" = {
              spawn = [
                "wpctl"
                "set-volume"
                "@DEFAULT_SINK@"
                "5%+"
              ];
            };

            "Mod+Shift+F2" = {
              spawn = [
                "${lib.getExe pkgs.brightnessctl}"
                "s"
                "5%-"
              ];
            };
            "Mod+Shift+F3" = {
              spawn = [
                "${lib.getExe pkgs.brightnessctl}"
                "s"
                "+5%"
              ];
            };
          };
        }
        .${config.devices.class}
      ]
      ++ builtins.genList (i: {
        "Mod+${toString i}" = {
          focus-workspace = i;
        };
        "Mod+Shift+${toString i}" = {
          move-column-to-workspace = i;
        };
      }) 10
    )
  );
}

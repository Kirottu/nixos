{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
  let cfg = config.graphical.niri; in
{
  config.hm.programs.niri.settings.binds = lib.mkIf cfg.enable (
    with config.hm.lib.niri.actions;
    lib.mkMerge (
      [
        {
          # Application binds
          "Mod+Return".action = spawn "alacritty";
          "Mod+F4".action = spawn "${lib.getExe pkgs.playerctl}" "play-pause";

          "Mod+Shift+S".action = spawn "systemctl" "suspend";
          "Mod+Shift+L".action = spawn "loginctl" "lock-session";

          # Window management
          "Mod+Shift+Q".action = close-window;

          "Mod+Up".action = focus-column-left;
          "Mod+Down".action = focus-column-right;
          "Mod+Left".action = focus-monitor-left;
          "Mod+Right".action = focus-monitor-right;

          "Mod+Shift+Up".action = move-column-left;
          "Mod+Shift+Down".action = move-column-right;
          "Mod+Shift+Left".action = move-column-to-monitor-left;
          "Mod+Shift+Right".action = move-column-to-monitor-right;

          "Mod+Ctrl+Up".action = focus-workspace-up;
          "Mod+Ctrl+Down".action = focus-workspace-down;
          "Mod+Shift+Ctrl+Up".action = move-column-to-workspace-up;
          "Mod+Shift+Ctrl+Down".action = move-column-to-workspace-down;

          "Mod+F".action = maximize-column;
          "Mod+Shift+F".action = fullscreen-window;

          "Mod+Comma".action = set-column-width "-10%";
          "Mod+Period".action = set-column-width "+10%";

          "Print".action = screenshot;
          "Shift+Print".action.screenshot-screen = [ ];
          "Mod+Shift+E".action = quit;
        }
        {
          desktop = { };
          laptop = {
            "Mod+F1".action = spawn "wpctl" "set-mute" "@DEFAULT_SINK@" "toggle";
            "Mod+F2".action = spawn "wpctl" "set-volume" "@DEFAULT_SINK@" "5%-";
            "Mod+F3".action = spawn "wpctl" "set-volume" "@DEFAULT_SINK@" "5%+";

            "Mod+Shift+F2".action = spawn "${lib.getExe pkgs.brightnessctl}" "s" "5%-";
            "Mod+Shift+F3".action = spawn "${lib.getExe pkgs.brightnessctl}" "s" "+5%";
          };
        }
        .${config.devices.class}
        {
          diagonals =
            {
              vertical = {
                "Mod+R" = {
                  repeat = false;
                  action = toggle-overview;
                };
                "Mod+D".action = spawn "anyrun";
              };
              overview = {

              };
            }
            .${config.theming.themeAttrs.subtheme};
        }
        .${config.theming.theme}
      ]
      ++ builtins.genList (i: {
        "Mod+${toString i}".action.focus-workspace = i;
        "Mod+Shift+${toString i}".action.move-column-to-workspace = i;
      }) 10
    ));
}

{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.graphical.screenLocking;
in
{
  options.graphical.screenLocking = {
    gtklock.enable = lib.mkEnableOption "gtklock";
    swayidle = {
      enable = lib.mkEnableOption "swayidle";
      command = lib.mkOption {
        type = lib.types.nonEmptyStr;
        description = "Command to run to lock the screen";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.swayidle.enable {

      hm.services.swayidle = {
        enable = true;
        events = [
          {
            event = "before-sleep";
            inherit (cfg.swayidle) command;
          }
          {
            event = "lock";
            inherit (cfg.swayidle) command;
          }
        ];
      };
    })
    (lib.mkIf cfg.gtklock.enable {
      security.pam.services.gtklock = { };

      graphical.screenLocking.swayidle.command = "${lib.getExe pkgs.gtklock} -d";

      hm.imports = [
        inputs.hm-modules.homeModules.gtklock
      ];
      hm.programs.gtklock = {
        enable = true;
        settings.main = {
          start-hidden = false;
          follow-focus = true;
          time-format = "%H:%M:%S";
        };
        style =
          with config.theming.themeAttrs;
          {
            diagonals = ''
              window {
                background-image: url("${config.theming.wallpaper}");
                background-size: cover;
                background-repeat: no-repeat;
                background-position: center;
                background-color: black;
              }

              #input-label {
                font-size: 0px;
              }

              entry {
                min-height: 40px;
                background:
                  linear-gradient(45deg, transparent 200px, ${l3} 200px, ${l3} 230px, transparent 230px),
                  ${l1};
                border: none;
                box-shadow: 0 0 5px black;
                border-radius: 0;
              }

              button {
                color: transparent;
                background: transparent;
                font-size: 0px;
                min-width: 0px;
              }
            '';
          }
          .${config.theming.theme};
      };

    })
  ];
}

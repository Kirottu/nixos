{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.graphical.ironbar;
in
{
  options.graphical.ironbar.enable = lib.mkEnableOption "Ironbar";

  config = lib.mkIf cfg.enable {
    hm.imports = [ inputs.ironbar.homeManagerModules.ironbar ];

    programs.ironbar = lib.mkMerge [
      {
        enable = true;
        package = pkgs.ironbar;
        systemd = true;
      }
      {
        bliss = {
          config = lib.mkMerge [
            {
              name = "bar";
              start_hidden = true;
              position = "top";
              height = 50;
            }
            {
              laptop = {
                start = [
                  {
                    type = "workspaces";
                    name_map = {
                      "chat" = "󰭹";
                      "games" = "󰸻";
                      "web" = "󰖟";
                    };
                  }
                  { type = "battery"; }
                ];
                center = [
                  { type = "clock"; }
                ];
                end = [
                  { type = "brightness"; }
                  { type = "volume"; }
                  { type = "tray"; }
                ];
              };
              desktop = {
                start = [
                  {
                    type = "workspaces";
                    name_map = {
                      "chat" = "󰭹";
                      "web-dp1" = "󰖟";
                      "web-dp2" = "󰖟";
                      "web-dp3" = "󰖟";
                      "games" = "󰸻";
                      "vr" = "󰢔";
                    };
                  }
                ];
                center = [
                  { type = "clock"; }
                ];
                end = [
                  { type = "tray"; }
                ];
              };
            }
            .${config.devices.class}
          ];
          #           style = ''

          # '';
        };
      }
      .${config.theming.theme}
    ];
  };
}

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
    hm.imports = [ inputs.ironbar.homeManagerModules.default ];

    hm.programs.ironbar = lib.mkMerge [
      {
        enable = true;
        # package = pkgs.ironbar;
        systemd = true;
      }
      {
        bliss = {
          config =
            let
              margin = 10;
            in
            lib.mkMerge [
              {
                name = "bar";
                start_hidden = true;
                position = "top";
                height = 50;
                margin = {
                  top = margin;
                  left = margin;
                  bottom = margin;
                  right = margin;
                };
              }
              {
                laptop = {
                  start = [
                    {
                      type = "workspaces";
                      sort = "index";
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
                      sort = "index";
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
          style = ''
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

            .item, .clock {
              background: transparent;
              border-radius: 20px;
            }

            .focused {
              background: #99ccff;
            }

            .container {
              background-color: transparent;
            }

          '';
        };
      }
      .${config.theming.theme}
    ];
  };
}

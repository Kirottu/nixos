{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.graphical.niri;
in
{
  config.hm.wayland.windowManager.niri.settings = lib.mkIf cfg.enable (
    lib.mkMerge [
      config.graphical.niri.extraOptions
      {
        spawn-at-startup = [
          [ "nextcloud" ]
        ];

        environment = {
          DISPLAY = ":0";
          NIXOS_OZONE_WL = "1";
        };

        gestures.hot-corners.off = [ ];

        # Input config
        input = {
          keyboard = {
            xkb = {
              layout = "fi";
            };
            repeat-delay = 300;
            repeat-rate = 40;
          };
          mouse = {
            accel-profile = "flat";
            accel-speed = -0.2;
          };
          touchpad = {
            tap = [ ];
            dwt = [ ];
            scroll-factor = 0.8;
            # natural-scroll = false;
          };
          focus-follows-mouse._props = {
            max-scroll-amount = "0%";
          };
        };

        # Layout
        layout = {
          gaps = 10;
          focus-ring.off = [ ];
        };

        # Ask clients to omit client side decorations
        prefer-no-csd = true;

        cursor = {
          hide-when-typing = [ ];
        };

      }
      {
        diagonals = lib.mkMerge [
          {
            layout = {
              border = {
                on = [ ];
                width = 4;
                active-color = config.theming.themeAttrs.l1;
                inactive-color = "#000000";
              };
            };
            animations = {
              window-open = {
                curve = "linear";
                duration-ms = 250;
                custom-shader = ''
                  bool is_in_diamond(float p, float x, float y, float cx, float cy) {
                      return (abs(x - cx) + abs(y - cy) < p);
                  }

                  vec4 open_color(vec3 coords_geo, vec3 size_geo) {
                      vec3 coords_tex = niri_geo_to_tex * coords_geo;
                      vec4 color = texture2D(niri_tex, coords_tex.st);
                      vec2 coords = coords_geo.xy * size_geo.xy; // Coordinates in pixel space

                      float border = 4.0;
                      
                      // Center of the window
                      vec2 c = size_geo.xy / 2.0;
                      
                      float p = niri_clamped_progress * max(size_geo.x, size_geo.y);
                      float x = coords.x;
                      float y = coords.y;

                      if (!is_in_diamond(p, x, y, c.x, c.y)) {
                          color = vec4(0.0);
                      }
                      // The border region
                      else if ((!is_in_diamond(p, x - border, y - border, c.x, c.y) ||
                               !is_in_diamond(p, x + border, y - border, c.x, c.y) ||
                               !is_in_diamond(p, x - border, y + border, c.x, c.y) ||
                               !is_in_diamond(p, x + border, y + border, c.x, c.y)) &&
                               x >= 0.0 && y >= 0.0 && x <= size_geo.x && y <= size_geo.y)
                      {
                          color = vec4(0.4, 0.0, 0.2, 1.0);
                      }

                      return color;
                  }
                '';
              };
              window-close = {
                curve = "linear";
                duration-ms = 250;
                custom-shader = ''
                  bool is_in_diamond(float p, float x, float y, float cx, float cy) {
                      return (abs(x - cx) + abs(y - cy) < p);
                  }

                  vec4 close_color(vec3 coords_geo, vec3 size_geo) {
                      vec3 coords_tex = niri_geo_to_tex * coords_geo;
                      vec4 color = texture2D(niri_tex, coords_tex.st);
                      vec2 coords = coords_geo.xy * size_geo.xy; // Coordinates in pixel space

                      float border = 4.0;
                      
                      // Center of the window
                      vec2 c = size_geo.xy / 2.0;
                      
                      float p = (1.0 - niri_clamped_progress) * max(size_geo.x, size_geo.y);
                      float x = coords.x;
                      float y = coords.y;

                      if (!is_in_diamond(p, x, y, c.x, c.y)) {
                          color = vec4(0.0);
                      }
                      // The border region
                      else if ((!is_in_diamond(p, x - border, y - border, c.x, c.y) ||
                               !is_in_diamond(p, x + border, y - border, c.x, c.y) ||
                               !is_in_diamond(p, x - border, y + border, c.x, c.y) ||
                               !is_in_diamond(p, x + border, y + border, c.x, c.y)) &&
                               x >= 0.0 && y >= 0.0 && x <= size_geo.x && y <= size_geo.y)
                      {
                          color = vec4(0.4, 0.0, 0.2, 1.0);
                      }

                      return color;
                  }
                '';
              };
            };
          }
          {
            vertical = {
              overview = {
                zoom = 0.25;
                backdrop-color = "#090909";
              };
              layout.struts.right = 45;

              binds = {
                "Mod+R" = {
                  _props = {
                    repeat = false;
                  };
                  toggle-overview = [ ];
                };
                "Mod+D" = {
                  spawn = "anyrun";
                };
              };
            };
            overview =
              let
                lockfile = "/tmp/niri-overview";
              in
              {
                spawn-sh-at-startup = [
                  [
                    "niri msg -j event-stream | ${pkgs.writeShellScript "niri-overview-monitor" ''
                      while read line; do
                        overview=$(echo $line | ${lib.getExe pkgs.jq} '.OverviewOpenedOrClosed.is_open')

                        if [ $overview = "false" ] && [ -f ${lockfile} ]; then
                          rm ${lockfile}
                          anyrun close
                        fi
                      done                                            
                    ''}"
                  ]
                ];
                overview = {
                  backdrop-color = "#040404";
                  zoom = 0.75;
                };
                binds = {
                  "Mod+D" = {
                    _props = {
                      repeat = false;
                    };
                    spawn = "${pkgs.writeShellScript "niri-overview" ''
                      if [ ! -f ${lockfile} ]; then
                        touch ${lockfile}
                        niri msg action open-overview
                        killall -SIGUSR1 .waybar-wrapped
                        anyrun
                        killall -SIGUSR1 .waybar-wrapped
                        rm ${lockfile}
                        niri msg action close-overview
                      else
                        anyrun close
                      fi
                    ''}";
                  };
                };
              };
          }
          .${config.theming.themeAttrs.subtheme}
        ];
      }
      .${config.theming.theme}
    ]
  );

}

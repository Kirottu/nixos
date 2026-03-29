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
    let
      lockfile = "/tmp/niri-overview";
      overview-script =
        barShow: barHide:
        "${pkgs.writeShellScript "niri-overview" ''
          if [ ! -f ${lockfile} ]; then
            touch ${lockfile}
            niri msg action open-overview
            ${barShow}
            anyrun
            ${barHide}
            rm ${lockfile}
            niri msg action close-overview
          else
            anyrun close
          fi
        ''}";
      overview-monitor = "niri msg -j event-stream | ${pkgs.writeShellScript "niri-overview-monitor" ''
        while read line; do
          overview=$(echo $line | ${lib.getExe pkgs.jq} '.OverviewOpenedOrClosed.is_open')

          if [ $overview = "false" ] && [ -f ${lockfile} ]; then
            rm ${lockfile}
            anyrun close
          fi
        done                                            
      ''}";

    in
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
              in
              {
                spawn-sh-at-startup = [
                  [
                    overview-monitor
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
                    spawn = overview-script "killall -SIGUSR1 .waybar-wrapped" "killall -SIGUSR1 .waybar-wrapped";
                  };
                };
              };
          }
          .${config.theming.themeAttrs.subtheme}
        ];
        bliss = {
          animations = {
            # workspace-switch = {
            #   spring._props = {
            #     damping-ratio = 0.80;
            #     stiffness = 523;
            #     epsilon = 0.0001;
            #   };
            # };
            window-open = {
              duration-ms = 1400;
              curve = "ease-out-expo";
              custom-shader = ''
                float ease_curve(float x) {
                    return x < 0.5 ? 4.0*x*x*x : 1.0 - pow(-2.0*x + 2.0, 3.0)/2.0;
                }

                vec4 open_color(vec3 coords_geo, vec3 size_geo) {
                    float t = niri_clamped_progress;
                    float prog = ease_curve(t);

                    // bottom-right corner
                    vec2 start = vec2(1.0, 1.0);

                    // compute distance along diagonal from corner
                    vec2 p = coords_geo.xy;
                    vec2 dir = vec2(-1.0, -1.0); // vector toward top-left
                    float dist = dot(p - start, dir);

                    // normalize distance to max diagonal (from corner to opposite)
                    float max_diag = 2.0;
                    float norm_dist = dist / max_diag;

                    // pixels not yet reached by sweep are invisible
                    if (norm_dist > prog) {
                        return vec4(0.0);
                    }

                    // sample normally
                    vec3 coords_tex = niri_geo_to_tex * coords_geo;
                    vec4 col = texture2D(niri_tex, coords_tex.xy);

                    return col;
                }'';
            };

            window-close = {
              duration-ms = 1400;
              curve = "ease-out-expo";
              custom-shader = ''
                // ease-in-out cubic curve helper
                float ease_curve(float x) {
                    return x < 0.5 ? 4.0*x*x*x : 1.0 - pow(-2.0*x + 2.0, 3.0)/2.0;
                }

                vec4 close_color(vec3 coords_geo, vec3 size_geo) {
                    float t = niri_clamped_progress;


                    float prog = ease_curve(t);

                    // choose corner: 0=top-left,1=top-right,2=bottom-left,3=bottom-right

                    int corner = 0; 
                    vec2 start;
                    if (corner == 0) start = vec2(0.0,0.0);
                    else if (corner == 1) start = vec2(1.0,0.0);
                    else if (corner == 2) start = vec2(0.0,1.0);
                    else start = vec2(1.0,1.0);


                    // compute distance along diagonal from corner

                    vec2 p = coords_geo.xy;
                    float dist = dot(p - start, vec2(1.0,1.0));

                    // normalize distance to max diagonal
                    float max_diag = 2.0; // max of vec2(1,1)
                    float norm_dist = dist / max_diag;


                    // If pixel is behind the sweeping line, make it invisible

                    if (norm_dist <= prog) {
                        return vec4(0.0);
                    }

                    // sample normally
                    vec3 coords_tex = niri_geo_to_tex * coords_geo;
                    vec4 col = texture2D(niri_tex, coords_tex.xy);

                    return col;
                }'';
            };

            # horizontal-view-movement = {
            #   spring._props = {
            #     damping-ratio = 0.85;
            #     stiffness = 423;
            #     epsilon = 0.0001;
            #   };
            # };
            # window-movement = {
            #   spring._props = {
            #     damping-ratio = 0.75;
            #     stiffness = 323;
            #     epsilon = 0.0001;
            #   };
            # };
            window-resize = {
              custom-shader = ''
                vec4 resize_color(vec3 coords_curr_geo, vec3 size_curr_geo) {
                    vec3 coords_tex_next = niri_geo_to_tex_next * coords_curr_geo;
                    vec4 color = texture2D(niri_tex_next, coords_tex_next.st);
                    return color;
                }
              '';
            };
            # config-notification-open-close = {
            #   spring._props = {
            #     damping-ratio = 0.65;
            #     stiffness = 923;
            #     epsilon = 0.001;
            #   };
            # };
            # screenshot-ui-open = {
            #   duration-ms = 200;
            #   curve = "ease-out-quad";
            # };
            # overview-open-close = {
            #   spring._props = {
            #     damping-ratio = 0.85;
            #     stiffness = 800;
            #     epsilon = 0.0001;
            #   };
            # };
          };

          layout.background-color = "transparent";
          spawn-sh-at-startup = [
            [
              overview-monitor
            ]
          ];
          overview = {
            workspace-shadow = {
              off = [ ];
            };
            zoom = 0.75;
          };
          binds = {
            "Mod+D" = {
              _props = {
                repeat = false;
              };
              spawn =
                let
                  bar = config.hm.programs.ironbar.config.name;
                in
                overview-script
                  ''
                    ironbar bar ${bar} show
                    yand set-offset 60
                  ''
                  ''
                    ironbar bar ${bar} hide
                    yand set-offset 0
                  '';
            };
          };

        };
      }
      .${config.theming.theme}
    ]
  );

}

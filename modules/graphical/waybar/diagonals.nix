{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  settings =
    let
      icon-font = "Symbols Nerd Font Mono 14";
      workspace-icons =
        {
          desktop = {
            "chat" = "󰭹";
            "web-dp1" = "󰖟";
            "web-dp2" = "󰖟";
            "web-dp3" = "󰖟";
            "games" = "󰸻";
            "vr" = "󰢔";
          };
          laptop = {
            "chat" = "󰭹";
            "games" = "󰸻";
            "web" = "󰖟";
          };
        }
        .${config.devices.class};
      icon = glyph: "<span font=\"${icon-font}\">${glyph}</span>";
      ppd = {
        format = icon "{icon}";
        tooltip-format = "Power profile: {profile}\nDriver: {driver}";
        tooltip = true;
        format-icons = {
          default = "";
          performance = "";
          balanced = "";
          power-saver = "";
        };
      };
    in
    {
      vertical = {
        mainBar = lib.mkMerge [
          {
            layer = "top";
            position = "left";
            reload_style_on_change = true;
            width = 45;
            "niri/workspaces" = {
              format = "<span font=\"${icon-font}\">{icon}</span>";
              format-icons = workspace-icons;
            };
            "tray" = {
              icon-size = 22;
              spacing = 5;
            };
            memory = {
              format = "<span font=\"12\">{percentage}%</span>\n${icon ""}";
              justify = "center";
            };
            cpu = {
              format = "<span font=\"12\">{usage}%</span>\n${icon ""}";
              justify = "center";
            };
            pulseaudio = {
              format = "<span font=\"12\">{volume}%</span>\n${icon "{icon}"}";
              format-icons = {
                default = [
                  "󰕿"
                  "󰖀"
                  "󰕾"
                ];
                default-muted = "󰝟";
              };
              justify = "center";
            };
            backlight = {
              format = "<span font=\"12\">{percent}%</span>\n${icon "{icon}"}";
              format-icons = [
                "󰃞"
                "󰃟"
                "󰃠"
              ];
              justify = "center";
            };
            battery = {
              format = "<span font=\"12\">{capacity}%</span>\n${icon "{icon}"}";
              format-icons = [
                ""
                ""
                ""
                ""
                ""
              ];
              justify = "center";
              format-charging = "<span font=\"12\">{capacity}%</span>\n${icon ""}";
            };
            clock = {
              format = "<span font=\"14\">{:%d\n%m\n~\n%H\n%M}</span>";
              justify = "center";
              interval = 1;
            };
            power-profiles-daemon = ppd;

          }
          {
            desktop = {
              modules-left = [
                "niri/workspaces"
                "tray"
              ];
              modules-center = [
              ];
              modules-right = [
                "cpu"
                "memory"
                "clock"
              ];
            };
            laptop = {
              modules-left = [
                "niri/workspaces"
                "tray"
              ];
              modules-center = [ ];
              modules-right = [
                "pulseaudio"
                "backlight"
                "battery"
                "power-profiles-daemon"
                "clock"
              ];
            };
          }
          .${config.devices.class}
        ];
      };
      overview = lib.mkMerge [
        {
          bottom = {
            start_hidden = true;
            exclusive = false;
            margin-bottom = 80;
            margin-right = 100;
            margin-left = 100;
            height = 30;
            layer = "top";
            position = "bottom";
            memory = {
              format = "${icon ""} <span font=\"12\">{percentage}%</span>";
            };
            cpu = {
              format = "${icon ""} <span font=\"12\">{usage}%</span>";
            };
            "niri/workspaces" = {
              format = icon "{icon}";
              format-icons = workspace-icons;
            };
            network = {
              format = "${icon ""} {ifname} ${icon ""} {bandwidthUpBits} ${icon ""} {bandwidthDownBits}";
              interval = 1;
            };
            battery = {
              format = "${icon "{icon}"} <span font=\"12\">{capacity}%</span>";
              format-icons = [
                ""
                ""
                ""
                ""
                ""
              ];
              format-charging = "${icon ""} <span font=\"12\">{capacity}%</span>";
            };
            power-profiles-daemon = ppd;
          };
          top = {
            start_hidden = true;
            exclusive = false;
            margin-top = 80;
            margin-right = 100;
            margin-left = 100;
            height = 30;
            layer = "top";
            position = "top";
            clock = {
              format = "{:%a, %b %d. %H:%M:%OS}";
              interval = 1;
            };
            tray = {
              icon-size = 22;
              spacing = 5;
            };
            pulseaudio = {
              format = "${icon "{icon}"} <span font=\"12\">{volume}%</span>";
              format-icons = {
                default = [
                  "󰕿"
                  "󰖀"
                  "󰕾"
                ];
                default-muted = "󰝟";
              };
              justify = "center";
            };
            backlight = {
              format = "${icon "{icon}"} <span font=\"12\">{percent}%</span>";
              format-icons = [
                "󰃞"
                "󰃟"
                "󰃠"
              ];
              justify = "center";
            };
          };
          # left = {
          #   start_hidden = true;
          #   exclusive = false;
          #   layer = "top";
          #   position = "left";
          #   modules-center = [ "cffi/niri-overflow" ];
          #   "cffi/niri-overflow" = {
          #     module_path = "${
          #       inputs.waybar-niri-overflow.packages.${pkgs.system}.default
          #     }/lib/libwaybar_niri_overflow.so";
          #     format = "${icon "<span rise=\"-1.5pt\">{n}</span>\n"}";
          #     class = "niri-overflow-left";
          #     align = "center";
          #     justify = "center";
          #     hide_when_zero = false;
          #     direction = "left";
          #   };
          # };
          # right = {
          #   start_hidden = true;
          #   exclusive = false;
          #   layer = "top";
          #   position = "right";
          #   modules-center = [ "cffi/niri-overflow" ];
          #   "cffi/niri-overflow" = {
          #     module_path = "${
          #       inputs.waybar-niri-overflow.packages.${pkgs.system}.default
          #     }/lib/libwaybar_niri_overflow.so";
          #     format = "${icon "<span rise=\"-1.5pt\">{n}</span>\n"}";
          #     class = "niri-overflow-right";
          #     align = "center";
          #     hide_when_zero = false;
          #     justify = "center";
          #     direction = "right";
          #   };
          # };
        }
        {
          desktop = {
            top = {
              modules-left = [
                "clock"
              ];
              modules-right = [
                "tray"
              ];
            };
            bottom = {
              modules-left = [
                "cpu"
                "memory"
              ];
              modules-center = [
                "niri/workspaces"
              ];
              modules-right = [
                "network"
              ];
            };
          };
          laptop = {
            top = {
              modules-left = [
                "clock"
                "backlight"
              ];
              modules-right = [
                "pulseaudio"
                "tray"
              ];
            };
            bottom = {
              modules-left = [
                "cpu"
                "memory"
                "power-profiles-daemon"
                "battery"
              ];
              modules-center = [
                "niri/workspaces"
              ];
              modules-right = [
                "network"
              ];
            };
          };
        }
        .${config.devices.class}
      ];
    }
    .${config.theming.themeAttrs.subtheme};
  style =
    with config.theming.themeAttrs;
    {
      vertical = ''
        #workspaces {
          background:
            linear-gradient(-30deg, ${l2} 25px, ${l1} 25px);
          padding-top: 5px;
          padding-bottom: 30px;
        }

        #workspaces button {
          border-radius: 0px;
        }

        #workspaces button.active {
          background: linear-gradient(90deg, @view_fg_color 6px, transparent 6px);
        }

        #tray {
          background: linear-gradient(-30deg, transparent 25px, ${l2} 25px);
          padding-bottom: 30px;
        }

        #pulseaudio {
          background: linear-gradient(-150deg, transparent 25px, ${l4} 25px);
          padding-top: 30px;
        }

        #cpu {
          background: linear-gradient(-150deg, transparent 25px, ${l3} 25px);
          padding-top: 30px;
        }

        #backlight {
          background: linear-gradient(-150deg, ${l4} 25px, ${l3} 25px);
          padding-top: 30px;
        }

        #battery,
        #memory {
          background: linear-gradient(-150deg, ${l3} 25px, ${l2} 25px);
          padding-top: 30px;
        }

        #power-profiles-daemon {
          background: ${l2}
        }

        #clock {
          background:
            linear-gradient(-150deg, ${l2} 25px, ${l1} 25px);
          font-family: "Hack Nerd Font";

          padding-top: 30px;
          padding-bottom: 7px;
        }

        window#waybar {
          background: transparent;
        }
      '';
      overview =
        let
          transition-l2 =
            {
              desktop = "transparent";
              laptop = l2;
            }
            .${config.devices.class};
          transition-l3 =
            {
              desktop = "transparent";
              laptop = l3;
            }
            .${config.devices.class};
        in
        ''
          #workspaces,
          #clock,
          #tray,
          #cpu {
            padding-right: 40px;
            padding-left: 40px;
          }

          #tray {
            background:
              linear-gradient(135deg, ${transition-l2} 25px, ${l1} 25px, ${l1} 50%, transparent 50%),
              linear-gradient(-45deg, transparent 25px, ${l1} 25px, ${l1} 50%, transparent 50%);
          }
          #clock {
            background:
              linear-gradient(135deg, transparent 25px, ${l1} 25px, ${l1} 60%, transparent 60%),
              linear-gradient(-45deg, ${transition-l2} 25px, ${l1} 25px, ${l1} 50%, transparent 50%);
          }
          #workspaces {
            background:
              linear-gradient(135deg, transparent 25px, ${l1} 25px, ${l1} 50%, transparent 50%),
              linear-gradient(-45deg, transparent 25px, ${l1} 25px, ${l1} 50%, transparent 50%);
          }

          #cpu {
            background:
              linear-gradient(135deg, transparent 25px, ${l1} 25px, ${l1} 50%, transparent 50%),
              linear-gradient(-45deg, ${l2} 25px, ${l1} 25px, ${l1} 50%, transparent 50%);
          }

          #memory {
            background:
              linear-gradient(-45deg, ${transition-l3} 25px, ${l2} 25px);
            padding-right: 40px;
          }

          #battery {
            background:
              linear-gradient(-45deg, transparent 25px, ${l3} 25px);
            padding-right: 40px;
          }

          #power-profiles-daemon {
            background: ${l3};
            padding-right: 10px;
          }

          #backlight {
            background:
              linear-gradient(-45deg, transparent 25px, ${l2} 25px);
            padding-right: 40px;
          }

          #pulseaudio {
            background:
              linear-gradient(135deg, transparent 25px, ${l2} 25px);
            padding-left: 40px;
          }

          #network {
            background:
              linear-gradient(135deg, transparent 25px, ${l1} 25px, ${l1} 50%, transparent 50%),
              linear-gradient(-45deg, transparent 25px, ${l1} 25px, ${l1} 50%, transparent 50%);
            padding-left: 40px;
            padding-right: 40px;
          }

          #workspaces button {
            border-radius: 0px;
            min-width: 20px;
          }

          #workspaces button.active {
            background: linear-gradient(0deg, @view_fg_color 4px, transparent 4px);
          }

          #niri-overflow-left {
          	padding-top: 30px;
          	padding-bottom: 30px;
          	padding-left: 5px;
          	min-width: 20px;
          	background:
          	  linear-gradient(-157.5deg, transparent 25px, ${l1} 25px, ${l1} 51%, transparent 51%),
              linear-gradient(-22.5deg, transparent 25px, ${l1} 25px, ${l1} 51%, transparent 51%),
              linear-gradient(0deg, transparent 30px, ${l1} 30px, ${l1} 50%, transparent 50%),
              linear-gradient(180deg, transparent 30px, ${l1} 30px, ${l1} 50%, transparent 50%);
          }
          #niri-overflow-right {
          	padding-top: 30px;
          	padding-bottom: 30px;
          	padding-right: 5px;
          	min-width: 20px;
          	background:
          	  linear-gradient(157.5deg, transparent 25px, ${l1} 25px, ${l1} 51%, transparent 51%),
              linear-gradient(22.5deg, transparent 25px, ${l1} 25px, ${l1} 51%, transparent 51%),
              linear-gradient(0deg, transparent 30px, ${l1} 30px, ${l1} 50%, transparent 50%),
              linear-gradient(180deg, transparent 30px, ${l1} 30px, ${l1} 50%, transparent 50%);
          }

          window#waybar.top,
          window#waybar.bottom {
            background: linear-gradient(90deg, transparent 5%, ${l4} 5%, ${l4} 95%, transparent 95%);
          }

          @keyframes fade {
            0% {
              opacity: 0;
            }
            100% {
              opacity: 1;
            }
          }

          window#waybar.left,
          window#waybar.right {
            background: transparent;
          }
        '';
    }
    .${subtheme};

}

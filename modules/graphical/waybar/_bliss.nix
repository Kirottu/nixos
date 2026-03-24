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
    lib.mkMerge [
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
  style = with config.theming.themeAttrs; ''

  '';
}

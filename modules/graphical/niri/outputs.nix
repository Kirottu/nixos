{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.graphical.niri.enable {
    # Display configurations vary wildly, so just using device
    # class would not really work
    hm.programs.niri.settings =
      {
        church-of-harold = {
          workspaces."chat" = {
            # FIXME: Figure out how to build `tv` automatically with this configuration
            open-on-output = "DP-3";
          };
          workspaces."games" = {
            open-on-output = "DP-2";
          };
          workspaces."vr" = {
            open-on-output = "DP-1";
          };
          workspaces."web-dp1" = {
            open-on-output = "DP-1";
          };
          workspaces."web-dp2" = {
            open-on-output = "DP-2";
          };
          workspaces."web-dp3" = {
            open-on-output = "DP-3";
          };

          outputs."DP-1" = {
            mode = {
              width = 1920;
              height = 1080;
              refresh = 74.986000;
            };
          };
          outputs."DP-2" = {
            mode = {
              width = 1920;
              height = 1080;
              refresh = 99.930000;
            };
          };
          outputs."DP-3" = {
            mode = {
              width = 1280;
              height = 1024;
              refresh = 75.025002;
            };
          };
          outputs."HDMI-A-1" = {
            mode = {
              width = 3840;
              height = 2160;
              refresh = 60.0;
            };
            scale = 2.0;
            enable = false;
          };
        };
        missionary-of-harold = {
          outputs."eDP-1".scale = 1.0;
        };
      }
      .${config.networking.hostName};
  };
}

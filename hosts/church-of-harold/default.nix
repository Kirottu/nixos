{ pkgs, config, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules
  ];
  config = {
    devices.class = "desktop";

    networking = {
      hostName = "church-of-harold";
    };
    gaming = {
      vr.enable = true;
      dolphin-emu.enable = true;
      heroic.enable = true;
      prismlauncher.enable = true;
      umu-run.enable = true;
      steam.enable = true;
      r2modman.enable = true;
    };
    # graphical.eww.enable = true;
    graphical = {
      yand.output = "DP-3";
      tv = {
        enable = true;
        desktopOutputs = [
          "DP-1"
          "DP-2"
          "DP-3"
        ];
        tvOutput = "HDMI-A-1";
        tvSink = "alsa_output.pci-0000_08_00.1.hdmi-stereo";
        tvRegex = "Navi.*\\[alsa\\]";
        tvProfile = 1;
        desktopSink = "alsa_output.pci-0000_0a_00.4.analog-stereo";
      };
      niri.extraOptions = {
        workspaces."chat" = {
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
    };
    services = {
      udev = {
        # Workaround for premature wakeups
        extraRules = ''
          ACTION=="add" SUBSYSTEM=="pci" ATTR{vendor}=="0x1022" ATTR{device}=="0x1483" ATTR{power/wakeup}="disabled"
        '';
        packages = with pkgs; [ android-udev-rules ];
      };
      lact.enable = true;
      btrfs.autoScrub.enable = true;
    };
    impermanence = {
      directories = [ "/etc/lact" ];
      userDirectories = [ ".config/lact" ];
    };

    hardware.amdgpu.overdrive.enable = true;

    programs.droidcam.enable = true;

    # Workaround for cursor corruption after suspend
    hm.programs.niri.settings.debug.disable-cursor-plane = [ ];

    hm.programs.git.signing.key = "B0640016A4BADA0FFBDBD1A57A14996A0D0109CC";

    wiibt.enable = true;

    system.stateVersion = "24.11"; # Did you read the comment?
    hm.home.stateVersion = "24.11";
  };
}

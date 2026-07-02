{
  pkgs,
  inputs,
  lib,
  config,
  myPkgs,
  ...
}:
let
  desktopSink = "alsa_output.pci-0000_0a_00.4.analog-stereo";
in
{
  imports = [
    ./hardware-configuration.nix
  ];
  config = {
    devices.class = "desktop";

    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # openrazer.enable = true;
    networking = {
      hostName = "church-of-harold";
      extraHosts = ''
        0.0.0.0 paradise-s1.battleye.com
        0.0.0.0 test-s1.battleye.com
        0.0.0.0 paradiseenhanced-s1.battleye.com
      '';
    };
    gaming = {
      vr = {
        enable = true;
        defaultSink = desktopSink;
        defaultSource = "alsa_input.pci-0000_0a_00.4.analog-stereo";
      };
      dolphin-emu.enable = true;
      heroic.enable = true;
      prismlauncher.enable = true;
      umu-run.enable = true;
      steam.enable = true;
      r2modman.enable = true;
      fake-frames.enable = true;
    };
    # graphical.eww.enable = true;
    graphical = {
      yand.output = "DP-3";
      # browsers.librewolf.enable = true;
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
        inherit desktopSink;
      };
      instant-replay = {
        enable = true;
        display = "DP-2";
        audioSources = [
          "default_output"
          "easyeffects_source"
        ];
      };
      niri.extraOptions = {
        workspace = [
          {
            _args = [ "chat" ];
            open-on-output = "DP-3";
          }
          {
            _args = [ "games" ];
            open-on-output = "DP-2";
          }
          {
            _args = [ "web-dp1" ];
            open-on-output = "DP-1";
          }
          {
            _args = [ "web-dp2" ];
            open-on-output = "DP-2";
          }
          {
            _args = [ "web-dp3" ];
            open-on-output = "DP-3";
          }
        ];

        output = [
          {
            _args = [ "DP-1" ];
            mode = "1920x1080@74.986000";
            position._props = {
              x = 0;
              y = 330;
            };
          }
          {
            _args = [ "DP-2" ];
            mode = "2560x1440@144.000";
            variable-refresh-rate = [ ];
            position._props = {
              x = 1920;
              y = 0;
            };
          }
          {
            _args = [ "DP-3" ];
            # mode = "1280x1024@75.025002";
            mode = "1920x1080@60.000";
            position._props = {
              x = 4480;
              y = 230;
            };
          }
          {
            _args = [ "HDMI-A-1" ];
            mode = "3840x2160@60.0";
            scale = 2.0;
            off = [ ];
            position._props = {
              x = 5760;
              y = 0;
            };
          }
        ];
        binds."Mod+Shift+M" = {
          _props.allow-when-locked = true;
          spawn = "${
            let
              lockfile = "/tmp/monitors-off";
            in
            pkgs.writeShellScript "toggle-monitors" ''
              if [ -f ${lockfile} ]; then
                niri msg action power-on-monitors
                rm ${lockfile}
              else
                niri msg action power-off-monitors
                touch ${lockfile}
              fi
            ''
          }";

        };
      };

    };

    sops.secrets."clanker/env" = {
      sopsFile = ../../secrets/church-of-harold.yaml;
      owner = "hermes";
      group = "hermes";
    };

    daemons = {
      llm = {
        enable = true;
        clankerSecrets = config.sops.secrets."clanker/env".path;
      };
    };

    systemd.coredump.settings.Coredump = {
      ProcessSizeMax = "512M";
      ExternalSizeMax = "512M";
    };

    services = {
      printing = {
        enable = true;
        drivers = [ pkgs.hplip ];
      };
      udev = {
        # Workaround for premature wakeups
        extraRules = ''
          ACTION=="add" SUBSYSTEM=="pci" ATTR{vendor}=="0x1022" ATTR{device}=="0x1483" ATTR{power/wakeup}="disabled"
        '';
      };
      ratbagd.enable = true;
      lact.enable = true;
      btrfs.autoScrub.enable = true;
      zerotierone.enable = true;
      pid-fan-controller = {
        package = pkgs.pid-fan-controller.overrideAttrs {
          src = pkgs.fetchFromGitHub {
            owner = "zimward";
            repo = "pid-fan-controller";
            rev = "debug";
            hash = "sha256-ZGyHr+LyrDJnszRCaC57WMHcucIwCWdeJYlS968fJOA=";
          };
        };
        enable = true;
        settings = {
          heat_srcs = [
            {
              name = "cpu";
              wildcard_path = "/sys/devices/pci0000:00/0000:00:18.3/hwmon/hwmon*/temp1_input";
              PID_params = {
                set_point = 60;
                # P = -0.005;
                # I = -0.05;
                # D = -0.01;
                P = -5.0e-3;
                I = -2.0e-3;
                D = -6.0e-3;
              };
            }
            {
              name = "gpu";
              wildcard_path = "/sys/class/drm/card*/device/hwmon/hwmon*/temp1_input";
              PID_params = {
                set_point = 60;
                # P = -0.008;
                # I = -0.05;
                # D = -0.01;
                P = -10.0e-3;
                I = -2.0e-3;
                D = -6.0e-3;
              };
            }
            {
              name = "internal";
              wildcard_path = "/sys/devices/platform/it87.2624/hwmon/hwmon*/temp1_input";
              PID_params = {
                set_point = 40;
                # P = -0.005;
                # I = -0.05;
                # D = -0.01;
                P = -5.0e-3;
                I = -2.0e-3;
                D = -6.0e-3;
              };
            }
          ];
          fans = [
            {
              # GPU
              wildcard_path = "/sys/class/drm/card*/device/hwmon/hwmon*/pwm1";
              min_pwm = 30;
              max_pwm = 180;
              heat_pressure_srcs = [ "gpu" ];
            }
            {
              # CPU fan
              wildcard_path = "/sys/devices/platform/it87.2624/hwmon/hwmon*/pwm1";
              min_pwm = 80;
              max_pwm = 255;
              heat_pressure_srcs = [ "cpu" ];
            }
            {
              # Intake fans
              wildcard_path = "/sys/devices/platform/it87.2624/hwmon/hwmon*/pwm3";
              min_pwm = 100;
              max_pwm = 180;
              heat_pressure_srcs = [
                "internal"
              ];
            }
          ];
        };
      };
    };

    # programs.coolercontrol.enable = true;
    impermanence = {
      directories = [
        "/etc/lact"
        "/var/lib/zerotier-one"
        "/var/lib/waydroid"
        "/etc/waydroid-extra"
        "/etc/ssh"
        "/var/lib/cups"
      ];
      userDirectories = [ ".config/lact" ];
    };

    boot = {
      # kernelPackages = pkgs.linuxPackagesFor pkgs.linux;
      # kernelPackages = pkgs.linuxPackagesFor pkgs.linux_latest;
      extraModulePackages = [
        # (pkgs.callPackage ./amdgpu.nix { kernel = config.boot.kernelPackages.kernel; })
        (config.boot.kernelPackages.it87.overrideAttrs {
          version = "unstable-2026-04-16";
          src = pkgs.fetchFromGitHub {
            owner = "frankcrawford";
            repo = "it87";
            rev = "20f2f2f4c92c14fcdd26f60d050e693ad2c30bf8";
            hash = "sha256-o2riPbm75Bez4/SrGV7hB3mlqdxxrwRPdre+3W5y/I0=";
          };
        })
      ];
      kernelModules = [
        "it87"
      ];
      # extraModulePackages = [
      #   (pkgs.callPackage myPkgs.it87 { kernel = config.boot.kernelPackages.kernel; })
      # ];
      # kernelParams = [
      #   "acpi_enforce_resources=lax"
      # ];
      # extraModprobeConfig = ''
      #   options it87 force_id=0x8622
      # '';
      kernelParams = [
        "mitigations=off"
        # Hardware accelerated scheduling maybe?
        # "amdgpu.mes=1"
        # "drm_sched_policy=2"
        "amdgpu.gpu_recovery=1"
        "amdgpu.lockup_timeout=10000"
        "amdgpu.cwsr_enable=0"
        "amdgpu.mcbp=0"
        "amdgpu.gfxoff=0"
      ];
      # kernel.sysctl = {
      #   "vm.swappiness" = 10;
      # };
    };
    net.tailscale.enable = true;

    hardware.amdgpu.overdrive.enable = true;

    programs.droidcam.enable = true;
    # programs.coolercontrol.enable = true;

    virtualisation.waydroid.enable = true;
    networking.nftables.enable = true;

    # nixpkgs.config.rocmSupport = true;

    # Workaround for cursor corruption after suspend
    # hm.programs.niri.settings.debug.disable-cursor-plane = [ ];

    hm.programs.git.signing.key = "B0640016A4BADA0FFBDBD1A57A14996A0D0109CC";

    wiibt.enable = true;

    environment.systemPackages = [
      (pkgs.zoom-us.override {
        gnomeXdgDesktopPortalSupport = true;
      })
      pkgs.deadlock-mod-manager
    ];

    # This machine should always be behind a router with a competent firewall, this is fine
    services.openssh = {
      enable = true;
      ports = [ 22 ];
      settings = {
        AllowUsers = [ config.mainUser.userName ];
        PasswordAuthentication = true;
        PermitRootLogin = "no";
      };
    };

    fonts.packages = [ pkgs.corefonts ];

    theming.theme = lib.mkForce "bliss";
    zramSwap.enable = lib.mkForce false;

    # perf.swapspace.enable = true;

    system.stateVersion = "24.11"; # Did you read the comment?
    hm.home.stateVersion = "24.11";
  };
}

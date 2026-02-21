{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules
  ];

  config = {
    devices.class = "laptop";

    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    networking = {
      hostName = "missionary-of-harold";
      # networkmanager.wifi.powersave = false;
    };

    gaming = {
      heroic.enable = true;
      prismlauncher.enable = true;
      umu-run.enable = true;
      steam.enable = true;
    };

    graphical = {
      yand.output = "eDP-1";
      niri.extraOptions = {
        workspaces."1-chat" = {
          open-on-output = "eDP-1";
          name = "chat";
        };

        workspaces."3-games" = {
          open-on-output = "eDP-1";
          name = "games";
        };

        workspaces."2-web" = {
          open-on-output = "eDP-1";
          name = "web";
        };

        outputs."eDP-1".scale = 1.0;
      };
    };

    services.btrfs.autoScrub.enable = true;

    hm.programs.git.signing.key = "B533007F762CC944EE90C544121FC25B5BCEC10E";

    boot = {
      kernelPackages = pkgs.linuxPackages_latest;
      # extraModulePackages = [ config.boot.kernelPackages.rtl8821ce ];
      # kernelModules = [ "8821ce" ];
      # blacklistedKernelModules = [ "rtw88_8821ce" ];
    };

    system.stateVersion = "24.11"; # Did you read the comment?
    hm.home.stateVersion = "24.11";
  };
}

{
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
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
        workspace = [
          {
            _args = [ "chat" ];
            open-on-output = "eDP-1";
          }
          {
            _args = [ "web" ];
            open-on-output = "eDP-1";
          }
          {
            _args = [ "games" ];
            open-on-output = "eDP-1";
          }
        ];

        output = [
          {
            _args = [ "eDP-1" ];
            scale = 1.0;
          }
        ];
      };
    };
    net.tailscale.enable = true;

    services.btrfs.autoScrub.enable = true;

    hm.programs.git.signing.key = "B533007F762CC944EE90C544121FC25B5BCEC10E";

    boot = {
      kernelPackages = pkgs.linuxPackages_latest;
      # extraModulePackages = [ config.boot.kernelPackages.rtl8821ce ];
      # kernelModules = [ "8821ce" ];
      # blacklistedKernelModules = [ "rtw88_8821ce" ];
    };

    impermanence.userDirectories = [ "Shitposting" ];

    system.stateVersion = "24.11"; # Did you read the comment?
    hm.home.stateVersion = "24.11";
  };
}

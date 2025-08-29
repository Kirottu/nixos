{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf (config.devices.class == "desktop" || config.devices.class == "laptop") {
    graphical = {
      enable = true;
      niri.enable = true;
      waybar.enable = true;
      webapps = {
        enable = true;
        webapps.cinny = {
          title = "Cinny";
          url = "https://app.cinny.in";
          icon = ./cinny.png;
        };
      };
      browsers = {
        zen.enable = true;
        default = "zen-beta.desktop";
      };
    };
    sops.secrets."users/pass-hash" = {
      neededForUsers = true;
      sopsFile = ../../secrets/users.yaml;
    };
    mainUser = {
      userName = "kirottu";
      hashedPasswordFile = config.sops.secrets."users/pass-hash".path;
    };
    cli = {
      starship.enable = true;
      fish.enable = true;
      getty = {
        enable = true;
        dm.enable = true;
      };
    };
    net = {
      # stubby.enable = true;
      ctrld.enable = true;
      networkmanager.enable = true;
    };
    impermanence = {
      enable = true;
      userDirectories = [
        "Projects"
        "Downloads"
        "git"
        ".config/dconf"
        ".local/share/flatpak" # Used for screen share tokens
        ".local/share/keyrings"
        ".local/state"
        ".cache"
        {
          directory = ".pki";
          mode = "0700";
        }
      ];
      userFiles = [
        ".config/gtk-3.0/bookmarks"
      ];
    };
    perf.s76-scheduler.enable = true;
    audio = {
      pipewire.enable = true;
      easyeffects.enable = true;
    };
    automounting.enable = true;
    bluetooth.enable = true;
    theming = {
      plymouth.enable = true;
      theme = "diagonals";
      themeAttrs = {
        l4 = "#1a000d";
        l3 = "#33001a";
        l2 = "#4d0026";
        l1 = "#660033";
        subtheme = "overview";
      };
    };
    daemons.kidex.enable = true;

    nixpkgs.config.allowUnfree = true;

    programs.command-not-found.enable = true;

    boot.kernel.sysctl."kernel.sysrq" = 1;
  };
}

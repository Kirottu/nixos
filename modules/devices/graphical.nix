{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.devices.graphical {
    gaming.enable = true;
    graphical = {
      enable = true;
      niri.enable = true;
      webapps = {
        enable = true;
        webapps.cinny = {
          title = "Cinny";
          url = "https://app.cinny.in";
          icon = ./cinny.png;
        };
      };
      browsers = {
        # zen.enable = true;
        # librewolf.enable = true;
        firefox.enable = true;
        default = "firefox.desktop";
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
      # ctrld.enable = true;
      resolved.enable = true;
      networkmanager.enable = true;
    };
    impermanence = {
      userDirectories = [
        "Projects"
        "Downloads"
        "git"
        # ".local/share/flatpak" # Used for screen share tokens
        # ".local/share/keyrings"
        # ".local/share/racket"
        # Got tired of impermanence on these, TODO: vibe check this later
        ".config"
        ".local/share"
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
    # perf.s76-scheduler.enable = true;
    audio = {
      pipewire.enable = true;
      easyeffects.enable = true;
    };
    automounting.enable = true;
    bluetooth.enable = true;
    theming = {
      plymouth.enable = true;
      theme = "bliss";
    };
    virt.distrobox.enable = true;
    daemons = {
      kidex.enable = true;
    };
    devel.llm.enable = true;

    services.mullvad-vpn = {
      enable = true;
      package = pkgs.mullvad-vpn;
    };
    impermanence.directories = [ "/etc/mullvad-vpn" ];

    mainUser.extraGroups = [
      "adbusers"
      "plugdev"
      "video"
      "input"
      "audio"
    ];

    boot = {
      kernel.sysctl."kernel.sysrq" = 1;
      zswap.enable = true;
    };
  };
}

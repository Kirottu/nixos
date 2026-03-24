{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  options.graphical.niri = {
    enable = lib.mkEnableOption "Niri compositor";
    extraOptions = lib.mkOption {
      type = lib.types.attrs;
      default = { };
    };
  };

  imports = [
    inputs.niri-nix.nixosModules.niri-nix
  ];

  config = lib.mkIf config.graphical.niri.enable {
    cli.getty.dm.command = lib.mkIf config.cli.getty.dm.enable "niri-session";

    home-manager.sharedModules = [
      inputs.niri-nix.homeModules.niri-nix
    ];

    hm.imports = [
      inputs.system76-scheduler-niri.homeModules.system76-scheduler-niri
    ];

    nix.settings = {
      substituters = [
        "https://niri-nix.cachix.org"
      ];
      trusted-public-keys = [
        "niri-nix.cachix.org-1:SvFtqpDcf7Sm1SMJdby1/+Y+6f3Yt3/3PMcSTKPJNJ0="
      ];
    };
    nixpkgs.overlays = [ inputs.niri-nix.overlays.niri-nix ];

    graphical = {
      screenLocking = {
        gtklock.enable = true;
        swayidle.enable = true;
      };
      waybar.enable = true;
      yand.enable = true;
      terminals.alacritty.enable = true;
      anyrun.enable = true;
    };
    hm.services.wpaperd.enable = true;

    programs.niri = {
      enable = true;
      package = pkgs.niri-unstable.overrideAttrs (prev: {
        src = pkgs.fetchFromGitHub {
          owner = "niri-wm";
          repo = "niri";
          rev = "wip/branch";
          hash = "sha256-L/Ldq9G41Mj8WjWTuC+rePvWIx1A/tHdFpLbQmtrMSA=";
        };
        version = "blur";
        env = prev.env // {
          NIRI_BUILD_VERSION_STRING = "blur";
        };
      });
    };
    hm.wayland.windowManager.niri = {
      enable = true;
      package = config.programs.niri.package;
    };
    security.soteria.enable = true;
    # nixpkgs.overlays = [ inputs.niri.overlays.niri ];
    # programs.niri.package =
    #   inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable.overrideAttrs
    #     {
    #       src = pkgs.fetchFromGitHub {
    #         owner = "flowerysong";
    #         repo = "niri";
    #         rev = "release-keybinds";
    #         hash = "sha256-R7qJK5io3o+BsVx1cSQSj8asYXg7WvLqNchY7SYnmuo=";
    #       };
    #     };

    xdg.portal = {
      xdgOpenUsePortal = true;
      extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    };

    # hm.systemd.user.services.xwayland-satellite = {
    #   Unit = {
    #     Description = "Xwayland outside your Wayland";
    #     BindsTo = [ "graphical-session.target" ];
    #     PartOf = [ "graphical-session.target" ];
    #     After = [ "graphical-session.target" ];
    #     Requisite = [ "graphical-session.target" ];
    #   };
    #   Service = {
    #     Type = "notify";
    #     NotifyAccess = "all";
    #     ExecStart =
    #       lib.getExe
    #         inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.xwayland-satellite-unstable;
    #     StandardOutput = "journal";
    #     Restart = "on-failure";
    #   };
    #   Install = {
    #     WantedBy = [ "graphical-session.target" ];
    #   };
    # };

    services.system76-scheduler.assignments = {
      desktop-environment = {
        matchers = [ "niri" ];
      };
    };

    hm.services.system76-scheduler-niri.enable = config.perf.s76-scheduler.enable;

    environment.systemPackages = with pkgs; [
      pulseaudio # Used by TV switching script
      libsecret
      wayland-utils
      wl-clipboard
      xwayland-satellite-unstable
    ];
  };
}

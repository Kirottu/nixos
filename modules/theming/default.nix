{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
{
  options.theming = {
    theme = lib.mkOption {
      type = lib.types.enum [
        "diagonals"
      ];
      default = "diagonals";
      description = "What overall theme should be applied";
    };
    themeAttrs = lib.mkOption {
      type = lib.types.attrs;
      default =
        {
          diagonals = {
            l4 = "#1a000d";
            l3 = "#33001a";
            l2 = "#4d0026";
            l1 = "#660033";
            # Subthemes: vertical, overview
            subtheme = "vertical";
          };
        }
        .${config.theming.theme};
      description = "Additional attributes for theme";
    };
    colorScheme = lib.mkOption {
      type = lib.types.path;
      description = "Base16 color scheme to use";
      default = { diagonals = ./color-schemes/adwaita-dark.yaml; }.${config.theming.theme};
    };
    wallpaper = lib.mkOption {
      type = lib.types.path;
      description = "Wallpaper to be used for desktop & lock screen";
      default = { diagonals = ./images/marker-of-harold.png; }.${config.theming.theme};
    };
    plymouth = {
      enable = lib.mkEnableOption "Plymouth";
      logo = lib.mkOption {
        type = lib.types.path;
        description = "Plymouth boot screen logo";
        default = { diagonals = ./images/marker-resized.png; }.${config.theming.theme};
      };
    };
  };

  imports = [
    inputs.stylix.nixosModules.stylix
  ];

  config =
    lib.mkIfElse config.graphical.enable
      (
        let
          icon-theme = "Papirus-Dark";

          qtctConfig = ''
            [Fonts]
            fixed="Hack Nerd Font,11,-1,5,50,0,0,0,0,0,Regular"
            general="Noto Sans,11,-1,5,50,0,0,0,0,0"

            [Appearance]
            style=Breeze
            standard_dialogs=xdgdesktopportal
            icon_theme=${icon-theme}
            custom_palette=true
            color_scheme_path=${pkgs.libsForQt5.qt5ct}/share/qt5ct/colors/darker.conf
          '';
        in
        {
          fonts.packages = with pkgs; [
            noto-fonts-cjk-sans
            # noto-fonts
            nerd-fonts.symbols-only
            nerd-fonts.hack
          ];

          hm.qt = {
            enable = true;
            platformTheme.name = "qtct";
          };

          environment.systemPackages = with pkgs; [
            kdePackages.breeze
          ];

          hm.xdg.configFile = {
            "qt5ct/qt5ct.conf".text = lib.mkForce qtctConfig;
            "qt6ct/qt6ct.conf".text = lib.mkForce qtctConfig;
          };

          # Stylix does not set this automatically, and as of FF 141 this is
          # required for FF to respect the dark theme
          # TODO: Should probably be upstreamed
          hm.dconf.settings = {
            "org/gnome/desktop/interface" = {
              color-scheme = "prefer-dark";
            };
          };
          gtk.iconCache.enable = true;

          hm.stylix = {
            base16Scheme = config.theming.colorScheme;
            polarity = "dark";
            enable = true;
            autoEnable = false;

            image = config.theming.wallpaper;

            cursor = {
              package = pkgs.bibata-cursors;
              name = "Bibata-Original-Classic";
              size = 24;
            };

            targets = {
              wpaperd.enable = true;
              gtk.enable = true;
              helix.enable = true;
              alacritty.enable = true;
            };

            iconTheme = {
              enable = true;
              dark = icon-theme;
              package = pkgs.papirus-icon-theme;
            };
          };
          stylix = {
            enable = true;
            autoEnable = false;
            base16Scheme = config.theming.colorScheme;

            fonts = {
              # serif = {
              #   package = pkgs.noto-fonts;
              #   name = "Noto Serif";
              # };
              # sansSerif = {
              #   package = pkgs.noto-fonts;
              #   name = "Noto Sans";
              # };
              monospace = {
                package = pkgs.nerd-fonts.hack;
                name = "Hack Nerd Font";
              };
              emoji = {
                package = pkgs.noto-fonts-emoji;
                name = "Noto Color Emoji";
              };

              sizes = {
                desktop = 11;
                popups = 11;
                applications = 11;
                terminal = 11;
              };
            };

            targets = {
              plymouth = lib.mkIf config.theming.plymouth.enable {
                enable = true;
                logo = config.theming.plymouth.logo;
                logoAnimated = false;
              };
            };
          };
          boot = lib.mkIf config.theming.plymouth.enable {
            plymouth = {
              enable = true;
            };
            kernelParams = [
              "quiet"
              "boot.shell_on_fail"
              "udev.log_priority=3"
              "rd.systemd.show_status=auto"
            ];
            consoleLogLevel = 3;
            initrd.verbose = false;
            loader.timeout = 0;
          };
        }
      )
      {
        stylix = {
          enable = true;
          base16Scheme = config.theming.colorScheme;
          autoEnable = false;
        };
      };
}

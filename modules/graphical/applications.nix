{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.graphical;
in
{
  options.graphical = {
    browsers = {
      zen.enable = lib.mkEnableOption "Zen Browser";
      librewolf.enable = lib.mkEnableOption "LibreWolf";
      default = lib.mkOption {
        type = lib.types.nonEmptyStr;
        description = "Desktop entry of the default browser";
      };
    };
    terminals = {
      alacritty.enable = lib.mkEnableOption "Alacritty";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        environment.systemPackages = with pkgs; [
          sirikali
          pavucontrol
          kdiskmark
          papers
        ];
        hm.xdg.mimeApps = {
          enable = true;
          defaultApplications = {
            "x-scheme-handler/http" = cfg.browsers.default;
            "x-scheme-handler/https" = cfg.browsers.default;
            "x-scheme-handler/chrome" = cfg.browsers.default;
            "text/html" = cfg.browsers.default;
            "application/x-extension-htm" = cfg.browsers.default;
            "application/x-extension-html" = cfg.browsers.default;
            "application/x-extension-shtml" = cfg.browsers.default;
            "application/xhtml+xml" = cfg.browsers.default;
            "application/x-extension-xhtml" = cfg.browsers.default;
            "application/x-extension-xht" = cfg.browsers.default;
          };

          associations.added = {
            "x-scheme-handler/http" = cfg.browsers.default;
            "x-scheme-handler/https" = cfg.browsers.default;
            "x-scheme-handler/chrome" = cfg.browsers.default;
            "text/html" = cfg.browsers.default;
            "application/x-extension-htm" = cfg.browsers.default;
            "application/x-extension-html" = cfg.browsers.default;
            "application/x-extension-shtml" = cfg.browsers.default;
            "application/xhtml+xml" = cfg.browsers.default;
            "application/x-extension-xhtml" = cfg.browsers.default;
            "application/x-extension-xht" = cfg.browsers.default;
          };
        };
      }
      (lib.mkIf cfg.terminals.alacritty.enable {
        hm.programs.alacritty = {
          enable = true;
          settings = {
            window = {
              decorations = "None";
            };
          };
        };
      })
      (lib.mkIf cfg.browsers.zen.enable {
        hm.imports = [ inputs.zen-browser.homeModules.beta ];
        hm.programs.zen-browser = {
          enable = true;
          policies = {
            DisableAppUpdate = true;
            DisableTelemetry = true;
          };
        };
        impermanence.userDirectories = [ ".zen" ];
      })
      (lib.utils.mkApp {
        package = pkgs.libreoffice-fresh;
        userDirectories = [ ".config/libreoffice" ];
      })
      (lib.utils.mkApp {
        package = pkgs.librewolf;
        userDirectories = [ ".librewolf" ];
      })
      (lib.utils.mkApp {
        package = pkgs.nextcloud-client;
        userDirectories = [
          ".config/Nextcloud"
          ".local/share/Nextcloud"
          "Nextcloud"
        ];
        extraOptions =
          let
            mkLink = name: {
              hm.home.file."${name}".source =
                config.hm.lib.file.mkOutOfStoreSymlink "${config.hm.home.homeDirectory}/Nextcloud/${name}";
            };
          in
          lib.mkMerge [
            (mkLink "Documents")
            (mkLink "Pictures")
            (mkLink "Videos")
          ];
      })
      (lib.utils.mkApp {
        package = pkgs.discord-ptb;
        userDirectories = [ ".config/discordptb" ];
      })
      (lib.utils.mkApp {
        package = pkgs.gimp3-with-plugins;
        userDirectories = [
          ".config/GIMP"
        ];
      })
      (lib.utils.mkApp {
        package = pkgs.inkscape;
        userDirectories = [
          ".config/inkscape"
        ];
      })
      (lib.utils.mkApp {
        package = pkgs.stremio.overrideAttrs (old: {
          postInstall = lib.concatStrings [
            old.postInstall
            ''
              substituteInPlace $out/share/applications/smartcode-stremio.desktop \
                --replace "StartupWMClass=stremio" "StartupWMClass=com.stremio.stremio"
            ''
          ];
        });
        userDirectories = [
          ".config/Smart Code ltd"
          ".local/share/Smart Code ltd"
          ".stremio-server"
        ];
        extraOptions = {
          nixpkgs.config.permittedInsecurePackages = [
            "qtwebengine-5.15.19"
          ];
        };
      })
      {
        hm.programs.obs-studio = {
          enable = true;
        };
        impermanence.userDirectories = [ ".config/obs-studio" ];
      }
    ]
  );
}

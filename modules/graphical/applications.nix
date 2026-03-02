{
  config,
  inputs,
  lib,
  myPkgs,
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
      firefox.enable = lib.mkEnableOption "Firefox";
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

          imagemagick
          tree
          killall
          file
          libnotify
          usbutils
          cloc
          wget
          unzip
          p7zip
          unrar-wrapper
          yt-dlp
          dig
          nettools
          nautilus
          # Video thumbnails
          ffmpeg-headless
          ffmpegthumbnailer

          kdePackages.partitionmanager

          sirikali
          pavucontrol
          kdiskmark
          (pkgs.writeShellApplication {
            name = "xwayland-rootful";
            text = ''
              STATE_FILE="/tmp/xwayland-rootful.state"

              if [ ! -f $STATE_FILE ]; then
                printf "10" > $STATE_FILE
              fi

              # shellcheck disable=SC2155
              export DISPLAY=":$(cat $STATE_FILE)"

              INC=$(($(cat $STATE_FILE) + 1))

              printf "%s" "$INC" > $STATE_FILE

              if [ -f "/tmp/tv.state" ]; then
                GEOMETRY="3840x2160"
              else
                GEOMETRY="2560x1440"
              fi

              ${lib.getExe pkgs.xwayland} -geometry $GEOMETRY -fullscreen -hidpi "$DISPLAY" &
              PID=$!

              sleep 0.1

              ${pkgs.openbox}/bin/openbox &

              sleep 0.1

              WAYLAND_DISPLAY="" "$@"

              kill $PID
            '';
          })
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
      (lib.mkIf cfg.browsers.librewolf.enable (
        lib.utils.mkApp {
          package = pkgs.librewolf;
          userDirectories = [ ".librewolf" ];
        }
      ))
      (lib.mkIf cfg.browsers.firefox.enable (
        lib.utils.mkApp {
          package = pkgs.firefox;
          userDirectories = [ ".mozilla" ];
        }
      ))
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
      # (lib.utils.mkApp {
      #   package = pkgs.discord-ptb;
      #   userDirectories = [ ".config/discordptb" ];
      # })
      # (lib.utils.mkApp {
      #   package = pkgs.vesktop;
      # })
      (lib.utils.mkApp {
        package = pkgs.equibop;
      })
      (lib.utils.mkApp {
        package = pkgs.mumble;
      })
      (lib.utils.mkApp {
        package = pkgs.callPackage myPkgs.sable { };
      })
      (lib.utils.mkApp {
        package = inputs.wrappers.lib.wrapPackage {
          inherit pkgs;
          package = pkgs.element-desktop.override {
            element-web = pkgs.element-web.override {
              conf = {
                features = {
                  feature_video_rooms = true;
                  feature_group_calls = true;
                  feature_element_call_video_rooms = true;
                };
              };
            };
          };
          flags = {
            "--password-store" = "gnome-libsecret";
          };
          flagSeparator = "=";
        };
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
        # package = pkgs.callPackage myPkgs.stremio { };
        package = inputs.nixpkgs-stremio.legacyPackages.${pkgs.stdenv.hostPlatform.system}.stremio;
        # package = pkgs.stremio;
        userDirectories = [
          ".config/Smart Code ltd"
          ".local/share/Smart Code ltd"
          ".local/share/stremio"
          ".stremio-server"
        ];
        extraOptions = {
          nixpkgs.config.permittedInsecurePackages = [
            "qtwebengine-5.15.19"
          ];
        };
      })
      # {
      #   impermanence.userDirectories = [
      #     ".config/Smart Code ltd"
      #     ".local/share/Smart Code ltd"
      #     ".local/share/stremio"
      #     ".stremio-server"
      #   ];
      # }
      (lib.utils.mkApp {
        package = pkgs.freecad;
        userDirectories = [
          ".config/FreeCAD"
          ".local/share/FreeCAD"
        ];
      })
      (lib.utils.mkApp {
        package = pkgs.prusa-slicer;
        userDirectories = [
          ".config/PrusaSlicer"
        ];
      })
      {
        hm.programs.obs-studio = {
          enable = true;
        };
        impermanence.userDirectories = [ ".config/obs-studio" ];
      }
      (lib.utils.mkApp {
        package = pkgs.wireshark;
        userDirectories = [
          ".config/wireshark"
        ];
        extraOptions = {
          programs.wireshark.enable = true;
          mainUser.extraGroups = [ "wireshark" ];
        };
      })
      (lib.utils.mkApp {
        package = pkgs.libqalculate; # TODO: HM module
        userDirectories = [ ".config/qalculate" ];
      })
      (lib.utils.mkApp {
        package = pkgs.wineWow64Packages.waylandFull;
        userDirectories = [ ".wine" ];
      })
    ]
  );
}

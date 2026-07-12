{
  config,
  lib,
  pkgs,
  inputs,
  myUtils,
  ...
}:
let
  cfg = config.gaming;
in
{
  options.gaming = {
    dolphin-emu.enable = lib.mkEnableOption "Dolphin Emulator";
    heroic.enable = lib.mkEnableOption "Heroic games launcher";
    steam.enable = lib.mkEnableOption "Steam";
    umu-run.enable = lib.mkEnableOption "UMU Launcher";
    r2modman.enable = lib.mkEnableOption "r2modman";
    itch.enable = lib.mkEnableOption "itch";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        programs.gamescope = {
          enable = true;
          capSysNice = true;
        };
      }
      (lib.mkIf cfg.umu-run.enable (
        myUtils.mkApp {
          package = pkgs.umu-launcher;
          userDirectories = [
            ".local/share/umu"
          ];
        }
      ))
      (lib.mkIf cfg.heroic.enable (
        (myUtils.mkApp {
          package = pkgs.heroic;
          userDirectories = [ ".config/heroic" ];
        })
      ))
      (lib.mkIf cfg.dolphin-emu.enable (
        lib.mkMerge [
          (myUtils.mkApp {
            package = pkgs.dolphin-emu;
            userDirectories = [
              ".config/dolphin-emu"
              ".local/share/dolphin-emu"
            ];
          })
          {
            services.udev = {
              packages = [
                pkgs.dolphin-emu
                (pkgs.writeTextFile {
                  name = "dolphin-usb-rule";
                  text = ''
                    SUBSYSTEM=="usb", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="0305", TAG+="uaccess"
                  '';
                  destination = "/lib/udev/rules.d/52-dolphin-btusb.rules";
                })
              ];
            };
          }
        ]
      ))
      (lib.mkIf cfg.steam.enable {
        impermanence.userDirectories = [
          ".local/share/Steam"
        ];

        # environment.systemPackages = [
        #   pkgs.steam-run
        # ];

        # nixpkgs.overlays = [ inputs.millenium.overlays.default ];
        #

        programs.steam = {
          package = pkgs.steam.override {
            # extraBwrapArgs = [
            #   "--cap-add"
            #   "CAP_SYS_ADMIN"
            #   "--dev-bind"
            #   "/dev/fuse"
            #   "/dev/fuse"
            # ];
          };
          enable = true;
          extest.enable = true;
          extraCompatPackages = with pkgs; [
            proton-ge-bin
          ];
          extraPackages = with pkgs; [
            libnotify
            python315
          ];
        };
      })
      (lib.mkIf cfg.itch.enable (
        myUtils.mkApp {
          package = pkgs.itch.override {
            steam-run =
              (pkgs.steam.override {
                extraPkgs = p: [
                  p.nss
                  p.libxscrnsaver
                ];
              }).passthru.run;
          };
        }
      ))
      (lib.mkIf cfg.r2modman.enable (
        myUtils.mkApp {
          package = pkgs.r2modman;
          userDirectories = [
            ".config/r2modman"
            ".config/r2modmanPlus-local"
          ];
        }
      ))
    ]
  );
}

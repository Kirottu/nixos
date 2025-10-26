{
  config,
  lib,
  pkgs,
  inputs,
  myPkgs,
  ...
}:
let
  xrizer-multilib =
    let
      pkg = inputs.nixpkgs-xr.packages.${pkgs.system}.xrizer;
    in
    pkgs.symlinkJoin {
      name = "xrizer-multilib";
      paths =
        let
          attrs = {
            postInstall = ''
              mkdir -p $out/lib/xrizer/$platformPath
              mv "$out/lib/libxrizer.so" "$out/lib/xrizer/$platformPath/vrclient.so"
            '';
          };
        in
        [
          (pkg.overrideAttrs attrs)
          ((pkgs.pkgsi686Linux.callPackage pkg.override { }).overrideAttrs attrs)
        ];
    };
  wivrn-config = {
    scale = 0.35;
    bitrate = 90000000;
    encoders = [
      {
        encoder = "vaapi";
        codec = "h265";
        width = 0.5;
        height = 0.25;
        offset_x = 0.0;
        offset_y = 0.0;
        group = 0;
      }
      {
        encoder = "vaapi";
        codec = "h265";
        width = 0.5;
        height = 0.75;
        offset_x = 0.0;
        offset_y = 0.25;
        group = 0;
      }
      {
        encoder = "vaapi";
        codec = "h265";
        width = 0.5;
        height = 1.0;
        offset_x = 0.5;
        offset_y = 0.0;
        group = 0;
      }
    ];
    # openvr-compat-path = "${inputs.nixpkgs-xr.packages.${pkgs.system}.xrizer}/lib/xrizer";
    openvr-compat-path = "${xrizer-multilib}/lib/xrizer";
    tcp-only = false;
  };

  cfg = config.gaming.vr;
in
{
  options.gaming.vr = {
    enable = lib.mkEnableOption "VR";
    defaultSink = lib.mkOption {
      type = lib.types.str;
    };
    defaultSource = lib.mkOption {
      type = lib.types.str;
    };
  };

  config = lib.mkIf config.gaming.vr.enable {

    # Needed for WiVRn
    services.avahi = {
      enable = true;
      publish = {
        enable = true;
        userServices = true;
      };
    };

    environment.systemPackages = [
      pkgs.bs-manager
    ];

    impermanence.userDirectories = [
      ".config/bs-manager"
      ".config/wlxoverlay"
      ".config/wivrn"
      ".config/openxr"
      ".local/share/wayvr-dashboard"
      ".local/share/dev.oo8.wayvr-dashboard"
    ];

    hm.imports = [
      inputs.hm-modules.homeModules.wivrn
      inputs.hm-modules.homeModules.wlx-overlay-s
    ];

    # services.system76-scheduler.assignments.vr = {
    #   nice = -12;
    #   ioClass = "realtime";
    #   ioPrio = 0;
    #   matchers = [
    #     "wivrn-server"
    #     "wlx-overlay-s"
    #   ];
    # };

    # security.wrappers."wivrn-server" = {
    #   setuid = false;
    #   owner = "root";
    #   group = "root";
    #   capabilities = "cap_sys_nice+eip";
    #   source = lib.getExe pkgs.wivrn;
    # };

    # hm.xdg.configFile."openxr/1/active_runtime.x86_64.json".source =
    #   "${pkgs.wivrn}/share/openxr/1/openxr_wivrn.json";
    hm.xdg.configFile."openxr/1/active_runtime.i686.json".source = "${
      pkgs.pkgsi686Linux.callPackage myPkgs.wivrn-server-lib { absolute = true; }
    }/share/openxr/1/openxr_wivrn.json";

    # programs.steam =
    #   let
    #     pkg = p: (p.callPackage myPkgs.wivrn-server-lib { });
    #   in
    #   {
    #     package = pkgs.steam.override {
    #       extraEnv = {
    #         # XR_RUNTIME_JSON = "${pkg pkgs}/share/openxr/1/openxr_wivrn.json";
    #         PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
    #       };
    #       # extraLibraries = p: [
    #       #   (pkg p)
    #       # ];
    #     };
    #   };

    # (pkgs.pkgsi686Linux.callPackage myPkgs.wivrn-server-lib { })

    # hm.programs.wivrn = {
    #   package = pkgs.wivrn;
    #   enable = true;
    #   # autostart = ''
    #   #   #!/bin/sh

    #   #   ${pkgs.pulseaudio}/bin/pactl set-default-sink wivrn.sink

    #   #   # ${lib.getExe pkgs.wlx-overlay-s} --openxr
    #   # '';
    #   autostart = ''
    #     #!/bin/sh
    #   '';
    #   settings = wivrn-config;
    # };

    services.wivrn = {
      package = inputs.nixpkgs-wivrn.legacyPackages.${pkgs.system}.wivrn;
      enable = true;
      config = {
        enable = true;
        json = wivrn-config // {
          application =
            let
              exec = lib.getExe inputs.wivrn-connection-manager.packages.${pkgs.system}.wivrn-connection-manager;
              config = (pkgs.formats.json { }).generate "config.json" {
                on_startup = [
                  {
                    exec = lib.getExe pkgs.wlx-overlay-s;
                    args = [ "--openxr" ];
                  }
                ];
                on_connect = [
                  {
                    exec = "${pkgs.pulseaudio}/bin/pactl";
                    args = [
                      "set-default-sink"
                      "wivrn.sink"
                    ];
                  }
                  {
                    exec = "${pkgs.pulseaudio}/bin/pactl";
                    args = [
                      "set-default-source"
                      "wivrn.source"
                    ];
                  }
                ];
                on_disconnect = [
                  {
                    exec = "${pkgs.pulseaudio}/bin/pactl";
                    args = [
                      "set-default-sink"
                      cfg.defaultSink
                    ];
                  }
                  {
                    exec = "${pkgs.pulseaudio}/bin/pactl";
                    args = [
                      "set-default-source"
                      cfg.defaultSource
                    ];
                  }
                ];
                kill_timeout = 300;
              };
            in
            (pkgs.writeShellApplication {
              name = "wivrn-autostart";
              text = ''
                ${exec} -c ${config}
              '';
            });

        };
      };
      steam.importOXRRuntimes = true;
      highPriority = true;
      autoStart = true;
    };

    hm.programs.wlx-overlay-s = {
      enable = true;
      watch = ./watch.yaml;
      openxrActions = ./openxr_actions.json5;
      dashboard.package = inputs.nixpkgs-xr.packages.${pkgs.system}.wayvr-dashboard;
      settings = {
        notification_topics = {
          DesktopNotification = "Watch";
        };
      };
    };
  };
}

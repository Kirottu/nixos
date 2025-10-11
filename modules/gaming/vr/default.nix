{
  config,
  lib,
  pkgs,
  inputs,
  myPkgs,
  ...
}:
{
  options.gaming.vr.enable = lib.mkEnableOption "VR";

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

    security.wrappers."wivrn-server" = {
      setuid = false;
      owner = "root";
      group = "root";
      capabilities = "cap_sys_nice+eip";
      source = lib.getExe pkgs.wivrn;
    };

    # hm.xdg.configFile."openxr/1/active_runtime.x86_64.json".source =
    #   "${pkgs.wivrn}/share/openxr/1/openxr_wivrn.json";
    hm.xdg.configFile."openxr/1/active_runtime.i686.json".source = "${
      pkgs.pkgsi686Linux.callPackage myPkgs.wivrn-server-lib { absolute = true; }
    }/share/openxr/1/openxr_wivrn.json";

    programs.steam =
      let
        pkg = p: (p.callPackage myPkgs.wivrn-server-lib { });
      in
      {
        package = pkgs.steam.override {
          extraEnv = {
            # XR_RUNTIME_JSON = "${pkg pkgs}/share/openxr/1/openxr_wivrn.json";
            PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES = 1;
          };
          # extraLibraries = p: [
          #   (pkg p)
          # ];
        };
      };

    # (pkgs.pkgsi686Linux.callPackage myPkgs.wivrn-server-lib { })

    hm.programs.wivrn = {
      package = pkgs.wivrn;
      # (pkgs.pkgsCross."gnu32".wivrn.overrideAttrs {
      #   cmakeFlags = [
      #     (lib.cmakeBool "WIVRN_BUILD_SERVER" false)
      #     (lib.cmakeBool "WIVRN_BUILD_SERVER_LIBRARY" true)
      #     (lib.cmakeFeature "WIVRN_OPENXR_MANIFEST_TYPE" "absolute")
      #   ];
      #   preFixup = "";
      #   desktopItems = [ ];
      # })
      enable = true;
      autostart = ''
        #!/bin/sh

        ${pkgs.pulseaudio}/bin/pactl set-default-sink wivrn.sink

        # ${lib.getExe pkgs.wlx-overlay-s} --openxr
      '';
      settings = {
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
        openvr-compat-path =
          let
            pkg = inputs.nixpkgs-xr.packages.${pkgs.system}.xrizer;
          in
          "${
            pkgs.symlinkJoin {
              name = "xrizer-multilib";
              paths =
                # let
                #   attrs = p: prev: {
                #     nativeBuildInputs = prev.nativeBuildInputs ++ [
                #       p.cmake
                #       p.python3
                #     ];

                #     buildInputs = prev.buildInputs ++ [
                #       p.libGL
                #       p.xorg.libX11
                #       p.wayland
                #       p.xorg.libXrandr
                #       p.xorg.libXxf86vm
                #       p.vulkan-headers
                #     ];

                #     postPatch = ''
                #       substituteInPlace src/graphics_backends/gl.rs \
                #         --replace-fail 'libGLX.so.0' '${lib.getLib p.libGL}/lib/libGLX.so.0'
                #     '';

                #     postInstall = ''
                #       mkdir -p $out/lib/xrizer/$platformPath
                #       mv "$out/lib/libxrizer.so" "$out/lib/xrizer/$platformPath/vrclient.so"
                #     '';
                #   };
                # in
                # [
                #   (pkg.overrideAttrs (attrs pkgs))
                #   ((pkgs.pkgsi686Linux.callPackage pkg.override { }).overrideAttrs (attrs pkgs.pkgsi686Linux))
                # ];
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

            }
          }/lib/xrizer";
        tcp-only = false;
      };
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

{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  options.gaming.vr.enable = lib.mkEnableOption "VR";

  config = lib.mkIf config.gaming.vr.enable {
    nix.settings = {
      substituters = [ "https://nix-community.cachix.org" ];
      trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
    };

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

    services.system76-scheduler.assignments.vr = {
      nice = -12;
      ioClass = "realtime";
      ioPrio = 0;
      matchers = [
        "wivrn-server"
        "wlx-overlay-s"
      ];
    };

    hm.programs.wivrn = {
      enable = true;
      autostart = ''
        #!/bin/sh

        ${pkgs.pulseaudio}/bin/pactl set-default-sink wivrn.sink

        ${lib.getExe pkgs.wlx-overlay-s} --openxr
      '';
      settings = {
        scale = 0.35;
        bitrate = 90000000;
        encoders = [
          {
            encoder = "vaapi";
            codec = "h264";
            width = 0.5;
            height = 0.25;
            offset_x = 0.0;
            offset_y = 0.0;
            group = 0;
          }
          {
            encoder = "vaapi";
            codec = "h264";
            width = 0.5;
            height = 0.75;
            offset_x = 0.0;
            offset_y = 0.25;
            group = 0;
          }
          {
            encoder = "vaapi";
            codec = "h264";
            width = 0.5;
            height = 1.0;
            offset_x = 0.5;
            offset_y = 0.0;
            group = 0;
          }
        ];
        openvr-compat-path = "${inputs.nixpkgs-xr.packages.${pkgs.system}.xrizer}/lib/xrizer";
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

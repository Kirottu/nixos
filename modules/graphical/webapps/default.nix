{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.graphical.webapps = {
    enable = lib.mkEnableOption "Webapp management";
    webapps = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, config, ... }:
          {
            options = {
              title = lib.mkOption {
                type = lib.types.nonEmptyStr;
                description = "Title of the webapp";
              };
              url = lib.mkOption {
                type = lib.types.nonEmptyStr;
                description = "Url for the website";
              };
              icon = lib.mkOption {
                type = lib.types.path;
                description = "Icon name for the desktop entry";
              };
            };
          }
        )
      );
      description = "Attrset of webapps";
      default = { };
    };
  };

  config = {
    impermanence.userDirectories = lib.mkIf config.graphical.webapps.enable [
      ".local/share/webapps"
    ];
    hm =
      let
        pkg = pkgs.wrapFirefox pkgs.firefox-unwrapped {
          extraPolicies = {
            DisableTelemetry = true;
            DisableFirefoxStudies = true;
            EnableTrackingProtection = {
              Value = true;
              Locked = true;
              Cryptomining = true;
              Fingerprinting = true;
            };
            DisablePocket = true;
            DisableFirefoxAccounts = true;
            DisableAccounts = true;
            DisableFirefoxScreenshots = true;
            OverrideFirstRunPage = "";
            OverridePostUpdatePage = "";
            DontCheckDefaultBrowser = true;
            ExtensionSettings = {
              "{5610edea-88c1-4370-b93d-86aa131971d1}" = {
                install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/open-in-internet-explorer/latest.xpi";
                installation_mode = "force_installed";
              };
            };
          };

        };
      in
      lib.mkIf config.graphical.webapps.enable (
        lib.mkMerge (
          [
            {
              mozilla.firefoxNativeMessagingHosts = [
                (
                  (pkgs.callPackage ./open-in-native-client.nix {
                    bins = [ pkgs.xdg-utils ];
                  })
                )
              ];
            }
          ]
          ++ lib.mapAttrsToList (
            name: value:
            let
              data-dir = "webapps/${name}";
            in
            {
              xdg.dataFile = {
                "${data-dir}/user.js".source = ./firefox-profile/user.js;
                "${data-dir}/chrome/userChrome.css".source = ./firefox-profile/chrome/userChrome.css;
                "${data-dir}/places.sqlite" = {
                  source = ./firefox-profile/places.sqlite;
                  force = true;
                };
                "${data-dir}/search.json.mozlz4" = {
                  source = ./firefox-profile/search.json.mozlz4;
                  force = true;
                };
              };

              xdg.desktopEntries."webapp-${name}" = {
                name = value.title;
                icon = value.icon;
                startupNotify = true;
                type = "Application";
                exec = lib.concatStrings [
                  "/bin/sh -c \"XAPP_FORCE_GTKWINDOW_ICON=${value.icon} ${lib.getExe config.hm.programs.firefox.package}"
                  " --class webapp-${name}"
                  " --name webapp-${name}"
                  " --profile ${config.hm.xdg.dataHome}/${data-dir}"
                  " --no-remote"
                  " ${value.url}\""
                ];
                settings = {
                  StartupWMClass = "webapp-${name}";
                };
              };
            }
          ) config.graphical.webapps.webapps
        )
      );
  };
}

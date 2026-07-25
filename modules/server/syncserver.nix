{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.server.syncserver;
  hostname = "ffsync.${config.domain}";
in
{
  options.server.syncserver = {
    enable = lib.mkEnableOption "Firefox Syncserver";
    secrets = lib.mkOption {
      type = lib.types.path;
    };
  };

  config = lib.mkIf cfg.enable {

    impermanence.directories = [
      config.services.mysql.dataDir
    ];

    services.mysql.package = pkgs.mariadb;

    services.firefox-syncserver = {
      enable = true;
      package = pkgs.syncstorage-rs.overrideAttrs (
        old:
        let
          swaggerSrc = pkgs.fetchurl {
            url = "https://github.com/swagger-api/swagger-ui/archive/refs/tags/v5.17.14.zip";
            hash = "sha256-SBJE0IEgl7Efuu73n3HZQrFxYX+cn5UU5jrL4T5xzNw=";
          };

          src = pkgs.fetchFromGitHub {
            owner = "mozilla-services";
            repo = "syncstorage-rs";
            rev = "f084c3c78f91939a69ff10303f6579f7bf538beb";
            hash = "sha256-d0rA/bWuo4gXvqI2inlvRI9NBP6ZRNSwLPkszNIkmhE=";
          };
        in
        {
          inherit src;
          version = "0.23.3";

          cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
            inherit src;
            hash = "sha256-BJ5+6o57WlwsTerKCmOPXATPHQfjr5cRYMbqC8CIPg0=";
          };

          env.SWAGGER_UI_DOWNLOAD_URL = "file://${swaggerSrc}";
        }
      );
      singleNode = {
        inherit hostname;
        enable = true;
        enableTLS = true;
        enableNginx = true;
      };
      secrets = cfg.secrets;
    };
  };
}

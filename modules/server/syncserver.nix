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

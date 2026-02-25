{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.syncserver;
  hostname = "ffsync.${config.domain}";
in
{
  options.syncserver.enable = lib.mkEnableOption "Firefox Syncserver";

  config = lib.mkIf cfg.enable {
    sops.secrets."syncserver/secrets" = {
      sopsFile = ../../secrets/overwatch-of-harold.yaml;
    };

    services.mysql.package = pkgs.mariadb;

    services.firefox-syncserver = {
      enable = true;
      singleNode = {
        inherit hostname;
        enable = true;
        enableTLS = true;
        enableNginx = true;
      };
      secrets = config.sops.secrets."syncserver/secrets".path;
    };
  };
}

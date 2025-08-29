{
  lib,
  config,
  pkgs,
  ...
}:
{
  config = {
    services.nextcloud = {
      enable = false;
      package = pkgs.nextcloud31;
      configureRedis = true;
      https = true;
      hostName = "nc.kirottu.com";
      config = {
        dbtype = "pgsql";
      };
      autoUpdateApps.enable = true;
    };
  };
}

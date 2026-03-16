{ config, lib, ... }:
let
  cfg = config.server.ddclient;
in
{
  options.server.ddclient = {
    enable = lib.mkEnableOption "ddclient";
    domains = lib.mkOption {
      type = lib.types.listOf lib.types.nonEmptyStr;
      default = [ ];
    };
    passwordFile = lib.mkOption {
      type = lib.types.path;
    };
  };

  config = lib.mkIf cfg.enable {
    services.ddclient = {
      enable = true;
      interval = "5min";
      protocol = "namecheap";
      username = config.domain;
      passwordFile = cfg.passwordFile;
      domains = cfg.domains;
    };
  };
}

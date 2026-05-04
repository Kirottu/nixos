{
  config,
  lib,
  ...
}:
let
  cfg = config.net.resolved;
in
{
  options.net.resolved.enable = lib.mkEnableOption "systemd-resolved";

  config = lib.mkIf cfg.enable {
    services.resolved = {
      enable = true;
    };
  };
}

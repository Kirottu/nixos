{
  config,
  lib,
  ...
}:
let
  cfg = config.net.tailscale;
in
{
  options.net.tailscale = {
    enable = lib.mkEnableOption "Tailscale client service";
  };

  config = lib.mkIf cfg.enable {
    impermanence.directories = [ "/var/lib/tailscale" ];

    services.tailscale = {
      enable = true;
      openFirewall = true;
    };
  };
}

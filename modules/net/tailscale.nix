{
  config,
  lib,
  pkgs,
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

    # Automatically restart Tailscale if it is detected that it is offline
    systemd.timers.tailscale-watchdog = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "1min";
        Unit = "tailscale-watchdog.service";
      };
    };

    systemd.services.tailscale-watchdog =
      let
        jq = lib.getExe pkgs.jq;
        systemctl = lib.getExe' pkgs.systemd "systemctl";
        tailscale = lib.getExe pkgs.tailscale;
        timestampPath = "/run/tailscale-watchdog";
        restartTimeout = 120; # 2 minutes
      in
      {
        script = ''
          if [ "$(${tailscale} status --json --peers=false --self=true | ${jq} -r .Self.Online)" == "false" ]; then
            if (( $(date +"%s") - $(cat ${timestampPath}) > ${toString restartTimeout} )); then
              ${systemctl} restart tailscaled.service
            fi
          else
            printf "$(date +"%s")" > ${timestampPath}
          fi
        '';

        serviceConfig = {
          Type = "oneshot";
        };
      };
  };
}

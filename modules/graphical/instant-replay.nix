{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.graphical.instant-replay;
in
{
  options.graphical.instant-replay = {
    enable = lib.mkEnableOption "Instant Replay";
    audioSource = lib.mkOption {
      type = lib.types.nonEmptyStr;
      description = "Audio sources to record";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.gpu-screen-recorder.enable = true;

    hm.systemd.user.services.gpu-screen-recorder = {
      Unit = {
        Description = "Instant Replay via GPU screen recorder";
        BindsTo = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        Requisite = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${lib.getExe pkgs.gpu-screen-recorder} -bm cbr -w portal -r 60 -q 10000 -c mp4 -restore-portal-session yes -o ${config.hm.home.homeDirectory}/Videos/InstantReplay -a ${cfg.audioSource}";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    hm.programs.niri.settings.binds = lib.mkIf config.graphical.niri.enable (
      with config.hm.lib.niri.actions;
      {
        "Mod+P".action = spawn "${pkgs.writeShellScript "instant-replay" ''
          pkill -SIGRTMIN+3 -f gpu-screen-recorder
          ${pkgs.libnotify}/bin/notify-send "Replay saved"
        ''}";
      }
    );
  };
}

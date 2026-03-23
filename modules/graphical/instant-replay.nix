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
    display = lib.mkOption {
      type = lib.types.nonEmptyStr;
      description = "Display to record";
    };
    audioSources = lib.mkOption {
      type = lib.types.listOf lib.types.nonEmptyStr;
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
      Service =
        let
          audioSources = lib.concatStrings (builtins.map (source: "-a ${source} ") cfg.audioSources);
        in
        {
          Type = "simple";
          ExecStart = "${lib.getExe pkgs.gpu-screen-recorder} -v no -bm cbr -w ${cfg.display} -r 60 -q 10000 -c mp4 -o ${config.hm.home.homeDirectory}/Videos/InstantReplay ${audioSources}";
          Restart = "on-failure";
        };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    hm.wayland.windowManager.niri.settings.binds = lib.mkIf config.graphical.niri.enable {
      "Mod+P" = {
        spawn = "${pkgs.writeShellScript "instant-replay" ''
          pkill -SIGRTMIN+3 -f gpu-screen-recorder -H
          sleep 0.1
          FILE=$(journalctl --user -e -u gpu-screen-recorder -n 1 -o cat | tr -d '\n')
          ffmpeg -i $FILE -c:v copy -c:a aac -ac 2 -filter_complex amerge=inputs=${builtins.toString (builtins.length cfg.audioSources)} "$FILE-merged.mp4"
          ${pkgs.libnotify}/bin/notify-send "Replay saved" "Replay saved as $FILE"
        ''}";
      };
    };
  };
}

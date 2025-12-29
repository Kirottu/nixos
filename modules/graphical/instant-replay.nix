{
  config,
  lib,
  ...
}:
let
  cfg = config.graphical.instant-replay;
in
{
  options.graphical.instant-replay = {
    enable = lib.mkEnableOption "Instant Replay";
    screen = lib.mkOption {
      type = lib.types.nonEmptyStr;
      description = "Screen to record";
    };
    audioSources = lib.mkOption {
      type = lib.types.listOf lib.types.nonEmptyStr;
      desription = "Audio sources to record";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.gpu-screen-recorder.enable = true;
  };
}

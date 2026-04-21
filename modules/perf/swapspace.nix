{
  config,
  lib,
  ...
}:
let
  cfg = config.perf.swapspace;
in
{
  options.perf.swapspace = {
    enable = lib.mkEnableOption "Swapspace";
  };

  config = lib.mkIf cfg.enable {
    services.swapspace = {
      enable = true;
      settings = {
        swappath = "/swap/swapspace";
      };
    };
  };
}

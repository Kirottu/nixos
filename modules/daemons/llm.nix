{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.daemons.llm;
in
{
  options.daemons.llm = {
    enable = lib.mkEnableOption "LLM";
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      package = pkgs.ollama-rocm;
    };
    services.open-webui = {
      enable = true;
      host = "0.0.0.0";
    };

    impermanence.directories = [ config.services.open-webui.stateDir ];
  };
}

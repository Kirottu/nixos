{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.devel.llm;
in
{
  options.devel.llm = {
    enable = lib.mkEnableOption "Client side LLM tools";
  };

  config = lib.mkIf cfg.enable {
    environment.sessionVariables = {
      OPENCODE_ENABLE_EXA = 1;
      OPENCODE_EXPERIMENTAL = "true";
      # OPENCODE_DISABLE_LSP_DOWNLOAD = "true";
      OPENCODE_EXPERIMENTAL_LSP_TOOL = "true";
    };

    hm.programs.opencode = {
      enable = true;
      extraPackages = [
        pkgs.nixd
        pkgs.rust-analyzer
      ];
      settings = {
        plugin = [
          "@simonwjackson/opencode-direnv"
          "@tarquinen/opencode-dcp"
        ];
        compaction.auto = false;
        provider = {
          local = {
            name = "Local";
            npm = "@ai-sdk/openai-compatible";
            options = {
              baseURL = "http://${config.daemons.llm.hostname}:${toString config.services.llama-swap.port}/v1";
            };
            models = lib.listToAttrs (
              map (model: {
                name = model.name;
                value = {
                  name = model.name;
                };
              }) config.daemons.llm.modelList
            );
          };
        };
        lsp = { };
      };
    };
    hm.xdg.configFile."opencode/dcp.json".source = (
      (pkgs.formats.json { }).generate "dcp.json" {
        compress.nudgeForce = "strong";
      }
    );

  };
}

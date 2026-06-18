{
  config,
  lib,
  pkgs,
  inputs,
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
      # PI_CODING_AGENT_DIR = "${config.users.users.${config.mainUser.userName}.home}/.config/pi";
    };

    # environment.systemPackages = [ inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi ];

    # hm.xdg.configFile."pi/models.json".source = (pkgs.formats.json { }).generate "models.json" {
    #   providers.local = {
    #     baseUrl = "http://${config.daemons.llm.hostname}:${toString config.daemons.llm.port}/v1";
    #     api = "openai-completions";
    #     apiKey = "ignored";
    #     models = lib.mapAttrsToList (name: value: { id = name; } // value.piOpts) config.daemons.llm.models;
    #   };
    # };

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
              baseURL = "http://${config.daemons.llm.hostname}:${toString config.daemons.llm.port}/v1";
            };
            models = builtins.mapAttrs (name: value: { name = name; }) config.daemons.llm.models;
          };
        };
        lsp = { };
      };
    };

  };
}

{
  pkgs,
  config,
  inputs,
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
    # services.ollama = {
    #   enable = true;
    #   package = pkgs.ollama-rocm;
    # };
    services.open-webui = {
      enable = true;
      port = 8081;
      host = "0.0.0.0";
    };

    services.llama-swap = {
      enable = true;
      # package = inputs.nixpkgs-llama-swap.legacyPackages.${pkgs.stdenv.hostPlatform.system}.llama-swap;
      settings =
        let
          llama-cpp = pkgs.llama-cpp-vulkan;
          llama-server = lib.getExe' llama-cpp "llama-server";

          # Helper: build model config from (name, { filename, isMoe ? false })
          buildModel =
            {
              name,
              filename,
              ttl ? -1,
              isMoe ? false,
              extraArgs ? "",
            }:
            {
              ${name} = {
                inherit ttl;
                cmd =
                  "${llama-server} --port \${PORT} -m /var/lib/llama-cpp/models/${filename} -fit on ${extraArgs}"
                  + lib.optionalString isMoe " --cpu-moe";
              };
            };

          # Your models: just list the data
          modelList = [
            {
              name = "qwen2.5-3b";
              ttl = 60;
              filename = "Qwen2.5-Coder-3B-Q8_0.gguf";
              extraArgs = "-md /var/lib/llama-cpp/models/Qwen2.5-Coder-0.5B-Q8_0.gguf";
            }
            {
              name = "qwen3-coder-next";
              filename = "Qwen3-Coder-Next-UD-Q4_K_XL.gguf";
              isMoe = true;
            }
            {
              name = "qwen3.6-35b-a3b";
              ttl = 120;
              filename = "Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf";
              isMoe = true;
            }
          ];

        in
        {
          healthCheckTimeout = 45;
          # Merge all model configs into one attrset
          models = lib.foldl (acc: m: acc // buildModel m) { } modelList;
        };
    };

    environment.systemPackages = [
      pkgs.opencode-desktop
      pkgs.opencode
    ];

    impermanence.directories = [
      "/var/lib/llama-cpp"
      "/var/lib/private"
      # config.services.open-webui.stateDir
    ];
  };
}

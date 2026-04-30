{
  pkgs,
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.daemons.llm;
  # Your models: just list the data
  modelList = [
    {
      name = "qwen2.5-3b";
      ttl = 60;
      filename = "Qwen2.5-Coder-3B-Q8_0.gguf";
      extraArgs = "-md /var/lib/llama-cpp/models/Qwen2.5-Coder-0.5B-Q8_0.gguf";
    }
    {
      name = "qwen3.6-35b-a3b";
      ttl = 300;
      # filename = "Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf";
      filename = "Qwen3.6-35B-A3B-Claude-4.6-Opus-Reasoning-Distilled-UD-Q4_K_XL.gguf";
      # extraArgs = "--no-mmap -md /var/lib/llama-cpp/models/Qwen3.6-35B-A3B-DFlash-q8_0.gguf";
      # My RX 6700 XT has 96 mb of L3 cache, this should apparently speed up prompt processing.
      extraArgs = "--no-mmap";
      isMoe = true;
    }
    {
      name = "darwin-36b-opus";
      ttl = 300;
      # filename = "Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf";
      filename = "FINAL-Bench_Darwin-36B-Opus-Q4_K_L.gguf";
      # extraArgs = "--no-mmap -md /var/lib/llama-cpp/models/Qwen3.6-35B-A3B-DFlash-q8_0.gguf";
      # My RX 6700 XT has 96 mb of L3 cache, this should apparently speed up prompt processing.
      extraArgs = "--no-mmap";
      isMoe = true;
    }
    # {
    #   name = "qwen3-8b";
    #   ttl = 120;
    #   filename = "Qwen3-8B-UD-Q5_K_XL.gguf";
    # }
    {
      name = "qwen3.5-9b";
      ttl = 120;
      filename = "Qwen3.5-9B-UD-Q4_K_XL.gguf";
      extraArgs = "-md /var/lib/llama-cpp/models/Qwen3.5-0.8B-UD-Q4_K_XL.gguf --no-kv-offload";
    }
  ];

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
    # services.open-webui = {
    #   enable = true;
    #   port = 8081;
    #   host = "0.0.0.0";
    # };

    services.llama-swap = {
      enable = true;
      # package = inputs.nixpkgs-llama-swap.legacyPackages.${pkgs.stdenv.hostPlatform.system}.llama-swap;
      settings =
        let
          # llama-cpp = pkgs.llama-cpp-rocm.overrideAttrs {
          #   src = pkgs.fetchFromGitHub {
          #     owner = "ruixiang63";
          #     repo = "llama.cpp";
          #     rev = "d1d2c81caccc748eaaff32b6b7823bad090fd1dd";
          #     hash = "sha256-ezbrXlVz+4RtHalAXGe01DBUUmD4bYfqhTtQQ4PO/gg=";
          #     leaveDotGit = true;
          #     postFetch = ''
          #       git -C "$out" rev-parse --short HEAD > $out/COMMIT
          #       find "$out" -name .git -print0 | xargs -0 rm -rf
          #     '';
          #   };
          #   npmDepsHash = "sha256-DxgUDVr+kwtW55C4b89Pl+j3u2ILmACcQOvOBjKWAKQ=";
          # };
          llama-cpp = pkgs.llama-cpp-rocm;
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
                  "${llama-server} --port \${PORT} -m /var/lib/llama-cpp/models/${filename} -fit on ${extraArgs} --ubatch-size 96"
                  + lib.optionalString isMoe " --cpu-moe";
              };
            };

        in
        {
          healthCheckTimeout = 60;
          # Merge all model configs into one attrset
          models = lib.foldl (acc: m: acc // buildModel m) { } modelList;
        };
    };

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
        provider = {
          local = {
            name = "Local";
            npm = "@ai-sdk/openai-compatible";
            options = {
              baseURL = "http://localhost:${toString config.services.llama-swap.port}/v1";
            };
            models = lib.listToAttrs (
              map (model: {
                name = model.name;
                value = {
                  name = model.name;
                };
              }) modelList
            );
          };
        };
        lsp = { };
      };
    };

    impermanence.directories = [
      "/var/lib/llama-cpp"
      # config.services.open-webui.stateDir
    ];
  };
}

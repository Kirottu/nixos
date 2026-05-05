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
    enable = lib.mkEnableOption "llama-swap daemon";
    hostname = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default =
        if config.net.tailscale.enable then "router-of-harold.tailnet.kirottu.com" else "localhost";
    };
    modelList = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [
        {
          name = "qwen2.5-3b";
          ttl = 60;
          filename = "Qwen2.5-Coder-3B-Q8_0.gguf";
          extraArgs = "-md /var/lib/llama-cpp/models/Qwen2.5-Coder-0.5B-Q8_0.gguf";
        }
        {
          name = "qwen3.6-35b-a3b";
          ttl = 600;
          # filename = "Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf";
          # filename = "Qwen3.6-35B-A3B-Claude-4.6-Opus-Reasoning-Distilled-UD-Q4_K_XL.gguf";
          filename = "Qwen3.6-35B-A3B-UD-Q4_K_S.gguf";
          # extraArgs = "--no-mmap -md /var/lib/llama-cpp/models/Qwen3.6-35B-A3B-DFlash-q8_0.gguf";
          # My RX 6700 XT has 96 mb of L3 cache, this should apparently speed up prompt processing.
          isMoe = true;
        }
        {
          name = "qwopus3.6-35b-a3b";
          ttl = 600;
          filename = "Qwen3.6-35B-A3B-Claude-4.6-Opus-Reasoning-Distilled-UD-Q4_K_XL.gguf";
          extraArgs = "-c 128000";
          isMoe = true;
        }
      ];
    };
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
      listenAddress = "0.0.0.0";
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
                  "${llama-server} --port \${PORT} --host 0.0.0.0 -m /var/lib/llama-cpp/models/${filename} -fit on ${extraArgs} --no-mmap --mlock -ub 2048 -ctk q8_0 -ctv q8_0 -fa on --tools all"
                  + lib.optionalString isMoe " --cpu-moe";
              };
            };

        in
        {
          healthCheckTimeout = 60;
          # Merge all model configs into one attrset
          models = lib.foldl (acc: m: acc // buildModel m) { } cfg.modelList;
        };
    };

    systemd.services.llama-swap.serviceConfig = {
      # Increase memlock limit to allow preventing the model from getting swapped
      LimitMEMLOCK = 202116300800;
    };

    impermanence.directories = [
      "/var/lib/llama-cpp"
      # config.services.open-webui.stateDir
    ];

  };
}

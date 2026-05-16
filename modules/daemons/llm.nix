{
  pkgs,
  config,
  inputs,
  lib,
  ...
}:
let
  cfg = config.daemons.llm;
  # Base llama.cpp settings
  iniFormat = pkgs.formats.ini { };
in
{
  options.daemons.llm = {
    enable = lib.mkEnableOption "llama-swap daemon";
    hostname = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default =
        if config.net.tailscale.enable then "router-of-harold.tailnet.kirottu.com" else "localhost";
    };
    port = lib.mkOption {
      type = lib.types.number;
      default = 8080;
    };
    # modelList = lib.mkOption {
    #   type = lib.types.listOf lib.types.attrs;
    #   default = [
    #     {
    #       name = "qwopus3.6-35b-a3b";
    #       ttl = 600;
    #       filename = "Qwen3.6-35B-A3B-Claude-4.6-Opus-Reasoning-Distilled-UD-Q4_K_XL.gguf";
    #       extraArgs = "-c 128000";
    #       isMoe = true;
    #     }
    #     {
    #       name = "qwen3.6-35b-a3b";
    #       ttl = 600;
    #       filename = "Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf";
    #       extraArgs = "-c 128000 --mmproj /var/lib/llama-cpp/models/Qwen3.6-35b-a3b-mmproj-F16.gguf";
    #       isMoe = true;
    #     }
    #     {
    #       name = "qwen2.5-3b";
    #       ttl = 60;
    #       filename = "Qwen2.5-Coder-3B-Q8_0.gguf";
    #       extraArgs = "-md /var/lib/llama-cpp/models/Qwen2.5-Coder-0.5B-Q8_0.gguf";
    #     }
    #   ];
    # };
    models = lib.mkOption {
      type = iniFormat.type;
      default = {
        "Qwen3.6-35B-A3B" = {
          model = "/var/lib/llms/Qwen3.6-35B-A3B-MTP-UD-Q4_K_S.gguf";
          # mmproj = "/var/lib/llms/Qwen3.6-35b-a3b-mmproj-F16.gguf";
          # spec-type = "mtp";
          # no-mmap = true;
          # spec-draft-n-max = 3;
          cpu-moe = true;
          c = 128000;
        };
        "Qwopus3.6-35B-A3B" = {
          model = "/var/lib/llms/Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf";
          cpu-moe = true;
          c = 128000;
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.llama-cpp = {
      enable = true;
    };

    systemd.services.llama-cpp.serviceConfig =
      let
        settings = {
          # version = 1;
          "*" = {
            # Optimization
            fit = true;
            mlock = true;
            ub = 2048;
            b = 2048;
            ctk = "turbo4";
            ctv = "turbo4";
            # ctk = "q8_0";
            # ctv = "q8_0";
            fa = true;
            cram = 2048;

            sleep-idle-seconds = 300;
          };
        }
        // cfg.models;
        ini = iniFormat.generate "models-preset" settings;
        llama-cpp = pkgs.llama-cpp-rocm.overrideAttrs {
          src = pkgs.fetchFromGitHub {
            owner = "EsmaeelNabil";
            repo = "llama.cpp";
            rev = "a578bb6b94529b7b2721d0ee49eaea5dbb2c6d07";
            hash = "sha256-oVkfp2bBuyYr/kHc6+MFMGxBq31gI1VvwFg0FZ2kI0g=";
            leaveDotGit = true;
            postFetch = ''
              git -C "$out" rev-parse --short HEAD > $out/COMMIT
              find "$out" -name .git -print0 | xargs -0 rm -rf
            '';
          };
          npmDepsHash = "sha256-cV3noOyKmst9vfxyvkCNhihPgwfVGhmPPT4UMloeWZM=";
        };
        # llama-cpp = pkgs.llama-cpp-rocm.overrideAttrs {
        #   src = pkgs.fetchFromGitHub {
        #     owner = "am17an";
        #     repo = "llama.cpp";
        #     rev = "e7b4848151377395b1693d326d1cda3fcd61c2d9";
        #     hash = "sha256-ZfuwyrWjvpM7nKwkxO+drYAo8HpES3Qtm9nu6wspNU0=";
        #     leaveDotGit = true;
        #     postFetch = ''
        #       git -C "$out" rev-parse --short HEAD > $out/COMMIT
        #       find "$out" -name .git -print0 | xargs -0 rm -rf
        #     '';
        #   };
        #   npmDepsHash = "sha256-cV3noOyKmst9vfxyvkCNhihPgwfVGhmPPT4UMloeWZM=";
        # };
      in
      {
        # Increase memlock limit to allow preventing the model from getting swapped
        LimitMEMLOCK = 202116300800;
        ExecStart = lib.mkForce (
          lib.concatStringsSep " " [
            (lib.getExe' llama-cpp "llama-server")
            "--host 0.0.0.0 --port ${toString cfg.port}"
            "--models-preset ${ini}"
            "--models-max 1"
            "--tools all"
          ]
        );
      };

    impermanence.directories = [
      # "/var/lib/llama-cpp"
      "/var/lib/llms"
      # config.services.open-webui.stateDir
    ];

  };
}

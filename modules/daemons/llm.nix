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
        if config.net.tailscale.enable then "church-of-harold.tailnet.kirottu.com" else "localhost";
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
      type = lib.types.attrs;
      default =
        let
          qwenDefault = rec {
            spec-type = "ngram-mod,draft-mtp";
            spec-draft-n-max = 3;
            cpu-moe = true;
            c = 262144;

            reasoning-budget = 4096;
            reasoning-budget-message = ". OK, I've thought about this enough. Let's proceed.";

            piOpts = {
              contextWindow = c;
              maxTokens = c;
              reasoning = true;
            };
          };
        in
        {
          "Qwen3.6-35B-A3B" = {
            model = "/var/lib/llms/Qwen3.6-35B-A3B-MTP-UD-Q4_K_S.gguf";
          }
          // qwenDefault;
          "Qwopus3.6-35B-A3B-APEX-Nano" = {
            model = "/var/lib/llms/Qwen3.6-35B-A3B-Claude-4.7-Opus-Reasoning-Distilled-APEX-MTP-I-Nano.gguf";
            sleep-idle-seconds = 30;
          }
          // qwenDefault;
          "Qwopus3.6-35B-A3B-APEX-Compact" = {
            model = "/var/lib/llms/Qwen3.6-35B-A3B-Claude-4.7-Opus-Reasoning-Distilled-APEX-MTP-I-Compact.gguf";
            cram = 8192;
          }
          // qwenDefault;
          "Qwopus3.6-35B-A3B-APEX-Quality" = {
            model = "/var/lib/llms/Qwen3.6-35B-A3B-Claude-4.7-Opus-Reasoning-Distilled-APEX-MTP-I-Quality.gguf";
          }
          // qwenDefault;
        };
    };
  };

  config = lib.mkIf cfg.enable {
    services.llama-cpp =
      let
        llama-cpp =
          inputs.nixpkgs-master.legacyPackages.${pkgs.stdenv.hostPlatform.system}.llama-cpp-vulkan.overrideAttrs
            (prev: rec {
              version = "9521";
              src = pkgs.fetchFromGitHub {
                owner = "ggml-org";
                repo = "llama.cpp";
                tag = "b${version}";
                hash = "sha256-Veph82amdJn90NiPIxOhtK7ECXfQVu6wWmflU26Qe2I=";
                leaveDotGit = true;
                postFetch = ''
                  git -C "$out" rev-parse --short HEAD > $out/COMMIT
                  find "$out" -name .git -print0 | xargs -0 rm -rf
                '';
              };

              # src = pkgs.fetchFromGitHub {
              #   owner = "TheTom";
              #   repo = "llama-cpp-turboquant";
              #   rev = "2b61ea24ef4fef435866301b7c953434e4fcb866";
              #   hash = "sha256-gMYQJTQkOb7pZ2LAvfRWX9uFgaJ0EsrW+Yq0l7BXHus=";
              #   leaveDotGit = true;
              #   postFetch = ''
              #     git -C "$out" rev-parse --short HEAD > $out/COMMIT
              #     find "$out" -name .git -print0 | xargs -0 rm -rf
              #   '';
              # };
              #

              npmDepsHash = "sha256-pjdbI6NcZRlJVd62xhgbLhWrwFYwgsIwjORqvo1+VD8=";

              cmakeFlags = prev.cmakeFlags ++ [
                (lib.cmakeBool "GGML_CPU_ALL_VARIANTS" true)
                (lib.cmakeBool "GGML_BACKEND_DL" true)
              ];
            });
        # llama-cpp =
        #   inputs.nixpkgs-master.legacyPackages.${pkgs.stdenv.hostPlatform.system}.llama-cpp-rocm.overrideAttrs
        #     (prev: {
        #       cmakeFlags = prev.cmakeFlags ++ [
        #         (lib.cmakeBool "GGML_CPU_ALL_VARIANTS" true)
        #         (lib.cmakeBool "GGML_BACKEND_DL" true)
        #       ];
        #     });

      in
      {
        package = llama-cpp;
        enable = true;
        host = "0.0.0.0";
        port = cfg.port;
        extraFlags = [
          "--tools"
          "all"
        ];
        modelsPreset = {
          # version = 1;
          "*" = {
            # Optimization
            fit = true;
            mlock = true;
            ub = 1024;
            b = 2048;
            # ctk = "q8_0";
            # ctv = "turbo2";
            ctk = "q8_0";
            ctv = "q4_0";
            fa = true;
            cram = 1024;
            tools = "all";

            sleep-idle-seconds = 300;
          };
        }
        // builtins.mapAttrs (
          name: value: lib.filterAttrs (name: value: name != "piOpts") value
        ) cfg.models;
      };

    # llama.cpp sleep mode for some reason tanks any subsequent performance,
    # hence this horribleness makes sure to actually unload any models whenever they
    # enter sleeping state
    systemd.timers."llama.cpp-watchdog" = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "1s";
        Unit = "llama.cpp-watchdog.service";
      };
    };

    systemd.services."llama.cpp-watchdog" =
      let
        curl = lib.getExe pkgs.curl;
        jq = lib.getExe pkgs.jq;
        baseUrl = "http://localhost:${toString cfg.port}";
      in
      {
        script = lib.concatStrings (
          lib.mapAttrsToList (name: value: ''
            if [ "$(${curl} -s ${baseUrl}/models | ${jq} -r '.data[] | select(.id=="${name}") | .status.value')" == "sleeping" ]; then
              ${curl} -s -X POST -H "Content-Type: application/json" --data '{"model": "${name}"}' ${baseUrl}/models/unload
            fi
          '') cfg.models
        );
        serviceConfig = {
          Type = "oneshot";
        };
      };

    systemd.services.llama-cpp.serviceConfig = {
      # Increase memlock limit to allow preventing the model from getting swapped
      LimitMEMLOCK = 202116300800;
    };

    impermanence.directories = [
      # "/var/lib/llama-cpp"
      "/var/lib/llms"
      # config.services.open-webui.stateDir
    ];

  };
}

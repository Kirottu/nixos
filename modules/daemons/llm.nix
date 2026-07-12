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
    gatedPort = lib.mkOption {
      description = "Resource gated proxy for llama.cpp";
      type = lib.types.number;
      default = 8081;
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
          qwenDefault = {
            # spec-type = "draft-mtp";
            # spec-draft-n-max = 3;
            # spec-draft-p-min = 0.75;
            # n-cpu-moe = 30;
            # c = 262144;
            # repeat-penalty = 1.1;

            chat-template-kwargs = "{\"preserve_thinking\": true}";
            # mmproj = "/var/lib/llms/Qwen3.6-35b-a3b-mmproj-F16.gguf";
          };
        in
        {
          "Gemma4" = {
            model = "/var/lib/llms/gemma-4-26B-A4B-APEX-I-Compact.gguf";
            n-cpu-moe = 22;
            temperature = 1.0;
            top-p = 0.95;
            top-k = 64;
          };
          "Agents-A1" = {
            model = "/var/lib/llms/Agents-A1-APEX-I-Compact.gguf";
            n-cpu-moe = 32;
            # model = "/var/lib/llms/Agents-A1-APEX-I-Quality.gguf";
            # n-cpu-moe = 35;
            temperature = 0.85;
            top-p = 0.95;
            min-p = 0.0;
            top-k = 20;
            presence-penalty = 1.1;
            sleep-idle-seconds = 30;
            # mmproj = "/var/lib/llms/mmproj-Agents-A1.gguf";
            # no-mmproj-offload = true;
          };
          "Ornith-1.0-35B-APEX-Compact" = {
            model = "/var/lib/llms/Ornith-1.0-35B-APEX-I-Compact.gguf";
            n-cpu-moe = 30;
            # cpu-moe = true;
            temperature = 0.6;
          }
          // qwenDefault;
          "Qwen3.6-35B-A3B" = {
            model = "/var/lib/llms/Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf";
            # cpu-moe = true;
            n-cpu-moe = 30;
            # cram = 4096;
          }
          // qwenDefault;
          "Qwopus3.6-35B-A3B-APEX-Compact" = {
            model = "/var/lib/llms/Qwopus3.6-35B-A3B-v1-APEX-MTP-I-Compact.gguf";
            # cram = 8192;
            temperature = 1.0;
            # dry-multiplier = 0.6;
            # dry-allowed-length = 2;

            n-cpu-moe = 32;

          }
          // qwenDefault;
          "Qwopus3.6-35B-A3B-APEX-Compact-Coding" = {
            model = "/var/lib/llms/Qwopus3.6-35B-A3B-v1-APEX-MTP-I-Compact.gguf";
            # cram = 8192;
            temperature = 0.6;

            n-cpu-moe = 32;

          }
          // qwenDefault;
          "Qwopus3.6-35B-A3B-APEX-Quality" = {
            # model = "/var/lib/llms/Qwen3.6-35B-A3B-Claude-4.7-Opus-Reasoning-Distilled-APEX-MTP-I-Quality.gguf";
            model = "/var/lib/llms/Qwopus3.6-35B-A3B-v1-APEX-MTP-I-Quality.gguf";
            # temperature = 1.0;
            # reasoning-budget = 4096;
            # reasoning-budget-message = "OK, I've thought about this enough. Let's proceed.";

            cpu-moe = true;
          }
          // qwenDefault;
          "Qwopus3.6-35B-A3B-APEX-Quality-Coding" = {
            # model = "/var/lib/llms/Qwen3.6-35B-A3B-Claude-4.7-Opus-Reasoning-Distilled-APEX-MTP-I-Quality.gguf";
            model = "/var/lib/llms/Qwopus3.6-35B-A3B-v1-APEX-MTP-I-Quality.gguf";
            cpu-moe = true;
            temperature = 0.6;
            top-p = 0.9;
          }
          // qwenDefault;
        };
    };
    clankerSecrets = lib.mkOption {
      type = lib.types.path;
    };
  };

  imports = [
    inputs.hermes-agent.nixosModules.default
  ];

  config = lib.mkIf cfg.enable {
    services.llama-cpp =
      let
        # llama-cpp = pkgs.llama-cpp-rocm;
        # Mainline
        # llama-cpp =
        #   (pkgs.llama-cpp.override {
        #     rocmSupport = true;
        #     rocmGpuTargets = [ "gfx1030" ];
        #     # vulkanSupport = true;
        #   }).overrideAttrs
        #     (prev: rec {
        #       # version = "9821";
        #       version = "9859";
        #       src = pkgs.fetchFromGitHub {
        #         owner = "ggml-org";
        #         repo = "llama.cpp";
        #         tag = "b${version}";
        #         # hash = "sha256-gkE3weJIQGDaGgVPRok+I08n1HfGD9tnugy7HBdlqCs=";
        #         hash = "sha256-htIMo3pOldoELyHyGIZ4voUJeay3fymIIRy89Z8gNK8=";
        #         leaveDotGit = true;
        #         postFetch = ''
        #           git -C "$out" rev-parse --short HEAD > $out/COMMIT
        #           find "$out" -name .git -print0 | xargs -0 rm -rf
        #         '';
        #       };

        #       # npmDepsHash = "sha256-X1DZgmhS/zHTqDT5zq0kywwntthcJ9vRXeqyO3zz6UU=";
        #       npmDepsHash = "sha256-X1DZgmhS/zHTqDT5zq0kywwntthcJ9vRXeqyO3zz6UU=";
        #     });
        # # Auto save slots on router
        # llama-cpp =
        #   (pkgs.llama-cpp.override {
        #     rocmSupport = true;
        #     rocmGpuTargets = [ "gfx1030" ];
        #     # vulkanSupport = true;
        #   }).overrideAttrs
        #     (prev: rec {
        #       # version = "9821";
        #       version = "9600";
        #       src = pkgs.fetchFromGitHub {
        #         owner = "dark-penguin";
        #         repo = "llama.cpp";
        #         rev = "368caf763879de72a5c41828705f3d0e7fde7eb9";
        #         hash = "sha256-kbyscjMjikWmjv9Fkq0UOp3HER8QTOOgwdMcRMqzSqo=";
        #         leaveDotGit = true;
        #         postFetch = ''
        #           git -C "$out" rev-parse --short HEAD > $out/COMMIT
        #           find "$out" -name .git -print0 | xargs -0 rm -rf
        #         '';
        #       };

        #       npmDepsHash = "sha256-pjdbI6NcZRlJVd62xhgbLhWrwFYwgsIwjORqvo1+VD8=";
        #     });
        # Local
        llama-cpp =
          (pkgs.llama-cpp.override {
            rocmSupport = true;
            rocmGpuTargets = [ "gfx1030" ];
            # vulkanSupport = true;
          }).overrideAttrs
            (prev: rec {
              # version = "9821";
              # version = "9873";
              version = "9902";
              src = pkgs.fetchgit {
                url = "http://localhost:8082";
                hash = "sha256-PhzaWAEoSfL4fkdDcC5kdfvkCWLCMkcODxTqs/672cQ=";
                rev = "c5a0978cbbbe0a27b2eddc7e6cedd7e07b7833ef";
                # hash = "sha256-U8IQXS0QUKMx4+5ZpJSP99m2HBc0aelk4FF269kCkog=";
                # rev = "ef8640fd93fefbf61db318fc41a3fb9aa2e65f57";
                leaveDotGit = true;
                postFetch = ''
                  git -C "$out" rev-parse --short HEAD > $out/COMMIT
                  find "$out" -name .git -print0 | xargs -0 rm -rf
                '';
              };

              npmDepsHash = "sha256-X1DZgmhS/zHTqDT5zq0kywwntthcJ9vRXeqyO3zz6UU=";
              # npmDepsHash = lib.fakeHash;
            });
        # llama-cpp =
        #   (pkgs.llama-cpp.override {
        #     rocmGpuTargets = [ "gfx1030" ];
        #     rocmSupport = true;
        #   }).overrideAttrs
        #     (prev: {
        #       version = "9190";
        #       src = pkgs.fetchFromGitHub {
        #         owner = "TheTom";
        #         repo = "llama-cpp-turboquant";
        #         rev = "7d9715f1f071fa07c7b2ad3dbfd320b314139e65";
        #         hash = "sha256-zXACPksSyY+HzDRJO/CbAyG/MrTdnsJ01GvOrsOhFSc=";
        #         leaveDotGit = true;
        #         postFetch = ''
        #           git -C "$out" rev-parse --short HEAD > $out/COMMIT
        #           find "$out" -name .git -print0 | xargs -0 rm -rf
        #         '';
        #       };

        #       npmDepsHash = "sha256-WaEePrEZ7O/7deP2KJhe0AwiSKYA8HOqETmMHUkmBe0=";

        #       cmakeFlags = prev.cmakeFlags ++ [
        #         (lib.cmakeBool "GGML_CPU_ALL_VARIANTS" true)
        #         (lib.cmakeBool "GGML_BACKEND_DL" true)
        #         # (lib.cmakeBool "GGML_HIP_ROCWMMA_FATTN" true)
        #       ];
        #     });
        # llama-cpp =
        #   inputs.nixpkgs-master.legacyPackages.${pkgs.stdenv.hostPlatform.system}.llama-cpp-vulkan.overrideAttrs
        #     (prev: rec {
        #       version = "9521";
        #       src = pkgs.fetchFromGitHub {
        #         owner = "ggml-org";
        #         repo = "llama.cpp";
        #         tag = "b${version}";
        #         hash = "sha256-Veph82amdJn90NiPIxOhtK7ECXfQVu6wWmflU26Qe2I=";
        #         leaveDotGit = true;
        #         postFetch = ''
        #           git -C "$out" rev-parse --short HEAD > $out/COMMIT
        #           find "$out" -name .git -print0 | xargs -0 rm -rf
        #         '';
        #       };

        #       npmDepsHash = "sha256-pjdbI6NcZRlJVd62xhgbLhWrwFYwgsIwjORqvo1+VD8=";
        #       # npmDepsHash = "sha256-WaEePrEZ7O/7deP2KJhe0AwiSKYA8HOqETmMHUkmBe0=";

        #       cmakeFlags = prev.cmakeFlags ++ [
        #         (lib.cmakeBool "GGML_CPU_ALL_VARIANTS" true)
        #         (lib.cmakeBool "GGML_BACKEND_DL" true)
        #       ];
        #     });
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
        settings = {
          host = "0.0.0.0";
          port = cfg.port;
          tools = "all";
          models-max = 1;
          models-preset = iniFormat.generate "models.ini" (
            {
              # version = 1;
              "*" = {
                # Optimization
                fit = true;
                fit-target = 2048;
                mlock = true;
                ub = 2048;
                b = 2048;
                # moe-cache = 2048;
                # ub = 512;
                # b = 512;
                # ctk = "q8_0";
                reasoning-budget = 4096;
                reasoning-budget-message = "OK, I've thought about this enough. Let's proceed.";
                slot-save-path = "/var/lib/private/llama-cpp";
                # ctv = "turbo2";
                ctk = "q8_0";
                ctv = "q8_0";
                fa = true;
                cram = 4096;
                tools = "all";
                np = 4;
                kv-unified = true;
                ctx-checkpoints = 4;
                lv = 4;
                no-mmap = true;
              };
            }
            // cfg.models
          );
        };
      };

    # llama.cpp sleep mode for some reason tanks any subsequent performance,
    # hence this horribleness makes sure to actually unload any models whenever they
    # enter sleeping state
    # systemd.timers."llama.cpp-watchdog" = {
    #   wantedBy = [ "timers.target" ];
    #   timerConfig = {
    #     OnBootSec = "5min";
    #     OnUnitActiveSec = "1s";
    #     Unit = "llama.cpp-watchdog.service";
    #   };
    # };

    # systemd.services."llama.cpp-watchdog" =
    #   let
    #     curl = lib.getExe pkgs.curl;
    #     jq = lib.getExe pkgs.jq;
    #     baseUrl = "http://localhost:${toString cfg.port}";
    #   in
    #   {
    #     script = lib.concatStrings (
    #       lib.mapAttrsToList (name: value: ''
    #         if [ "$(${curl} -s ${baseUrl}/models | ${jq} -r '.data[] | select(.id=="${name}") | .status.value')" == "sleeping" ]; then
    #           ${curl} -s -X POST -H "Content-Type: application/json" --data '{"model": "${name}"}' ${baseUrl}/models/unload
    #         fi
    #       '') cfg.models
    #     );
    #     serviceConfig = {
    #       Type = "oneshot";
    #     };
    #   };

    systemd.services.llama-cpp = {
      path = [ pkgs.ffmpeg ];
      serviceConfig = {
        # Increase memlock limit to allow preventing the model from getting swapped
        LimitMEMLOCK = 202116300800;
      };
      environment = {
        RADV_PERTEST = "nogttspill";
        HSA_OVERRIDE_GFX_VERSION = "10.3.0";
        # GPU_MAX_HW_QUEUES = "1";
        # GGML_CUDA_MOE_CACHE_MIN_EXPERT_KB = "0";
      };
    };

    systemd.services.gated-proxy = {
      description = "Resource gated LLM proxy";
      wantedBy = [ "multi-user.target" ];

      environment = {
        GATED_PROXY_CONFIG = (pkgs.formats.json { }).generate "gated-proxy-config.json" {
          host = "0.0.0.0";
          port = cfg.gatedPort;
          target_host = "127.0.0.1";
          target_port = cfg.port;

          gpu = "AMD Radeon RX 6700 XT";
          load_average_window = 15;
          cpu_load_average_thresh = 40.0;
          gpu_load_average_thresh = 30.0;
          model_loaded_grace = 120;

          idle_unload_timeouts = { };
        };
        RUST_LOG = "info";
      };

      serviceConfig = {
        ExecStart = lib.getExe inputs.gated-proxy.packages.${pkgs.stdenv.hostPlatform.system}.gated-proxy;
        Restart = "on-failure";
        DynamicUser = true;
        CapabilityBoundingSet = [ "" ];
        LockPersonality = true;
        PrivateTmp = true;
        ProcSubset = "all";
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "default";
        ProtectSystem = "strict";
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
      };
    };

    environment.systemPackages = [
      inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.tui
      # (
      #   inputs.nixpkgs-vllm.legacyPackages.${pkgs.stdenv.hostPlatform.system}.python313Packages.vllm.override
      #   {
      #     rocmSupport = true;
      #   }
      # )
    ];

    services.hermes-agent = {
      enable = true;
      environmentFiles = [
        cfg.clankerSecrets
        "${pkgs.writeText "hermes-env" ''
          LCM_CONTEXT_THRESHOLD=0.40
        ''}"
      ];
      mcpServers = {
        exa.url = "https://mcp.exa.ai/mcp";
      };
      extraDependencyGroups = [
        "matrix"
      ];
      extraPlugins = [
        (pkgs.fetchFromGitHub {
          owner = "stephenschoettler";
          repo = "hermes-lcm";
          # rev = "08980b7c6728e846745a603046ab012deb3f9c71";
          tag = "v0.19.0";
          # hash = "sha256-c5ycRJkce+NuHGwvb2j2gsyRMiVxtFHsYDFnpaZDFYA=";
          hash = "sha256-B80HCn3BT+M1B8THMm3Ph5tpimTB68yIVkBfPaV4X40=";
        })
      ];
      addToSystemPackages = true;
      container = {
        enable = true;
        backend = "podman";
        hostUsers = [ config.mainUser.userName ];
      };
      settings = {
        timezone = "Europe/Helsinki";
        plugins = {
          enabled = [
            "hermes-lcm"
          ];
          hermes-memory-store = {
            auto_extract = true;
          };
        };
        model = {
          base_url = "http://localhost:${toString cfg.gatedPort}/v1";
          provider = "custom";
          # default = "Qwen3.6-35B-A3B";
          # default = "Qwopus3.6-35B-A3B-APEX-Compact";
          # default = "Ornith-1.0-35B-APEX-Compact";
          # context_length = 257536;
          # default = "Gemma4";
          # context_length = 222464;
          default = "Agents-A1";
          context_length = 262144;
        };
        auxiliary = {
          # The default auxiliary client timeout of 30 s simply isn't feasible on my hardware
          title_generation.timeout = 3600;
          extraction.timeout = 3600;
          compression.timeout = 3600;
        };
        terminal = {
          backend = "local";
        };
        memory = {
          provider = "holographic";
          memory_enabled = true;
          user_profile_enabled = true;
        };
        agent = {
          api_max_retries = 200;
        };
        context = {
          engine = "lcm";
        };
      };
    };

    security.sudo-rs.extraRules = [
      {
        users = [ config.mainUser.userName ];
        commands = [
          {
            command = "/run/current-system/sw/bin/podman";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

    # mainUser.extraGroups = [ config.services.hermes-agent.group ];

    impermanence.directories = [
      # "/var/lib/llama-cpp"
      "/var/lib/llms"
      {
        directory = config.services.hermes-agent.stateDir;
        user = config.services.hermes-agent.user;
        group = config.services.hermes-agent.group;
      }
      # {
      #   directory = config.services.zeroclaw.instances.assistant.dataDir;
      #   user = config.services.zeroclaw.instances.assistant.user;
      #   group = config.services.zeroclaw.instances.assistant.group;
      # }
      # config.services.open-webui.stateDir
    ];

  };
}

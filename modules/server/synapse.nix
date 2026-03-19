{
  config,
  lib,
  inputs,
  pkgs,
  utils,
  ...
}:
let
  port = 8448;
  matrixDomain = "matrix.${config.domain}";
  url = "https://${matrixDomain}";
  clientConfig = {
    "m.homeserver".base_url = url;
    "org.matrix.msc3575.proxy"."url" = url;
    "org.matrix.msc4143.rtc_foci" = [
      {
        "type" = "livekit";
        "livekit_service_url" = "https://${config.server.matrix-rtc.domain}/livekit/jwt";
      }
    ];
  };
  serverConfig."m.server" = "${matrixDomain}:${builtins.toString port}";
  mkWellKnown = data: ''
    default_type application/json;
    add_header Access-Control-Allow-Origin *;
    return 200 '${builtins.toJSON data}';
  '';
  workerLogConfig =
    name:
    (pkgs.formats.yaml { }).generate "log_config_${name}" {
      disable_existing_loggers = false;
      formatters = {
        journal_fmt = {
          format = "%(name)s: [%(request)s] %(message)s";
        };
      };
      handlers = {
        journal = {
          SYSLOG_IDENTIFIER = "synapse-${name}";
          class = "systemd.journal.JournalHandler";
          formatter = "journal_fmt";
        };
      };
      root = {
        handlers = [
          "journal"
        ];
        level = "WARNING";
      };
      version = 1;
    };

  proxyPass = {
    proxyPass = "http://$synapse_worker_upstream$request_uri";
    recommendedProxySettings = true;
    extraConfig = ''
      client_max_body_size 50M;
      proxy_http_version 1.1;
    '';
  };
  cfg = config.server.synapse;
in
{
  options.server.synapse.enable = lib.mkEnableOption "Synapse";

  config = lib.mkIf cfg.enable {
    impermanence.directories = [ config.services.matrix-synapse.dataDir ];

    server.turn.enable = true;

    server.matrix-rtc = {
      enable = true;
      homeservers = [ config.domain ];
    };

    services.matrix-synapse = {
      enable = true;
      configureRedisLocally = true;
      workers = {
        "federation_sender" = {
          worker_log_config = workerLogConfig "federation-sender";
        };
        "events_persister" = {
          worker_log_config = workerLogConfig "events-persister";
          worker_listeners = [
            {
              type = "http";
              bind_addresses = [ "::1" ];
              port = 9111;
              resources = [
                {
                  names = [ "replication" ];
                }
              ];
            }
          ];
        };
        "receipts_writer" = {
          worker_log_config = workerLogConfig "receipts-writer";
          worker_listeners = [
            {
              type = "http";
              bind_addresses = [ "::1" ];
              port = 9112;
              resources = [
                {
                  names = [ "replication" ];
                }
              ];
            }
            {
              type = "http";
              bind_addresses = [ "::1" ];
              tls = false;
              port = 8112;
              x_forwarded = true;
              resources = [
                {
                  names = [ "client" ];
                }
              ];
            }
          ];
        };
      };
      settings = {
        server_name = config.domain;
        public_baseurl = "https://${matrixDomain}";
        listeners = [
          {
            port = 8008;
            bind_addresses = [
              "::1"
            ];
            type = "http";
            tls = false;
            x_forwarded = true;
            resources = [
              {
                names = [
                  "client"
                  "federation"
                ];
                compress = true;
              }
            ];
          }
          {
            port = 9093;
            bind_addresses = [
              "::1"
            ];
            tls = false;
            type = "http";
            resources = [
              {
                names = [ "replication" ];
              }
            ];
          }
        ];

        instance_map = {
          main = {
            host = "::1";
            port = 9093;
          };
          "events_persister" = {
            host = "::1";
            port = 9111;
          };
          "receipts_writer" = {
            host = "::1";
            port = 9112;
          };
        };
        stream_writers = {
          events = [ "events_persister" ];
          receipts = "receipts_writer";
          typing = "receipts_writer";
        };
        federation_sender_instances = [
          "federation_sender"
        ];
        federation = {
          client_timeout = "300s";
        };
        presence = {
          enabled = true;
        };
        turn_uris = [
          "turn:${config.server.turn.realm}:3478?transport=udp"
          "turn:${config.server.turn.realm}:3478?transport=tcp"
        ];
        turn_shared_secret_path = config.server.turn.secretFile;
        turn_user_lifetime = "1h";
        turn_allow_guests = true;
        experimental_features = {
          msc3266_enabled = true;
          msc4222_enabled = true;
        };
        media_retention = {
          local_media_lifetime = "30d";
          remote_media_lifetime = "7d";
        };
        max_event_delay_duration = "24h";
        rc_message = {
          per_second = 0.5;
          burst_count = 30;
        };
        rc_delayed_event_mgmt = {
          per_second = 1;
          burst_count = 20;
        };
        registration_requires_token = true;
        enable_registration = true;
        log_config = (pkgs.formats.yaml { }).generate "log_config" {
          disable_existing_loggers = false;
          formatters = {
            journal_fmt = {
              format = "%(name)s: [%(request)s] %(message)s";
            };
          };
          handlers = {
            journal = {
              SYSLOG_IDENTIFIER = "synapse";
              class = "systemd.journal.JournalHandler";
              formatter = "journal_fmt";
            };
          };
          root = {
            handlers = [
              "journal"
            ];
            level = "WARNING";
          };
          version = 1;
        };
      };
    };

    services.synapse-auto-compressor.enable = true;

    services.nginx = {
      upstreams = {
        "matrix-synapse".servers = {
          "[::1]:8008" = { };
        };
        "matrix-receipts".servers = {
          "[::1]:8112" = { };
        };
      };
      commonHttpConfig = ''
        map $uri $synapse_worker_upstream {
          default matrix-synapse;
          ~^/_matrix/client/(r0|v3|unstable)/rooms/.*/receipt matrix-receipts;
          ~^/_matrix/client/(r0|v3|unstable)/rooms/.*/read_markers matrix-receipts;
          ~^/_matrix/client/(api/v1|r0|v3|unstable)/rooms/.*/typing matrix-receipts;
        }
      '';
      mapHashBucketSize = 128;
      virtualHosts.${config.domain} = {
        locations."= /.well-known/matrix/server".extraConfig = mkWellKnown serverConfig;
        locations."= /.well-known/matrix/client".extraConfig = mkWellKnown clientConfig;
        #for some reason clients insist on not using the subdomain
        locations."~ ^(/_matrix|/_synapse/client)" = proxyPass;
      };
      virtualHosts.${matrixDomain} = {
        enableACME = true;
        forceSSL = true;
        listen = lib.lists.flatten (
          map
            (addr: [
              {
                inherit addr;
                port = 8448;
                ssl = true;
              }
              #clients should access via normal https
              {
                inherit addr;
                port = 443;
                ssl = true;
              }
              #for redirects
              {
                inherit addr;
                port = 80;
                ssl = false;
              }
            ])
            [
              "0.0.0.0"
              "[::0]"
            ]
        );
        locations = {
          "~ ^(/_matrix|/_synapse/client)" = proxyPass;
        };

        extraConfig = ''
          access_log /var/log/nginx/matrix_access.log;
          error_log /var/log/nginx/matrix_error.log;
        '';

      };
    };

    users.users."matrix-synapse".extraGroups = [ "keys" ];

    networking.firewall.allowedTCPPorts = [
      port
    ];
  };
}

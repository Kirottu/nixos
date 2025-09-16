{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  port = 8448;
  matrixDomain = "matrix.${config.domain}";
  url = "https://${matrixDomain}";
  clientConfig."m.homeserver".base_url = url;
  serverConfig."m.server" = "${matrixDomain}:${builtins.toString port}";
  mkWellKnown = data: ''
    default_type application/json;
    add_header Access-Control-Allow-Origin *;
    return 200 '${builtins.toJSON data}';
  '';
  certDir = config.security.acme.certs.${config.domain}.directory;
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
        level = "INFO";
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

  mkMetrics = port: {
    inherit port;
    type = "metrics";
    tls = false;
    resources = [ ];
    bind_addresses = [
      "127.0.0.1"
    ];
  };
in
{
  options.synapse.enable = lib.mkEnableOption "Synapse";

  config = lib.mkIf config.synapse.enable {
    impermanence.directories = [ "/var/lib/matrix-synapse" ];

    services.matrix-synapse = {
      enable = true;
      configureRedisLocally = true;
      workers = {
        "federation_sender" = {
          worker_log_config = workerLogConfig "federation-sender";
          worker_listeners = lib.optional config.grafana.enable (mkMetrics 9001);
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

          ]
          ++ lib.optional config.grafana.enable (mkMetrics 9002);
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
          ]
          ++ lib.optional config.grafana.enable (mkMetrics 9003);
        };
      };
      settings = {
        server_name = config.domain;
        public_baseurl = "https://${config.domain}";
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
        ]
        ++ lib.optional config.grafana.enable (mkMetrics 9000);
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
          enabled = false;
        };
        turn_uris = [
          "turn:${matrixDomain}:3478?transport=udp"
          "turn:${matrixDomain}:3478?transport=tcp"
        ];
        turn_shared_secret = config.services.coturn.static-auth-secret;
        turn_user_lifetime = "1h";
        turn_allow_guests = true;
        enable_metrics = config.grafana.enable;
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
            level = "INFO";
          };
          version = 1;
        };
      };
    };

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
        #for some reason clients insist on not using the sub domain
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
        locations."~ ^(/_matrix|/_synapse/client)" = proxyPass;

        extraConfig = ''
          access_log /var/log/nginx/matrix_access.log;
          error_log /var/log/nginx/matrix_error.log;
        '';

      };
    };

    services.coturn = {
      enable = true;
      no-cli = true;
      no-tcp-relay = true;
      min-port = 49000;
      max-port = 50000;
      use-auth-secret = true;
      static-auth-secret = inputs.private.secrets.matrix.turn;
      realm = matrixDomain;
      cert = "${certDir}/full.pem";
      pkey = "${certDir}/key.pem";
      extraConfig = ''
        # ban private IP ranges
        no-multicast-peers
        denied-peer-ip=0.0.0.0-0.255.255.255
        denied-peer-ip=10.0.0.0-10.255.255.255
        denied-peer-ip=100.64.0.0-100.127.255.255
        denied-peer-ip=127.0.0.0-127.255.255.255
        denied-peer-ip=169.254.0.0-169.254.255.255
        denied-peer-ip=172.16.0.0-172.31.255.255
        denied-peer-ip=192.0.0.0-192.0.0.255
        denied-peer-ip=192.0.2.0-192.0.2.255
        denied-peer-ip=192.88.99.0-192.88.99.255
        denied-peer-ip=192.168.0.0-192.168.255.255
        denied-peer-ip=198.18.0.0-198.19.255.255
        denied-peer-ip=198.51.100.0-198.51.100.255
        denied-peer-ip=203.0.113.0-203.0.113.255
        denied-peer-ip=240.0.0.0-255.255.255.255
        denied-peer-ip=::1
        denied-peer-ip=64:ff9b::-64:ff9b::ffff:ffff
        denied-peer-ip=::ffff:0.0.0.0-::ffff:255.255.255.255
        denied-peer-ip=100::-100::ffff:ffff:ffff:ffff
        denied-peer-ip=2001::-2001:1ff:ffff:ffff:ffff:ffff:ffff:ffff
        denied-peer-ip=2002::-2002:ffff:ffff:ffff:ffff:ffff:ffff:ffff
        denied-peer-ip=fc00::-fdff:ffff:ffff:ffff:ffff:ffff:ffff:ffff
        denied-peer-ip=fe80::-febf:ffff:ffff:ffff:ffff:ffff:ffff:ffff
      '';
    };

    users.users."turnserver".extraGroups = [ "nginx" ];

    networking.firewall.allowedUDPPortRanges = [
      {
        from = config.services.coturn.min-port;
        to = config.services.coturn.max-port;
      }
    ];

    security.acme.certs.${config.domain}.postRun =
      "systemctl restart matrix-synapse.service; systemctl restart coturn.service";
    networking.firewall.allowedTCPPorts = [
      port
      3478
      5349
    ];
    networking.firewall.allowedUDPPorts = [
      3478
      5349
    ];
  };
}

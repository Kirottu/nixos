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
    "m.identity_server".base_url = "https://vector.im";
    "org.matrix.msc3575.proxy"."url" = url;
    "org.matrix.msc4143.rtc_foci" = [
      {
        "type" = "livekit";
        "livekit_service_url" = "https://${matrixDomain}/livekit/jwt";
      }
    ];
  };
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

  livekitKeyFile = "/run/livekit.key";
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
          enabled = false;
        };
        turn_uris = [
          "turn:${matrixDomain}:3478?transport=udp"
          "turn:${matrixDomain}:3478?transport=tcp"
        ];
        turn_shared_secret = config.services.coturn.static-auth-secret;
        turn_user_lifetime = "1h";
        turn_allow_guests = true;
        experimental_features = {
          msc3266_enabled = true;
          msc4222_enabled = true;
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
      virtualHosts."_" = {
        listen = [
          {
            addr = "127.0.0.1";
            port = 800;
            ssl = false;
          }
        ];
        locations."/".root = toString pkgs.synapse-admin;
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
          "^~ /livekit/jwt/" = {
            priority = 400;
            proxyPass = "http://[::1]:${toString config.services.lk-jwt-service.port}/";
          };
          "^~ /livekit/sfu/" = {
            extraConfig = ''
              proxy_send_timeout 120;
              proxy_read_timeout 120;
              proxy_buffering off;

              proxy_set_header Accept-Encoding gzip;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "upgrade";
            '';

            priority = 400;
            proxyPass = "http://[::1]:${toString config.services.livekit.settings.port}/";
            proxyWebsockets = true;
          };
        };

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

    services.livekit = {
      enable = true;
      openFirewall = true;
      settings = {
        rtc.use_external_ip = true;
      };
      settings.room.auto_create = false;
      keyFile = livekitKeyFile;
    };
    services.lk-jwt-service = {
      enable = true;
      # can be on the same virtualHost as synapse
      livekitUrl = "wss://${matrixDomain}/livekit/sfu";
      keyFile = livekitKeyFile;
    };

    # generate the key when needed
    systemd.services.livekit-key = {
      before = [
        "lk-jwt-service.service"
        "livekit.service"
      ];
      wantedBy = [ "multi-user.target" ];
      path = with pkgs; [
        livekit
        coreutils
        gawk
      ];
      script = ''
        echo "Key missing, generating key"
        echo "lk-jwt-service: $(livekit-server generate-keys | tail -1 | awk '{print $3}')" > "${livekitKeyFile}"
      '';
      serviceConfig.Type = "oneshot";
      unitConfig.ConditionPathExists = "!${livekitKeyFile}";
    };

    # restrict access to livekit room creation to a homeserver
    systemd.services.lk-jwt-service.environment.LIVEKIT_FULL_ACCESS_HOMESERVERS = config.domain;

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

{
  config,
  lib,
  ...
}:
let
  domain = "grafana.${config.domain}";
  mkScraper = name: {
    job_name = name;
    static_configs = [
      {
        targets = [ "localhost:${toString config.services.prometheus.exporters.${name}.port}" ];
      }
    ];
  };
in
{
  options.grafana.enable = lib.mkEnableOption "Grafana";

  config = lib.mkIf config.grafana.enable {
    impermanence.directories = [
      "/var/lib/grafana"
    ];

    services.prometheus = {
      enable = true;
      globalConfig = {
        scrape_interval = "15s";
      };
      exporters = {
        nginx = {
          enable = true;
          sslVerify = false;
        };
        unbound = {
          enable = true;
          unbound = {
            host = "unix://${config.services.unbound.settings.remote-control.control-interface}";
            certificate = null;
            ca = null;
          };
        };
        node = {
          enable = true;
          enabledCollectors = [ "systemd" ];
        };
      };
      scrapeConfigs = [
        (mkScraper "node")
        (mkScraper "nginx")
        (mkScraper "unbound")
      ]
      ++ (lib.optional config.synapse.enable {
        job_name = "synapse";
        metrics_path = "/_synapse/metrics";
        static_configs = [
          {
            targets = [ "localhost:9000" ];
            labels = {
              instance = "kirottu.com";
              job = "master";
              index = "1";
            };
          }
          {
            targets = [ "localhost:9001" ];
            labels = {
              instance = "kirottu.com";
              job = "federation-sender";
              index = "1";
            };
          }
          {
            targets = [ "localhost:9002" ];
            labels = {
              instance = "kirottu.com";
              job = "events-persister";
              index = "1";
            };
          }
          {
            targets = [ "localhost:9003" ];
            labels = {
              instance = "kirottu.com";
              job = "receipts-writer";
              index = "1";
            };
          }
        ];
      });
    };

    services.grafana = {
      enable = true;
      settings = {
        server = {
          inherit domain;
          http_port = 3000;
          http_addr = "127.0.0.1";
        };
      };
      provision = {
        enable = true;
        datasources.settings.datasources = [
          # Provisioning a built-in data source
          {
            name = "Prometheus";
            type = "prometheus";
            url = "http://${config.services.prometheus.listenAddress}:${toString config.services.prometheus.port}";
            isDefault = true;
            editable = false;
          }
        ];
      };
    };

    services.nginx.statusPage = true;

    services.nginx.virtualHosts.${domain} = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}";
        proxyWebsockets = true;
        recommendedProxySettings = true;
      };
    };
  };
}

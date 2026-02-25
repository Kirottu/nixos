{ config, ... }:
{
  config = {
    sops.secrets."ddclient/password" = {
      sopsFile = ../../secrets/overwatch-of-harold.yaml;
    };

    services.ddclient = {
      enable = true;
      interval = "5min";
      protocol = "namecheap";
      username = config.domain;
      passwordFile = config.sops.secrets."ddclient/password".path;
      domains = [
        "nc.${config.domain}"
      ];
    };
  };
}

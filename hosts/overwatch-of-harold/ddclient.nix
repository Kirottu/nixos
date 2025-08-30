{ config, ... }:
{
  config = {
    sops.secrets."ddclient/password" = {
      sopsFile = ../../secrets/server.yaml;
    };

    services.ddclient = {
      enable = true;
      interval = "1min";
      protocol = "namecheap";
      username = config.domain;
      passwordFile = config.sops.secrets."ddclient/password".path;
      domains = [
        "*.${config.domain}"
        "@.${config.domain}"
      ];
    };
  };
}

{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
{
  imports = [
    ./hardware-config.nix
  ];

  config = {
    devices.class = "server";
    domain = "kirottu.com";

    sops.secrets =
      let
        spreed = {
          sopsFile = ../../secrets/hell-of-harold.yaml;
          owner = config.services.nextcloud-spreed-signaling.user;
        };
        stalwart = {
          sopsFile = ../../secrets/hell-of-harold.yaml;
          owner = "stalwart-mail";
        };
        shared-mail = {
          sopsFile = ../../secrets/mail.yaml;
          group = "keys";
          mode = "0440";
        };
      in
      {
        "turn/secret" = {
          sopsFile = ../../secrets/hell-of-harold.yaml;
          group = "keys";
          mode = "0440";
        };
        "spreed-hpb/hashkey" = spreed;
        "spreed-hpb/blockkey" = spreed;
        "spreed-hpb/internalsecret" = spreed;
        "spreed-hpb/nextcloudsecret" = spreed;
        "stalwart/admin-pass" = stalwart;
        "stalwart/db-pass" = stalwart;
        "mail/noreply" = shared-mail;
        "mail/postmaster" = stalwart;
        "synapse/client-secret" = {
          sopsFile = ../../secrets/hell-of-harold.yaml;
          owner = "matrix-synapse";
        };
        "webmail/client-secret" = {
          sopsFile = ../../secrets/hell-of-harold.yaml;
          owner = "rouncube";
        };
      };
    server = {
      spreed-hpb = {
        enable = true;
        hashkeyFile = config.sops.secrets."spreed-hpb/hashkey".path;
        blockkeyFile = config.sops.secrets."spreed-hpb/blockkey".path;
        nextcloudsecretFile = config.sops.secrets."spreed-hpb/nextcloudsecret".path;
        internalsecretFile = config.sops.secrets."spreed-hpb/internalsecret".path;
      };
      turn = {
        secretFile = config.sops.secrets."turn/secret".path;
      };
      mumble = {
        enable = true;
        # musicbot.enable = true;
      };
      synapse = {
        enable = true;
        clientSecretFile = config.sops.secrets."synapse/client-secret".path;
      };
      keycloak.enable = true;
      stalwart = {
        enable = true;
        adminPassFile = config.sops.secrets."stalwart/admin-pass".path;
        dbPassFile = config.sops.secrets."stalwart/db-pass".path;
        webmailSecret = "webmail/client-secret";
        # principals = [
        #   {
        #     class = "individual";
        #     name = "Noreply";
        #     secret = "%{file:${config.sops.secrets."mail/noreply".path}}%";
        #     email = [ "noreply@${config.domain}" ];
        #   }
        #   {
        #     class = "individual";
        #     name = "Postmaster";
        #     secret = "%{file:${config.sops.secrets."mail/postmaster".path}}%";
        #     email = [ "postmaster@${config.domain}" ];
        #   }
        # ];
      };
    };

    impermanence = {
      enable = true;
      directories = [
        "/var/lib/postgresql"
      ];
    };

    systemd.network.enable = true;
    networking.useNetworkd = true;
    systemd.network.networks."10-wan" = {
      networkConfig.DHCP = "no";
      matchConfig.Name = "enp1*";
      address = [
        "89.167.75.62/32"
        "2a01:4f9:c014:5536::/64"
      ];
      routes = [
        {
          Gateway = "172.31.1.1";
          GatewayOnLink = true;
        }
        { Gateway = "fe80::1"; }
      ];
    };

    services.postgresql = {
      enable = true;
    };

    services.nginx = {
      virtualHosts."${config.domain}" = {
        enableACME = true;
        forceSSL = true;
        locations."/".root = inputs.personal-site;
      };
    };

    networking.hostName = "hell-of-harold";

    boot.loader.grub.enable = true;
    boot.loader.grub.device = "/dev/sda";

    hm.programs.helix.enable = lib.mkForce false;
    environment.systemPackages = [ pkgs.neovim ];

    system.stateVersion = "25.11";
    hm.home.stateVersion = "25.11";
  };
}

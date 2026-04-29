{
  config,
  pkgs,
  inputs,
  lib,
  myPkgs,
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
        shared = {
          sopsFile = ../../secrets/shared.yaml;
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
        "mail/noreply" = shared;
        "mail/postmaster" = stalwart;
        "oidc/synapse" = shared;
        "oidc/webmail" = shared;
        "oidc/fairemail" = shared;
        "oidc/nextcloud" = shared;
        "oidc/vaultwarden" = shared;
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
        clientSecretFile = config.sops.secrets."oidc/synapse".path;
      };
      keycloak.enable = true;
      stalwart = {
        enable = true;
        adminPassFile = config.sops.secrets."stalwart/admin-pass".path;
        dbPassFile = config.sops.secrets."stalwart/db-pass".path;
        webmailSecretPath = config.sops.secrets."oidc/webmail".path;
        automation.principals = [
          {
            class = "individual";
            name = "noreply";
            secret = "%{file:${config.sops.secrets."mail/noreply".path}}%";
            email = [ "noreply@${config.domain}" ];
          }
        ];
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

    services.keycloak = {
      vault = {
        main_smtpPass = config.sops.secrets."mail/noreply".path;
        main_nextcloud = config.sops.secrets."oidc/nextcloud".path;
        main_synapse = config.sops.secrets."oidc/synapse".path;
        main_vaultwarden = config.sops.secrets."oidc/vaultwarden".path;
        main_fairemail = config.sops.secrets."oidc/fairemail".path;
        main_webmail = config.sops.secrets."oidc/webmail".path;
      };
      package = pkgs.callPackage myPkgs.keycloak { };
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

    system.stateVersion = "25.11";
    hm.home.stateVersion = "25.11";
  };
}

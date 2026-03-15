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
    ./synapse.nix
    ../../modules
  ];

  config = {
    devices.class = "server";
    domain = "kirottu.com";

    synapse.enable = true;

    sops.secrets =
      let
        block = {
          sopsFile = ../../secrets/hell-of-harold.yaml;
          owner = config.services.nextcloud-spreed-signaling.user;
        };
      in
      {
        "turn/secret" = {
          sopsFile = ../../secrets/hell-of-harold.yaml;
          group = "keys";
          mode = "0440";
        };
        "spreed-hpb/hashkey" = block;
        "spreed-hpb/blockkey" = block;
        "spreed-hpb/internalsecret" = block;
        "spreed-hpb/nextcloudsecret" = block;
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
        botamusique.enable = true;
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

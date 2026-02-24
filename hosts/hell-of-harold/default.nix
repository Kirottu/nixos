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

    server.turn = {
      secret = inputs.private.secrets.matrix.secret;
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
      enable = true;
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

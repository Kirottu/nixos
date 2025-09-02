{
  config,
  pkgs,
  lib,
  ...
}:
{
  options = {
    domain = lib.mkOption {
      type = lib.types.str;
    };
  };

  imports = [
    ./hardware-configuration.nix
    ../../modules
    ./nextcloud.nix
    ./synapse.nix
    ./nginx.nix
    ./ddclient.nix
    ./vaultwarden.nix
  ];

  config = {
    devices.class = "server";
    domain = "kirottu.com";
    networking = {
      hostName = "overwatch-of-harold";
      nameservers = [
        "1.1.1.1"
        "8.8.8.8"
      ];
      dhcpcd.extraConfig = "nohook resolv.conf";
    };

    services.resolved = {
      enable = true;
      dnsovertls = "true";
      fallbackDns = config.networking.nameservers;
    };

    mainUser = {
      userName = "harold";
      extraOptions = {
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILmnknd6bSmWrhpr+I5j3R5fou8gu8zY4V3oc+gTfVuH kirottu@church-of-harold"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAus3fLTD2awXq7p9IVzKdhxV0k0VBlIas9L3KxBHmWb kirottu@missionary-of-harold"
        ];
      };
    };

    cli.fish.enable = true;

    impermanence = {
      enable = true;
      directories = [
        "/var/lib/postgresql"
        "/var/lib/fail2ban"
        "/etc/ssh"
      ];
      userDirectories = [
        "Flake"
      ];
    };

    #prevent OOM on cache fail
    systemd.services.nix-daemon = {
      serviceConfig = {
        MemoryHigh = "1G";
        MemoryMax = "2.5G";
      };
      environment.TMPDIR = "/nix/tmp";
    };
    systemd.tmpfiles.rules = [
      "d /nix/tmp 1777 root root 1d"
      "d /var/log/nginx 1640 nginx nginx 1d"
    ];

    services.openssh = {
      enable = true;
      ports = [ 22 ];
      settings = {
        AllowUsers = [ config.mainUser.userName ];
        AuthenticationMethods = "publickey,password";
        PasswordAuthentication = true;
        PermitRootLogin = "no";
      };
    };

    services.fail2ban = {
      # enable = true;
    };

    networking.firewall = {
      enable = false;
      allowedTCPPorts = [
        22
        80
        443
      ];
    };

    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_17;
    };

    hm.programs.git.signing.key = "26982691F464B6026D552AD16A022A372FDFBF4E";

    services.btrfs.autoScrub.enable = true;

    # Fix for niri-flake compiling niri if that is set at all
    hm.programs.niri.settings = lib.mkForce null;

    system.stateVersion = "25.05";
    hm.home.stateVersion = "25.05";
  };
}

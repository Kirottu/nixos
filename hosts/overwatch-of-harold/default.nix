{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules
    ./nextcloud.nix
    ./synapse.nix
    ./nginx.nix
  ];

  config = {
    devices.class = "server";
    networking.hostName = "overwatch-of-harold";

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

    security.acme = {
      acceptTerms = true;
      defaults.email = "arnovaara@kirottu.com";
      certs =
        let
          sub = t: s: "${s}.${t}";
        in
        {
          "kirottu.com" = {
            webroot = "/var/lib/acme/acme-challenge/";
            extraDomainNames = builtins.map (sub "kirottu.com") [
              "nc"
              "calendar"
              "matrix"
            ];
          };
        };
    };
    impermanence = {
      enable = true;
      directories = [
        "/var/lib/acme"
        "/var/lib/postgresql"
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
      enable = true;
    };

    networking.firewall = {
      enable = true;
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

    # Fix for niri-flake compiling niri if that is set at all
    hm.programs.niri.settings = lib.mkForce null;

    system.stateVersion = "25.05";
    hm.home.stateVersion = "25.05";
  };
}

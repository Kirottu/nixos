{
  lib,
  config,
  ...
}:
{
  options = {
    domain = lib.mkOption {
      type = lib.types.str;
    };
  };

  config = lib.mkIf (config.devices.class == "server") {
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

    impermanence.directories = [
      "/var/lib/fail2ban"
      "/etc/ssh"
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
  };
}

{
  config,
  ...
}:
{
  imports = [
    ./nextcloud.nix
    ./synapse.nix
  ];

  config = {
    device.class = "server";

    sops.secrets."server/pass-hash" = {
      neededForUsers = true;
      sopsFile = ../../secrets/users.yaml;
    };
    mainUser = {
      userName = "harold";
      hashedPasswordFile = config.sops.secrets."server/pass-hash".path;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILmnknd6bSmWrhpr+I5j3R5fou8gu8zY4V3oc+gTfVuH kirottu@church-of-harold"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAus3fLTD2awXq7p9IVzKdhxV0k0VBlIas9L3KxBHmWb kirottu@missionary-of-harold"
      ];
    };

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
      directories = [ "/var/lib/acme" ];
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
  };
}

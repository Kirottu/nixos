{
  lib,
  config,
  pkgs,
  ...
}:
{
  options = {
    domain = lib.mkOption {
      type = lib.types.str;
      default = "";
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

    security.acme = {
      acceptTerms = true;
      defaults.email = "arnovaara@kirottu.com";
    };

    server.borg.enable = true;

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

    services.logrotate.checkConfig = false;

    system.autoUpgrade = {
      enable = true;
      flake = "github:Kirottu/nixos";
      randomizedDelaySec = "30min";
      dates = "Mon,Wed,Fri *-*-* 03:00:00";
      allowReboot = true;
      rebootWindow = {
        lower = "02:00";
        upper = "04:00";
      };
    };

    systemd.services.nixos-upgrade.environment = {
      GIT_SSH_COMMAND = "ssh -i /etc/ssh/ssh_host_ed25519_key";
    };

    services.openssh = {
      enable = true;
      ports = [ 22 ];
      settings = {
        AllowUsers = [ config.mainUser.userName ];
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    programs.ssh.knownHostsFiles = [
      (pkgs.writeText "github.keys" ''
        github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
        github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
        github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
      '')
    ];

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

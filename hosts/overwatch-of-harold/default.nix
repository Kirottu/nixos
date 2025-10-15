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
    ./grafana.nix
    ./mail.nix
  ];

  config = {
    devices.class = "server";
    domain = "kirottu.com";

    synapse.enable = true;
    grafana.enable = true;
    # mail.enable = true;

    networking = {
      hostName = "overwatch-of-harold";
      nameservers = [
        "127.0.0.1"
      ];
      dhcpcd.extraConfig = "nohook resolv.conf";
    };

    services.unbound = {
      enable = true;
      settings = {
        remote-control = lib.mkIf config.grafana.enable {
          control-enable = true;
          control-interface = "/run/unbound/unbound.socket";
        };
        server = {
          interface = [ "0.0.0.0" ];
          prefetch = "yes";
          prefetch-key = "yes";
          num-threads = 2;
          msg-cache-slabs = 2;
          rrset-cache-slabs = 2;
          infra-cache-slabs = 2;
          key-cache-slabs = 2;
          serve-expired = "yes";
          cache-min-ttl = 600;
          serve-expired-client-timeout = 0;
          key-cache-size = "64m";
          rrset-cache-size = "64m";
          msg-cache-size = "32m";
          so-rcvbuf = "8m";
          so-sndbuf = "8m";
          outgoing-range = 8192;
          num-queries-per-thread = 4096;
        };
        forward-zone = [
          {
            name = ".";
            forward-addr = [
              "1.1.1.1@853#cloudflare-dns.com"
              "9.9.9.9#dns.quad9.net"
            ];
            forward-tls-upstream = true;
          }
        ];
      };
    };

    # services.resolved = {
    #   enable = true;
    #   dnsovertls = "true";
    #   fallbackDns = config.networking.nameservers;
    # };

    networking.useDHCP = true;

    # systemd.network = {
    #   enable = true;
    #   networks."10-wan" = {
    #     matchConfig.Name = "enp0s25";
    #     networkConfig = {
    #       DHCP = "ipv4";
    #       IPv6AcceptRA = true;
    #     };
    #     linkConfig.RequiredForOnline = "routable";
    #     routes = [
    #       {
    #         Gateway = "fe80::101";
    #       }
    #       {
    #         Gateway = "192.168.101.1";
    #       }
    #     ];
    #   };
    # };

    services.fireqos = {
      enable = true;
      config =
        let
          interface = "enp0s25";
          upSpeed = "20mbit";
          downSpeed = "80mbit";
        in
        ''
          interface ${interface} world-in input rate ${downSpeed}

          interface ${interface} world-out output rate ${upSpeed}
        '';
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

    hm.programs.git.signing.key = "26982691F464B6026D552AD16A022A372FDFBF4E";

    services.btrfs.autoScrub.enable = true;

    system.autoUpgrade = {
      enable = true;
      flake = "github:Kirottu/nixos";
      randomizedDelaySec = "45min";
      dates = "02:00";
      allowReboot = true;
      rebootWindow = {
        lower = "02:00";
        upper = "04:00";
      };
    };

    systemd.services.nixos-upgrade.environment = {
      GIT_SSH_COMMAND = "ssh -i /etc/ssh/ssh_host_ed25519_key";
    };

    systemd.timers.updateFlake = {
      enable = true;
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "1:30";
        Unit = "updateFlake.service";
      };
    };
    systemd.services.updateFlake = {
      enable = true;
      serviceConfig = {
        User = config.mainUser.userName;
        Type = "simple";
        ExecStart = lib.getExe (
          pkgs.writeShellApplication {
            name = "updateFlake";
            runtimeInputs = [
              pkgs.git
              pkgs.gnupg
              config.services.openssh.package
              config.nix.package
            ];
            text = ''
              cd "$(mktemp -d)"
              # GIT_SSH_COMMAND="ssh -i /etc/ssh/ssh_host_ed25519_key" git clone ssh://git@github.com/Kirottu/nixos
              git clone https://github.com/Kirottu/nixos
              cd nixos
              nix flake update
              git add flake.lock
              git commit -m "flake: update lock"
              git push
              cd ..
              rm -rf nixos
            '';
          }
        );
      };
    };

    # Fix for niri-flake compiling niri if that is set at all
    hm.programs.niri.settings = lib.mkForce null;

    system.stateVersion = "25.05";
    hm.home.stateVersion = "25.05";
  };
}

{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    (inputs.import-tree ../../modules)
  ];

  config = {
    devices.class = "server";
    domain = "kirottu.com";

    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    sops.secrets = {
      "ddclient/password" = {
        sopsFile = ../../secrets/overwatch-of-harold.yaml;
      };
      "vaultwarden/env".sopsFile = ../../secrets/overwatch-of-harold.yaml;
      "syncserver/secrets" = {
        sopsFile = ../../secrets/overwatch-of-harold.yaml;
      };
      "nextcloud/adminpass" = {
        sopsFile = ../../secrets/overwatch-of-harold.yaml;
      };
    };

    # synapse.enable = true;
    server = {
      syncserver = {
        enable = true;
        secrets = config.sops.secrets."syncserver/secrets".path;
      };
      nextcloud = {
        enable = true;
        monitoredServices = [ "nixos-upgrade" ];
        adminPass = config.sops.secrets."nextcloud/adminpass".path;
      };
      ddclient = {
        enable = true;
        passwordFile = config.sops.secrets."ddclient/password".path;
        domains = [
          config.server.nextcloud.domain
        ];
      };
      vaultwarden = {
        enable = true;
        secrets = config.sops.secrets."vaultwaden/env".path;
      };
    };
    # grafana.enable = true;
    # mail.enable = true;
    # cinny.enable = true;

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

    impermanence = {
      enable = true;
      directories = [
        "/var/lib/postgresql"
      ];
      userDirectories = [
        "Flake"
      ];
    };

    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_17;
    };

    hm.programs.git.signing.key = "26982691F464B6026D552AD16A022A372FDFBF4E";

    services.btrfs.autoScrub.enable = true;

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

    # Helix is failing currently
    # hm.programs.helix.enable = lib.mkForce false;
    # environment.systemPackages = [ pkgs.neovim ];

    system.stateVersion = "25.05";
    hm.home.stateVersion = "25.05";
  };
}

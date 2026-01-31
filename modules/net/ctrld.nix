{
  config,
  inputs,
  lib,
  ...
}:
let

  cfg = config.net.ctrld;
in
{
  options.net.ctrld = {
    enable = lib.mkEnableOption "CtrlD";
    upstream = lib.mkOption {
      type = with lib.types; nullOr nonEmptyStr;
    };
  };

  imports = [
    inputs.ctrld.nixosModules.ctrld
  ];

  config = lib.mkIf cfg.enable (
    let
      settings = {
        listener = {
          "0" = {
            ip = "127.0.0.1";
            port = 53;
          };
        };
        upstream = {
          "0" = {
            type = "doh";
            endpoint = if (cfg.upstream != null) then cfg.upstream else "https://freedns.controld.com/p2";
            timeout = 5000;
          };
          # "0" = {
          #   type = "doh";
          #   endpoint = "https://cloudflare-dns.com/dns-query";
          #   timeout = 5000;
          # };
        };
      };

    in
    {
      networking = {
        networkmanager.dns = lib.mkForce "none";
        nameservers = [
          "127.0.0.1"
          "::1"
        ];
      };
      services.ctrld = {
        enable = true;
        inherit settings;
      };
    }
  );
}

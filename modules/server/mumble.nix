{
  config,
  lib,
  ...
}:
let
  cfg = config.server.mumble;
in
{
  options.server.mumble = {
    enable = lib.mkEnableOption "Murmur for Mumble";
  };

  config = lib.mkIf cfg.enable {
    impermanence.directories = [ config.services.murmur.stateDir ];

    services.murmur =

      let
        certDir = config.security.acme.certs.${cfg.realm}.directory;
      in
      {
        enable = true;
        openFirewall = true;
        sslCert = "${certDir}/full.pem";
        sslKey = "${certDir}/key.pem";
        welcometext = "Epämäärämääräistä möminää ja suolaista paskapuhumista.";
      };

    users.users."murmur".extraGroups = [ "nginx" ];
  };
}

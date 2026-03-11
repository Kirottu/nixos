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
        certDir = config.security.acme.certs.${config.domain}.directory;
      in
      {
        enable = true;
        openFirewall = true;
        sslCert = "${certDir}/full.pem";
        sslKey = "${certDir}/key.pem";
        welcometext = "Epämäärämääräistä möminää ja suolaista paskapuhumista.";
      };

    security.acme.certs.${config.domain}.reloadServices = [ "murmur.service" ];

    users.users."murmur".extraGroups = [ "nginx" ];
  };
}

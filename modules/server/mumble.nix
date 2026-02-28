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

    services.murmur = {
      enable = true;
      openFirewall = true;
      welcometext = "Epämäärämääräistä möminää ja suolaista paskapuhumista.";
    };
  };
}

{
  config,
  lib,
  ...
}:
let
  cfg = config.server.spreed-hpb;
in
{
  options.server.spreed-hpb = {
    enable = lib.mkEnableOption "High performance backend for Nextcloud Talk";
  };

  config = lib.mkIf cfg.enable {
    server.turn.enable = true;

    services.nextcloud-spreed-signaling = {
      configureNginx = true;
      settings = {
        turn = {
          servers = [
            "turn:${config.server.turn.realm}:3478?transport=udp"
            "turn:${config.server.turn.realm}:3478?transport=tcp"
          ];
        };
      };
      backends.nextcloud = {
        urls = [
          "https://nc.kirottu.com"
        ];
      };
    };
  };
}

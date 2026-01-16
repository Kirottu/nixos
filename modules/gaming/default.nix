{
  lib,
  config,
  ...
}:
{
  imports = [
    ./vr
    ./applications.nix
    ./fake-frames.nix
  ];

  options.gaming.enable = lib.mkEnableOption "Gaming";

  config = lib.mkIf config.gaming.enable {
    # Various persistent directories needed by games
    impermanence.userDirectories = [
      "Games"
      ".factorio"
    ];
    programs.gamemode.enable = true;
  };
}

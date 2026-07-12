{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.gaming.enable = lib.mkEnableOption "Gaming";

  config = lib.mkIf config.gaming.enable {
    # Various persistent directories needed by games
    impermanence.userDirectories = [
      "Games"
      ".factorio"
    ];
    programs.gamemode.enable = true;
    boot.kernelModules = [ "ntsync" ];

    environment.systemPackages = [
      (pkgs.writeShellApplication {
        name = "swapless";
        excludeShellChecks = [
          "SC2068"
        ];
        text = ''
          ${lib.getExe' pkgs.systemd "systemd-run"} --user -p MemorySwapMax=0 -p MemoryZSwapMax=0 --pipe --send-sighup --wait $@
        '';
      })
    ];
  };
}

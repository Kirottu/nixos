{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.net.networkmanager.enable = lib.mkEnableOption "NetworkManager";

  config = lib.mkIf config.net.networkmanager.enable {
    networking.networkmanager = {
      enable = true;
      plugins = with pkgs; [
        networkmanager-openconnect
      ];
    };
    hm.services.network-manager-applet.enable = true;
    impermanence.directories = [ "/etc/NetworkManager/system-connections" ];
    mainUser.extraGroups = [ "networkmanager" ];
  };
}

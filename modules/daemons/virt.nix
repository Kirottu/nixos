{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.virt;
in
{
  options.virt = {
    podman.enable = lib.mkEnableOption "Podman";
    distrobox.enable = lib.mkEnableOption "Distrobox";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.podman.enable {
      virtualisation.podman = {
        enable = true;
        dockerCompat = true;
      };

      impermanence = {
        userDirectories = [ ".local/share/containers" ];
        directories = [ "/var/lib/containers" ];
      };
    })
    (lib.mkIf cfg.distrobox.enable {
      virt.podman.enable = true;
      environment.systemPackages = [ pkgs.distrobox ];
    })
  ];
}

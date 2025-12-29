{ lib, ... }:
{
  options.graphical.enable = lib.mkEnableOption "Graphical environment";

  imports = [
    ./eww
    ./niri
    ./waybar
    ./webapps
    ./anyrun.nix
    ./applications.nix
    ./browsers.nix
    ./screen-locking.nix
    ./instant-replay.nix
    ./tv.nix
    ./yand.nix
  ];
}

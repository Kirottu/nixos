{ pkgs, ... }:
{
  config = {
    hm.programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    impermanence.userDirectories = [
      ".cargo"
      ".local/share/direnv"
    ];
  };
}

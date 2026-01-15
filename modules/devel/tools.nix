{ pkgs, ... }:
{
  config = {
    hm.programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    environment.systemPackages = [
      pkgs.devenv
    ];

    nix.settings = {
      substituters = [ "https://devenv.cachix.org" ];
      trusted-public-keys = [ "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=" ];
    };

    impermanence.userDirectories = [
      ".cargo"
      ".gradle"
      ".local/share/direnv"
    ];
  };
}

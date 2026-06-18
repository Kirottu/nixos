{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.devices.graphical {
    hm.programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    environment.systemPackages = [
      pkgs.devenv
    ];

    hm.programs.zed-editor = {
      enable = true;
      package = pkgs.zed-editor-fhs;
    };

    nix.settings = {
      substituters = [ "https://devenv.cachix.org" ];
      trusted-public-keys = [ "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=" ];
    };

    impermanence.userDirectories = [
      ".cargo"
      ".gradle"
      # I hate java development
      ".jdks"
      ".java"
      ".local/share/direnv"
    ];
  };
}

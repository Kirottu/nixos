{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.cli.fish.enable = lib.mkEnableOption "Fish login shell";

  config = lib.mkIf config.cli.fish.enable {
    programs.fish.enable = true;
    mainUser.shell = pkgs.fish;

    impermanence.userDirectories = [
      ".local/share/fish"
    ];

    # Takes really long to eval during build
    documentation.man.generateCaches = false;

    hm.programs.fish =
      let
        flake = "${config.hm.home.homeDirectory}/Projects/nixos";
      in
      {
        enable = true;
        shellAliases = {
          nd = "nix develop -c fish";
          nhs = "nh os switch ${flake} -a";
          nhb = "nh os boot ${flake} -a";
          nhus = "nh os switch ${flake} -u -a";
          nhub = "nh os boot ${flake} -u -a";
        };
        interactiveShellInit = lib.concatStrings (
          lib.flatten [
            ''
              set fish_greeting
            ''

            (lib.optional config.cli.getty.dm.enable ''
              if status is-login
                if test -z $WAYLAND_DISPLAY && test -z $DISPLAY && test $XDG_VTNR = 1
                  exec ${config.cli.getty.dm.command}
                end
              end'')
          ]
        );
      };
  };
}

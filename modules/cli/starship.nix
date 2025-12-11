{ lib, config, ... }:
{
  options.cli.starship.enable = lib.mkEnableOption "Starship prompt";

  config = lib.mkIf config.cli.starship.enable {
    hm.programs.starship = {
      enable = true;
      enableFishIntegration = true;
      settings =
        let
          middle_modules = [
            "c"
            "cmake"
            "cobol"
            "daml"
            "dart"
            "deno"
            "dotnet"
            "elixir"
            "elm"
            "erlang"
            "fennel"
            "gleam"
            "golang"
            "guix_shell"
            "haskell"
            "haxe"
            "helm"
            "java"
            "julia"
            "kotlin"
            "gradle"
            "lua"
            "nim"
            "nodejs"
            "ocaml"
            "opa"
            "perl"
            "php"
            "pulumi"
            "purescript"
            "python"
            "quarto"
            "raku"
            "rlang"
            "red"
            "ruby"
            "rust"
            "scala"
            "solidity"
            "swift"
            "terraform"
            "typst"
            "vlang"
            "vagrant"
            "zig"
          ];
        in
        with config.theming.themeAttrs;
        lib.mergeAttrs
          {
            format = lib.concatStrings [
              "[](${l1})"
              "$directory"
              "[](fg:${l1} bg:${l2})"
              "$git_branch$git_status"
              "[](fg:${l2} bg:${l3})"
              "$package"
              (lib.concatStrings (builtins.map (mod: "$" + mod) middle_modules))
              "[](fg:${l3} bg:${l4})"
              "$nix_shell$time"
              "[](fg:${l4})\n$character"
            ];

            directory = {
              style = "bg:${l1}";
              format = "[ $path ]($style)";
            };

            git_branch = {
              style = "bg:${l2}";
              format = "[ $symbol$branch(:$remote_branch) ]($style)";
            };
            git_status = {
              style = "bg:${l2}";
              format = "([\\[$all_status$ahead_behind\\] ]($style))";
            };

            package = {
              format = "[ $symbol$version ]($style)";
              style = "bg:${l3}";
            };

            nix_shell = {
              style = "bg:${l4}";
              format = "[ $symbol$state( \\($name\\)) ]($style)";
            };

          }
          (
            builtins.listToAttrs (
              builtins.map (mod: {
                name = mod;
                value = {
                  style = "bg:${l3}";
                  format = "[ via $symbol($version) ]($style)";
                };
              }) middle_modules
            )
          );
    };
  };
}

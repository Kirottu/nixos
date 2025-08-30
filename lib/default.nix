{
  inputs,
  lib,
  ...
}:
inputs.nixpkgs.lib.extend (
  final: prev: {
    utils = {
      # Helper function to add an app to the system with possible extra options and
      # persisted directories
      mkApp =
        {
          package,
          directories ? [ ],
          files ? [ ],
          userDirectories ? [ ],
          userFiles ? [ ],
          extraOptions ? { },
        }:
        lib.mkMerge [
          {
            environment.systemPackages = [ package ];
            impermanence = {
              inherit
                directories
                files
                userDirectories
                userFiles
                ;
            };
          }
          extraOptions
        ];
    };
    mkIfElse = p: yes: no: lib.mkMerge [
      (lib.mkIf p yes)
      (lib.mkIf (!p) no)
    ];
  }
)

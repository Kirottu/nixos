{
  lib,
}:
let
  entries = builtins.readDir ./.;
  filtered = lib.filterAttrs (name: _: name != "default.nix") entries;
  list = lib.mapAttrsToList (
    name: type:
    let
      basename = lib.removeSuffix ".nix" name;
      path = lib.concatStringsSep "/" [
        ./.
        name
      ];
    in
    {
      name = basename;
      value = import path;
    }
  ) filtered;
in
lib.listToAttrs list

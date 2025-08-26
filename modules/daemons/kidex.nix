{
  inputs,
  config,
  lib,
  ...
}:
let
  cfg = config.daemons.kidex;
in
{
  options.daemons.kidex.enable = lib.mkEnableOption "Kidex";

  config = lib.mkIf cfg.enable {
    hm.imports = [
      inputs.kidex.homeModules.kidex
    ];
    hm.services.kidex = {
      enable = true;
      settings = {
        directories = [
          {
            path = "~/Documents";
            recurse = true;
          }
          {
            path = "~/Pictures";
            recurse = true;
          }
          {
            path = "~/Downloads";
            recurse = false;
          }
        ];
      };
    };
  };
}

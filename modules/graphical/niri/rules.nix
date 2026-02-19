{ config, lib, ... }:

let
  cfg = config.graphical.niri;
in
{
  config.hm.programs.niri.settings.window-rules = lib.mkIf cfg.enable [
    {
      open-floating = false;
    }
    {
      matches = [
        {
          app-id = "^(webapp-cinny|discord|vesktop|equibop)$";
        }
      ];
      open-on-workspace = "chat";
    }
    {
      matches = [
        {
          app-id = "^steam$";
        }
      ];
      open-on-workspace = "games";
    }
    {
      matches = [
        {
          app-id = "^aslains_wows_modpack.*";
        }
      ];
      open-floating = true;
    }
  ];
}

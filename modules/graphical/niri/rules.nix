{ config, lib, ... }:

let
  cfg = config.graphical.niri;
in
{
  config.hm.wayland.windowManager.niri.settings = lib.mkIf cfg.enable {
    window-rule = [
      {
        open-floating = false;
      }
      {
        match._props.app-id = "^(webapp-cinny|discord|vesktop|equibop)$";

        open-on-workspace = "chat";
      }
      {
        match._props.app-id = "^steam$";

        open-on-workspace = "games";
      }
      {
        match._props.app-id = "^aslains_wows_modpack.*";

        open-floating = true;
      }
    ];
    layer-rule = [
      {
        _children = [
          { match._props.layer = "top"; }
          { match._props.layer = "overlay"; }
        ];
        background-effect = {
          xray = false;
        };
      }
    ];
  };
}

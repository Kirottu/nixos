{ config, lib, ... }:

let
  cfg = config.graphical.niri;
in
{
  config.hm.wayland.windowManager.niri.settings = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
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
      }
      {
        diagonals = { };
        bliss = {
          window-rule = [
            {
              geometry-corner-radius = 20;
              clip-to-geometry = true;
              background-effect = {
                blur = true;
              };
            }
            {
              match._props.is-focused = false;

              opacity = 0.92;
            }
          ];
          layer-rule = [
            {
              _children = [
                { match._props.namespace = "yand"; }
                { match._props.namespace = "anyrun"; }
                { match._props.namespace = "ironbar"; }
              ];

              geometry-corner-radius = 20;

              background-effect = {
                blur = true;
                xray = false;
              };
            }
            {
              match._props.namespace = "^wpaperd-*.";

              place-within-backdrop = true;
            }
          ];
        };
      }
      .${config.theming.theme}
    ]
  );
}

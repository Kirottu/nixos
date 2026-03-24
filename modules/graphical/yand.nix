{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.graphical.yand;
in
{
  options.graphical.yand = {
    enable = lib.mkEnableOption "Yand";
    output = lib.mkOption {
      type = with lib.types; nullOr str;

    };
  };

  config = lib.mkIf cfg.enable {
    hm.imports = [
      inputs.yand.homeModules.yand
    ];

    hm.services.yand = {
      enable = true;
      settings = {
        width = 400;
        spacing = 10;
        margin = 5;
        timeout = 5;
        layer = "Top";
        output = lib.mkIf (cfg.output != null) cfg.output;
      };
      style =
        with config.theming.themeAttrs;
        {
          diagonals = ''
            window {
              background: transparent;
            }

            .notification {
              background: linear-gradient(135deg, ${l1} 250px, ${l2} 250px, ${l2} 300px, ${l1} 300px);
              opacity: 1.0;
              margin: 5px;
              box-shadow: 0 0 5px black;
              border-radius: 0;
            }

            .summary {
              margin: 5px;
              font-size: 11pt;
            }

            .body {
              margin: 5px;
            }

            .action {
              border-radius: 0;
              background: ${l3};
              border-right: 1px solid ${l1};
            }

            .action:hover {
              background:
                linear-gradient(-45deg, ${l1} 20px, transparent 20px),
                linear-gradient(45deg, ${l1} 20px, transparent 20px),
                ${l3};
            }

            .action:last-child {
              border-right: none;
            }

            .icon {
              margin: 5px;
            }      '';
          bliss = ''

          '';
        }
        .${config.theming.theme};
    };
  };
}

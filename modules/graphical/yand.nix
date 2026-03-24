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

    hm.services.yand = lib.mkMerge [
      {
        enable = true;
      }
      {
        diagonals = {
          settings = {
            width = 400;
            spacing = 10;
            margin = 5;
            timeout = 5;
            layer = "Top";
            output = lib.mkIf (cfg.output != null) cfg.output;
          };
          style = with config.theming.themeAttrs; ''
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
        };
        bliss = {
          settings = {
            width = 400;
            spacing = 10;
            margin = 10;
            timeout = 5;
            layer = "Top";
            output = lib.mkIf (cfg.output != null) cfg.output;
          };
          style = ''
            window {
              border-radius: 20px;
              background-color: #ffffff90;
              color: black;
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
              border-right: 1px solid @borders;
            }

            .action:first-child {
              border-bottom-left-radius: 20px;
            }

            .action:last-child {
              border-bottom-right-radius: 20px;
              border-right: none;
            }

            .icon {
              margin: 5px;
            }

          '';
        };
      }
      .${config.theming.theme}
    ];
  };
}

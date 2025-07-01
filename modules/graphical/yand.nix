{
  config,
  lib,
  inputs,
  ...
}:
{
  options.graphical.yand.enable = lib.mkEnableOption "Yand";

  config = lib.mkIf config.graphical.yand.enable {
    hm.imports = [
      inputs.yand.homeModules.yand
    ];

    hm.services.yand = {
      enable = true;
      settings = {
        width = 400;
        spacing = 10;
        timeout = 5;
        output =
          {
            church-of-harold = "DP-3";
            missionary-of-harold = "eDP-1";
          }
          .${config.networking.hostName};
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
              margin: 10px;
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
        }
        .${config.theming.theme};
    };
  };
}

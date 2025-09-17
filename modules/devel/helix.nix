{ pkgs, ... }:
{
  config = {
    hm.programs.helix = {
      enable = true;
      defaultEditor = true;
      extraPackages = with pkgs; [
        vscode-langservers-extracted
        nil
        nixfmt-rfc-style
        rust-analyzer
        marksman
        python313Packages.python-lsp-server
        sourcekit-lsp
        typescript-language-server
      ];
      settings = {
        editor = {
          cursor-shape = {
            normal = "block";
            insert = "bar";
            select = "underline";
          };
          lsp = {
            display-messages = true;
            display-inlay-hints = true;
          };
          inline-diagnostics = {
            cursor-line = "warning";
            other-lines = "error";
          };
          end-of-line-diagnostics = "hint";
          auto-format = true;
        };

        # theme = "adwaita-dark";
      };
      languages = {
        language-server.rust-analyzer.config.check = {
          command = "clippy";
        };
        language = [
          {
            name = "css";
            language-servers = [ "vscode-css-language-server" ];
          }
          {
            name = "nix";
            auto-format = true;
            formatter.command = "nixfmt";
          }
        ];
      };
    };
  };
}

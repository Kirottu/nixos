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
        tinymist
        ltex-ls-plus
        marksman
        python313Packages.python-lsp-server
        typescript-language-server
        omnisharp-roslyn
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
            cursor-line = "hint";
            other-lines = "error";
          };
          # end-of-line-diagnostics = "hint";
          auto-format = true;
        };

        keys.normal.space = {
          B = "file_picker_in_current_buffer_directory";
        };

        # theme = "adwaita-dark";
      };
      languages = {
        language-server.rust-analyzer.config.check = {
          command = "clippy";
        };
        language-server.tinymist.config = {
          exportPdf = "onType";
        };
        language-server.nil.config = {
          autoArchive = true;
        };
        language-server.ltex-ls.config = {
          command = "ltex-ls-plus";
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
          {
            name = "typst";
            language-servers = [
              "tinymist"
              "ltex-ls-plus"
            ];
          }
          {
            name = "markdown";
            language-servers = [
              "marksman"
              "ltex-ls-plus"
            ];
          }
        ];
      };
    };
  };
}

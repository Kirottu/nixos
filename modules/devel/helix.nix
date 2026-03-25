{
  pkgs,
  inputs,
  config,
  ...
}:
{
  config = {
    hm.programs.helix = {
      enable = true;
      defaultEditor = true;
      extraPackages =
        with pkgs;
        [
          vscode-langservers-extracted
          nixd
          nixfmt
          rust-analyzer
          tinymist
          ltex-ls-plus
          zls
          marksman
          clang-tools
          python313Packages.python-lsp-server
          typescript-language-server
          omnisharp-roslyn
        ]
        ++
          lib.optional config.daemons.llm.enable
            inputs.codel.packages.${pkgs.stdenv.hostPlatform.system}.default;
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
        language-server.nixd = {
          command = "nixd";
        };
        language-server.codel = {
          command = "codel";
        };
        language = [
          {
            name = "rust";
            language-servers = [
              "rust-analyzer"
              "codel"
            ];
          }
          {
            name = "css";
            language-servers = [ "vscode-css-language-server" ];
          }
          {
            name = "nix";
            auto-format = true;
            formatter.command = "nixfmt";
            language-servers = [ "nixd" ];
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

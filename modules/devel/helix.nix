{ pkgs, inputs, ... }:
{
  config = {
    # hm.programs.helix = {
    #   enable = true;
    #   defaultEditor = true;
    environment.variables.EDITOR = "helix";
    environment.systemPackages = [
      (inputs.wrappers.wrapperModules.helix.apply {
        inherit pkgs;
        extraPackages = with pkgs; [
          vscode-langservers-extracted
          nil
          nixfmt-rfc-style
          rust-analyzer
          tinymist
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
              cursor-line = "warning";
              other-lines = "error";
            };
            end-of-line-diagnostics = "hint";
            auto-format = true;
          };

          theme = "dark_plus";
        };
        languages = {
          language-server.rust-analyzer.config.check = {
            command = "clippy";
          };
          language-server.tinymist.config = {
            exportPdf = "onType";
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
      }).wrapper
    ];
  };
}

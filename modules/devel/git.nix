{
  lib,
  pkgs,
  inputs,
  config,
  ...
}:
{
  options.git.key = lib.mkOption {
    type = lib.types.nonEmptyStr;
  };

  config = {
    # hm.programs.git = {
    #   enable = true;
    #   signing.signByDefault = true;
    #   settings = {
    #     user.name = "Arno Vaara";
    #     user.email = "arnovaara@kirottu.com";
    #     init.defaultBranch = "main";
    #   };
    # };

    mainUser.extraOptions.packages = [
      pkgs.gh
      (inputs.wrappers.wrapperModules.git.apply {
        inherit pkgs;
        settings = {
          user = {
            name = "Arno Vaara";
            email = "arnovaara@kirottu.com";
            signingKey = config.git.key;
          };
          commit.gpgSign = true;
          tag.gpgSign = true;
          init.defaultBranch = "main";
          credential = {
            "github.com" = {
              helper = "${pkgs.gh}/bin/gh auth git-credential";
            };
          };
        };
      }).wrapper
    ];
    # impermanence.userFiles = [
    #   ".config/gh"
    # ];
  };
}

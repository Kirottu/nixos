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

    environment.systemPackages = [
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
        };
      }).wrapper
    ];
    # impermanence.userFiles = [
    #   ".config/gh"
    # ];
  };
}

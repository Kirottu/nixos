{
  lib,
  config,
  pkgs,
  ...
}:
{
  options = {
    mainUser = {
      userName = lib.mkOption {
        default = "kirottu";
        description = "Username";
        type = lib.types.nonEmptyStr;
      };
      hashedPassword = lib.mkOption {
        type = with lib.types; nullOr nonEmptyStr;
        default = null;
        description = "Password hash for user";
      };
      hashedPasswordFile = lib.mkOption {
        type = with lib.types; nullOr path;
        default = null;
        description = "File with password hash for user";
      };
      extraGroups = lib.mkOption {
        type = with lib.types; listOf nonEmptyStr;
        default = [ ];
        description = "Extra groups for the main user";
      };
      shell = lib.mkOption {
        type = lib.types.package;
        description = "Login shell";
      };
      extraOptions = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };
    };
  };

  config = {
    # TODO: Assertion to ensure one password method exists
    users = {
      mutableUsers = false;
      users.${config.mainUser.userName} = lib.mkMerge [
        {
          isNormalUser = true;
          hashedPassword = lib.mkIf (config.mainUser.hashedPassword != null) config.mainUser.hashedPassword;
          hashedPasswordFile = lib.mkIf (
            config.mainUser.hashedPasswordFile != null
          ) config.mainUser.hashedPasswordFile;
          shell = config.mainUser.shell;
          extraGroups = config.mainUser.extraGroups ++ [
            "wheel"
          ];
        }
        config.mainUser.extraOptions
      ];
    };
  };
}

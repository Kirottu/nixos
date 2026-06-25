{
  inputs,
  config,
  lib,
  ...
}:
{
  options =
    let
      pathList = with lib.types; listOf (either attrs nonEmptyStr);
    in
    {
      impermanence = {
        enable = lib.mkEnableOption "Impermanence";
        persistentFs = lib.mkOption {
          type = lib.types.attrs;
          description = "Persistent filesystem";
        };
        directories = lib.mkOption {
          type = pathList;
          default = [ ];
          description = "Additional system level directories to persist";
        };
        files = lib.mkOption {
          type = pathList;
          default = [ ];
          description = "Additional system level files to persist";
        };
        userDirectories = lib.mkOption {
          type = pathList;
          default = [ ];
          description = "Additional user level directories to persist";
        };
        userFiles = lib.mkOption {
          type = pathList;
          default = [ ];
          description = "Additional user level files to persist";
        };
      };
    };

  imports = [
    inputs.impermanence.nixosModules.impermanence
    inputs.persist-retro.nixosModules.persist-retro
  ];

  config = lib.mkIf config.impermanence.enable {
    fileSystems."/" = {
      device = "none";
      fsType = "tmpfs";
      options = [
        "defaults"
        "size=100%"
        "mode=755"
      ];
    };

    fileSystems."/home/${config.mainUser.userName}" = {
      device = "none";
      fsType = "tmpfs";
      neededForBoot = true;
      options = [
        "defaults"
        "size=25%"
        "mode=755"
      ];
    };

    fileSystems."/persistent" = config.impermanence.persistentFs;

    environment.persistence."/persistent" = {
      enable = true;
      hideMounts = true;
      directories = config.impermanence.directories ++ [
        "/var/log"
        "/var/lib/systemd/coredump"
        "/var/lib/nixos"
        "/var/lib/private"
      ];
      files = config.impermanence.files ++ [
        "/etc/machine-id"
      ];
      users.${config.mainUser.userName} = {
        directories = config.impermanence.userDirectories ++ [
          ".config/nix"
        ];
        files = config.impermanence.userFiles;
      };
    };
  };
}

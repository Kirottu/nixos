{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.server.borg;
in
{
  options.server.borg = {
    enable = lib.mkEnableOption "Borg backup";
    repositories = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            keys = lib.mkOption {
              type = lib.types.listOf lib.types.nonEmptyStr;
              example = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILmnknd6bSmWrhpr+I5j3R5fou8gu8zY4V3oc+gTfVuH kirottu@church-of-harold";
            };
            quota = lib.mkOption {
              type = lib.types.nonEmptyStr;
              default = "100G";
            };
          };
        }
      );
      default = { };
    };
  };

  # config = lib.mkIf cfg.enable (
  #   lib.mkMerge (
  #     [
  #     ]
  #     ++ (lib.mapAttrsToList (
  #       name: value:
  #       (
  #         let
  #           user = "${name}-borgbackup";
  #         in
  #         {
  #           users.users.${user} = {
  #             createHome = true;
  #             home = if config.impermanence.enable then "/persistent/home/${user}}" else "/home/${user}";
  #             authorizedKeys = map (
  #               key:
  #               "command=\"${lib.getExe pkgs.borgbackup} serve --restrict-to-repository ${
  #                 config.users.users.${user}.home
  #               } --storage-quota ${value.quota}\",restrict ${key}"
  #             ) value.keys;
  #           };
  #         }
  #       )
  #     ) cfg.repositories)
  #   )
  # );
  config = lib.mkIf cfg.enable {
    impermanence.directories = [ "/root/.ssh" ];
    users = lib.mkMerge (
      lib.mapAttrsToList (
        name: value:
        (
          let
            user = "${name}-borgbackup";
            home = if config.impermanence.enable then "/persistent/home/${user}}" else "/home/${user}";
          in
          {
            users.${user} = {
              inherit home;
              createHome = true;
              group = user;
              isSystemUser = true;
              openssh.authorizedKeys.keys = map (
                key:
                "command=\"${lib.getExe pkgs.borgbackup} serve --restrict-to-path ${home} --storage-quota ${value.quota}\",restrict ${key}"
              ) value.keys;
            };
            groups.${user} = { };
          }
        )
      ) cfg.repositories
    );

  };
}

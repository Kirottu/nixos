{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.nix-index-database.nixosModules.nix-index
  ];
  # FIXME: Needs to be more configurable
  config = {
    programs.nh = {
      enable = true;

      # clean = {
      #   enable = true;
      #   extraArgs = "--keep-since 30d --keep 10";
      # };
      flake = "/home/${config.mainUser.userName}/Projects/nixos";
    };
    programs.nix-index-database.comma.enable = true;

    hm.programs.htop = {
      enable = true;
      settings = {
        hide_kernel_threads = 1;
        hide_userland_threads = 1;
        show_program_path = 0;
        highlight_base_name = 1;
        highlight_deleted_exe = 1;
        highlight_threads = 1;
        highlight_changes = 1;
        highlight_changes_delay_secs = 5;
        find_comm_in_cmdline = 1;
        strip_exe_from_cmdline = 1;
        show_merged_command = 1;
        show_cpu_usage = 1;
        show_cpu_frequency = 1;
        show_cpu_temperature = 1;
      }
      // (
        with config.hm.lib.htop;
        leftMeters [
          (bar "LeftCPUs2")
          (text "Blank")
          (bar "GPU")
          (text "Blank")
          (bar "Memory")
          (bar "Swap")
        ]
      )
      // (
        with config.hm.lib.htop;
        rightMeters [
          (bar "RightCPUs2")
          (text "Tasks")
          (text "LoadAverage")
          (text "Uptime")
          (text "DiskIO")
          (text "NetworkIO")
        ]
      );
    };
  };
}

{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.graphical.tv;
in
{
  options.graphical.tv = {
    enable = lib.mkEnableOption "TV switching support";
    desktopOutputs = lib.mkOption {
      description = "Outputs for desktop mode";
      type = with lib.types; listOf nonEmptyStr;
    };
    tvOutput = lib.mkOption {
      description = "Outputs for TV mode";
      type = lib.types.nonEmptyStr;
    };
    desktopSink = lib.mkOption {
      description = "Audio sink for the desktop";
      type = lib.types.nonEmptyStr;
    };
    tvSink = lib.mkOption {
      description = "Audio sink for the TV";
      type = lib.types.nonEmptyStr;
    };
    tvRegex = lib.mkOption {
      description = "Regex to identify audio device for profile selection";
      type = lib.types.nonEmptyStr;
    };
    tvProfile = lib.mkOption {
      description = "Profile index for the correct audio profile";
      type = lib.types.int;
    };
  };

  config = lib.mkIf config.graphical.tv.enable (
    let
      mkScript =
        toTv: toDesktop:
        let
          stateFile = "/tmp/tv.state";

        in
        pkgs.writeShellScript "tv.sh" ''
          #!/bin/sh

          if [ -f "${stateFile}" ]; then
            rm "${stateFile}"
            ${pkgs.pulseaudio}/bin/pactl set-default-sink ${cfg.desktopSink}

            ${toDesktop}
          else
            touch "${stateFile}"

            ${toTv}
            # Pipewire insists on changing the profile of the GPU audio output,
            # so it has to be set here

            ID=$(wpctl status | grep -e "${cfg.tvRegex}" | tr -s ' ' | cut -d ' ' -f 3 | cut -d '.' -f 1)
            
            ${pkgs.wireplumber}/bin/wpctl set-profile $ID ${toString cfg.tvProfile}
            sleep 1
            ${pkgs.pulseaudio}/bin/pactl set-default-sink ${cfg.tvSink}
          fi
        '';
    in
    lib.mkMerge [
      (lib.mkIf config.graphical.niri.enable (
        let
          niri = lib.getExe pkgs.niri;
          workspaces = config.hm.wayland.windowManager.niri.settings.workspace;
          getName = workspace: (builtins.elemAt workspace._args 0);
          wsToTv = lib.concatStrings (
            builtins.map (ws: ''
              ${niri} msg action move-workspace-to-monitor --reference ${getName ws} ${cfg.tvOutput}
            '') workspaces
          );
          desktopMonsOff = lib.concatStrings (
            builtins.map (output: ''
              ${niri} msg output ${output} off
            '') cfg.desktopOutputs
          );
          desktopMonsOn = lib.concatStrings (
            builtins.map (output: ''
              ${niri} msg output ${output} on
            '') cfg.desktopOutputs
          );
          wsToDesktop = lib.concatStrings (
            builtins.map (ws: ''
              ${niri} msg action move-workspace-to-monitor --reference ${getName ws} ${ws.open-on-output}
            '') workspaces
          );
          fixDesktopOrder = lib.concatStrings (
            lib.flatten (
              builtins.map (
                output:
                lib.imap (i: ws: ''
                  ${niri} msg action move-workspace-to-index --reference ${getName ws} ${toString i}
                '') (builtins.filter (ws: ws.open-on-output == output) workspaces)

              ) cfg.desktopOutputs
            )
          );
          fixTvOrder = lib.concatStrings (
            lib.imap (i: ws: ''
              ${niri} msg action move-workspace-to-index --reference ${getName ws} ${toString i}
            '') workspaces
          );

          script =
            mkScript
              ''
                ${
                  if config.graphical.instant-replay.enable then "systemctl --user stop gpu-screen-recorder" else ""
                }
                ${niri} msg output ${cfg.tvOutput} on
                sleep 1
                ${desktopMonsOff}
                sleep 1
                ${wsToTv}
                ${fixTvOrder}
              ''
              ''
                ${desktopMonsOn}
                sleep 1
                ${niri} msg output ${cfg.tvOutput} off
                sleep 1
                ${wsToDesktop}
                ${fixDesktopOrder}
                ${if config.graphical.waybar.enable then "systemctl --user restart waybar" else ""}
                ${
                  if config.graphical.instant-replay.enable then "systemctl --user start gpu-screen-recorder" else ""
                }
              '';
        in
        {
          hm.wayland.windowManager.niri.settings.binds = {
            "Mod+T" = {
              spawn = "${script}";
            };
          };
        }
      ))
    ]
  );
}

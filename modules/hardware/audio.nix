{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.audio = {
    pipewire.enable = lib.mkEnableOption "Pipewire";
    easyeffects.enable = lib.mkEnableOption "Easyeffects";
  };

  config = lib.mkMerge [
    (lib.mkIf config.audio.pipewire.enable {
      environment.systemPackages = with pkgs; [
        pwvucontrol
        helvum
        pulseaudio
      ];

      impermanence.userDirectories = [ ".config/pulse" ];

      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;

        extraConfig = {
          pipewire = {
            "10-clock-rate" = {
              "context.properties" = {
                "default.clock.quantum" = 2048;
                "default.clock.min-quantum" = 512;
              };
            };
          };
        };
      };
    })
    (lib.mkIf config.audio.easyeffects.enable {
      hm.services.easyeffects.enable = true;
      impermanence.userDirectories = [
        ".config/easyeffects"
        ".local/share/easyeffects"
      ];
    })
  ];
}

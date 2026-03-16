{
  pkgs,
  ...
}:
{
  security = {
    sudo = {
      enable = false;
      extraConfig = ''
        Defaults lecture = never
      '';
    };
    sudo-rs = {
      enable = true;
      # extraConfig = ''
      #   Defaults lecture = false
      # '';
    };
  };
  impermanence.userDirectories = [
    {
      directory = ".gnupg";
      mode = "0700";
    }
  ];
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-gnome3;
  };
}

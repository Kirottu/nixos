{
  config,
  pkgs,
  lib,
  myUtils,
  ...
}:
let
  # glfw = pkgs.glfw3-minecraft.overrideAttrs {
  #   patches = [
  #     ./0001-Key-Modifiers-Fix.patch
  #     ./0002-Fix-duplicate-pointer-scroll-events.patch
  #     ./0003-Implement-glfwSetCursorPosWayland.patch
  #     ./0004-Fix-Window-size-on-unset-fullscreen.patch
  #     ./0005-Add-warning-about-being-an-unofficial-patch.patch
  #     ./0006-Avoid-error-on-startup.patch
  #     ./0007-Fix-fullscreen-location.patch
  #     ./0008-Fix-forge-crash.patch
  #   ];

  # };
in
{
  options.gaming.prismlauncher.enable = lib.mkEnableOption "Prismlauncher";

  config = lib.mkIf config.gaming.prismlauncher.enable (
    myUtils.mkApp {
      package = pkgs.prismlauncher.override {
        # glfw3-minecraft = glfw;
      };
      userDirectories = [ ".local/share/PrismLauncher" ];
    }
  );
}

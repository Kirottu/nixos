{
  pkgs,
  kernel,
}:
pkgs.stdenv.mkDerivation {
  name = "btusb-kernel-module";
  inherit (kernel)
    src
    version
    postPatch
    nativeBuildInputs
    ;

  patches = [ ./ignore_wii_bt.patch ];

  modulePath = "drivers/bluetooth";

  buildPhase = ''
    BUILT_KERNEL=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build

    cp $BUILT_KERNEL/Module.symvers .
    cp $BUILT_KERNEL/.config .
    cp ${kernel.dev}/vmlinux .

    make -j$NIX_BUILD_CORES modules_prepare
    make -j$NIX_BUILD_CORES M=$modulePath modules
  '';

  installPhase = ''
    make \
      INSTALL_MOD_PATH="$out" \
      XZ="xz -T$NIX_BUILD_CORES" \
      M="$modulePath" \
      modules_install
  '';

  meta = {
    description = "Patched BTUSB kernel module";
  };
}

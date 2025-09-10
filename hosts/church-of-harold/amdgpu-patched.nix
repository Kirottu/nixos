{
  pkgs,
  kernel,
  lib,
}:
pkgs.stdenv.mkDerivation {
  name = "amdgpu-kernel-module";
  inherit (kernel)
    src
    version
    postPatch
    nativeBuildInputs
    ;

  patches = [
    pkgs.fetchurl
    {
      url = "https://github.com/Frogging-Family/community-patches/raw/a6a468420c0df18d51342ac6864ecd3f99f7011e/linux61-tkg/cap_sys_nice_begone.mypatch";
      hash = lib.fakeHash;
    }
  ];

  modulePath = "drivers/gpu/drm/amd/amdgpu";

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
    description = "Patched amdgpu kernel module";
  };
}

{
  lib,
  fetchFromGitHub,
  fetchFromGitLab,
  applyPatches,
  cmake,
  git,
  glslang,
  stdenv,
  # librsvg,
  # avahi,
  boost,
  # cli11,
  eigen,
  # ffmpeg,
  glm,
  libdrm,
  # libGL,
  # libnotify,
  # libpulseaudio,
  # libva,
  nlohmann_json,
  openxr-loader,
  # onnxruntime,
  # pipewire,
  # shaderc,
  # spdlog,
  # systemd,
  udev,
  vulkan-headers,
  vulkan-loader,
  # x264,
  pkg-config,
  python3,
  absolute ? false,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "wivrn-server-lib";
  version = "25.9";

  src = fetchFromGitHub {
    owner = "wivrn";
    repo = "wivrn";
    rev = "v${finalAttrs.version}";
    hash = "sha256-XP0bpXgtira2QIlS0fNEteNP48WnEjBYFM1Xmt2sm5I=";
  };

  monado = applyPatches {
    src = fetchFromGitLab {
      domain = "gitlab.freedesktop.org";
      owner = "monado";
      repo = "monado";
      rev = "7a4018e2d89151e60e562fac79eba90ca7a328d8";
      hash = "sha256-DPIvJb23bK7SDjZr9mK0Wt6Zbo3Ari3Ar8TtPe5QgKY=";
    };

    postPatch = ''
      ${finalAttrs.src}/patches/apply.sh ${finalAttrs.src}/patches/monado/*
    '';
  };

  strictDeps = true;

  # Let's make sure our monado source revision matches what is used by WiVRn upstream
  postUnpack = ''
    ourMonadoRev="${finalAttrs.monado.src.rev}"
    theirMonadoRev=$(cat ${finalAttrs.src.name}/monado-rev)
    if [ ! "$theirMonadoRev" == "$ourMonadoRev" ]; then
      echo "Our Monado source revision doesn't match CMakeLists.txt." >&2
      echo "  theirs: $theirMonadoRev" >&2
      echo "    ours: $ourMonadoRev" >&2
      return 1
    fi
  '';

  nativeBuildInputs = [
    cmake
    git
    # glib
    glslang
    # librsvg
    pkg-config
    python3
  ];

  buildInputs = [
    # avahi
    boost
    # cli11
    eigen
    # ffmpeg
    glm
    # harfbuzz
    # libarchive
    libdrm
    # libGL
    # libnotify
    # libpulseaudio
    # librsvg
    # libva
    # libX11
    # libXrandr
    nlohmann_json
    openxr-loader
    # onnxruntime
    # pipewire
    # shaderc
    # spdlog
    # systemd
    udev
    vulkan-headers
    vulkan-loader
    # x264
  ];

  cmakeFlags = [
    (lib.cmakeBool "WIVRN_BUILD_SERVER" false)
    (lib.cmakeBool "WIVRN_BUILD_WIVRNCTL" false)
    (lib.cmakeBool "WIVRN_BUILD_SERVER_LIBRARY" true)
    (lib.cmakeBool "FETCHCONTENT_FULLY_DISCONNECTED" true)
    (lib.cmakeFeature "WIVRN_OPENXR_MANIFEST_TYPE" (if absolute then "absolute" else "filename"))
    (lib.cmakeFeature "GIT_DESC" "v${finalAttrs.version}")
    (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_MONADO" "${finalAttrs.monado}")
  ];

  preFixup =
    if absolute then
      ""
    else
      ''
        mv $out/lib/wivrn/* $out/lib
        rm -r $out/lib/wivrn
      '';

  meta = {
    description = "WiVRn server library";
    platforms = lib.platforms.linux;
  };
})

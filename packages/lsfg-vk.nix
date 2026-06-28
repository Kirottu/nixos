{
  llvmPackages,
  cmake,
  fetchFromGitHub,
  lib,
  vulkan-headers,
  qt6,
}:
llvmPackages.stdenv.mkDerivation rec {
  pname = "lsfg-vk";
  version = "2.0.0-dev";

  src = fetchFromGitHub {
    owner = "PancakeTAS";
    repo = "lsfg-vk";
    tag = "v${version}";
    hash = "sha256-meXXl1hHvmOaVjeGglsYSmVJiaxuijfPesjs8wuKrfs=";
    fetchSubmodules = true;
  };

  postInstall = ''
    substituteInPlace "$out/share/vulkan/implicit_layer.d/VkLayer_LSFGVK_frame_generation.json" \
      --replace-fail "liblsfg-vk-layer.so" "$out/lib/liblsfg-vk-layer.so"
  '';

  nativeBuildInputs = [
    llvmPackages.clang-tools
    llvmPackages.libllvm
    qt6.wrapQtAppsHook
    cmake
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    vulkan-headers
  ];

  cmakeFlags = [
    (lib.cmakeBool "LSFGVK_BUILD_UI" true)
    (lib.cmakeBool "LSFGVK_BUILD_CLI" true)
  ];

  meta = {
    description = "Vulkan layer for frame generation (Requires owning Lossless Scaling)";
    homepage = "https://github.com/PancakeTAS/lsfg-vk/";
    changelog = "https://github.com/PancakeTAS/lsfg-vk/releases/tag/${src.tag}";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}

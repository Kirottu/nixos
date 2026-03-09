{
  lib,
  rustPlatform,
  fetchNpmDeps,
  nodejs,
  npmHooks,
  pkg-config,
  webkitgtk_4_1,
  cargo-tauri,
  fetchFromGitHub,
  wrapGAppsHook4,
  glib-networking,
  libayatana-appindicator,
  makeDesktopItem,
  openssl,
}:
rustPlatform.buildRustPackage rec {
  pname = "sable-tauri";
  version = "1.3.3";

  src = fetchFromGitHub {
    owner = "hazre";
    repo = "cinny";
    rev = "feat/tauri-integration";
    hash = "sha256-V8i/u9G3JUL2WQ+Ru5sRBEAS07e+PBZ4Clnkt7PaHsg=";
  };

  cargoHash = "sha256-GmS4UddwJkZEMvb185Rvq2LN/gJBDRCdA65AH3ZgzC8=";

  npmDeps = fetchNpmDeps {
    name = "${pname}-${version}-npm-deps";
    inherit src;
    hash = "sha256-QbDIvHW/Nj95hFr6k+M/gAyQ1PJ5dDP6CqkfJa8dJIs=";
  };

  nativeBuildInputs = [
    cargo-tauri.hook
    nodejs
    npmHooks.npmConfigHook
    pkg-config
    wrapGAppsHook4
  ];

  buildInputs = [
    glib-networking
    openssl
    webkitgtk_4_1
    libayatana-appindicator
  ];

  postPatch = ''
    substituteInPlace src-tauri/tauri.conf.json \
      --replace com.tauri.dev moe.sable.app
  '';

  npm_config_ignore_scripts = true;

  # desktopItems = [
  #   (makeDesktopItem {
  #     name = "sable";
  #     exec = pname;
  #     icon = "sable";
  #     desktopName = "Sable";
  #     genericName = "Matrix client";
  #     categories = [
  #       "Network"
  #       "InstantMessaging"
  #     ];
  #     startupWMClass = "sable";
  #   })
  # ];

  cargoRoot = "src-tauri";
  buildAndTestSubdir = cargoRoot;
}

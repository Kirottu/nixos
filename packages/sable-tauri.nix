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
  openssl,
}:
rustPlatform.buildRustPackage rec {
  pname = "sable-tauri";
  version = "1.4.0";

  src = fetchFromGitHub {
    owner = "hazre";
    rev = "feat/tauri-integration";
    hash = lib.fakeHash;
  };

  npmDeps = fetchNpmDeps {
    name = "${pname}-${version}-npm-deps";
    inherit src;
    hash = lib.fakeHash;
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
  ];

  cargoRoot = "src-tauri";
  buildAndTestSubdir = cargoRoot;
}

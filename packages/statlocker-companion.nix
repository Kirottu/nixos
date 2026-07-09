{
  lib,
  appimageTools,
  fetchurl,
  stdenv,
  autoPatchelfHook,
  wayland,
  libx11,
  libxcb,
  glib,
  gtk3,
  gdk-pixbuf,
  dbus,
  libsoup_3,
  libgcc,
  webkitgtk_4_1,
  obs-studio,
}:
let

  version = "0.2.5";
  pname = "statlocker-companion";
  src = fetchurl {
    url = "https://updates.statlocker.gg/companion/download/statlocker-companion_amd64.AppImage";
    hash = "sha256-Gm2pIzPMqAh0z8aIie9znXuqbuHd9i7wRZ5aVjU1nXI=";
  };

  src-extracted = appimageTools.extract { inherit version pname src; };
in
stdenv.mkDerivation {
  inherit version pname;
  src = src-extracted;

  # sourceRoot = ".";

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  installPhase = ''
    mkdir -p $out/bin
    install -m755 -D $src/usr/bin/statlocker-companion $out/bin/statlocker-companion
    cp -r $src/usr/share $out/
  '';

  buildInputs = [
    wayland
    libx11
    libxcb
    glib
    gtk3
    gdk-pixbuf
    dbus
    libsoup_3
    libgcc
    webkitgtk_4_1
    obs-studio
  ];
}

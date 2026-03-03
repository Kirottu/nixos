{
  buildNpmPackage,
  electron,
  fetchFromGitHub,
  makeDesktopItem,
  copyDesktopItems,
}:
buildNpmPackage rec {
  pname = "sable-matrix-client-electron";
  version = "1.0.0";
  src = fetchFromGitHub {
    owner = "7w1";
    repo = "Sable-Client-Electron";
    rev = "8751d73cc6c53fb7abdf5b99232e541166944ff8";
    # hash = "sha256-XawYnHHuAS4HbsQYKhRQ0qPeZom7KB/2sw4GMFq5C9s=";
    hash = "sha256-oI8dr8Ud5+by2oJYUZ+OS/HDFkBIcyuqDZ59M5hM118=";
  };

  # npmDepsHash = "sha256-oI8dr8Ud5+by2oJYUZ+OS/HDFkBIcyuqDZ59M5hM118=";
  npmDepsHash = "sha256-XawYnHHuAS4HbsQYKhRQ0qPeZom7KB/2sw4GMFq5C9s=";
  # npmDepsHash = "sha256-oI8dr8Ud5+by2oJYUZ+OS/HDFkBIcyuqDZ59M5hM118=";

  nativeBuildInputs = [
    electron
    copyDesktopItems
  ];

  dontNpmBuild = true;

  desktopItem = makeDesktopItem {
    name = "sable";
    exec = pname;
    icon = "sable";
    desktopName = "Sable";
    genericName = "Matrix client";
    categories = [
      "Network"
      "InstantMessaging"
    ];
    startupWMClass = "sable";
  };
  env = {
    ELECTRON_SKIP_BINARY_DOWNLOAD = 1;
  };

  postInstall = ''
    makeWrapper ${electron}/bin/electron $out/bin/${pname} \
      --add-flags $out/lib/node_modules/${pname}/main.js

    mkdir -p $out/share/icons/hicolor/512x512/apps

    cp icon.png $out/share/icons/hicolor/512x512/apps/sable.png

    install -Dm444 -t $out/share/applications ${desktopItem}/share/applications/*.desktop
  '';
}

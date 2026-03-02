{
  buildNpmPackage,
  electron,
  fetchFromGitHub,
}:
buildNpmPackage rec {
  pname = "sable-matrix-client-electron";
  version = "1.0.0";
  src = fetchFromGitHub {
    owner = "7w1";
    repo = "Sable-Client-Electron";
    rev = "8751d73cc6c53fb7abdf5b99232e541166944ff8";
  };

  nativeBuildInputs = [ electron ];

  dontNpmBuild = true;

  env = {
    ELECTRON_SKIP_BINARY_DOWNLOAD = 1;
  };

  postInstall = ''
    makeWrapper ${electron}/bin/electron $out/bin/${pname}
      --add-flags $out/lib/node_modules/${pname}/main.js
  '';
}

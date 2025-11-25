{
  lib,
  stdenv,
  fetchurl,
}:
stdenv.mkDerivation rec {
  pname = "stremio-enhanced";
  version = "1.0.1";

  src = fetchurl {
    url = 
    hash = "sha256-8MJNqAk2dgvmmTspdNga3879AuczbJUkX24Hh/NxLTA=";
  };

    server = fetchurl rec {
    pname = "stremio-server";
    version = "4.20.8";
    url = "https://dl.strem.io/server/v${version}/desktop/server.js";
    hash = "sha256-cRMgD1d1yVj9FBvFAqgIqwDr+7U3maE8OrCsqExftHY=";
    meta.license = lib.licenses.unfree;
  };

  meta = {
    mainProgram = "stremio-enhanced";
  };
}

{
  pkgs,
  nodejs,
  fetchzip,
  makeWrapper,
  lib,

  # The binaries open-in should have access to
  bins,
  ...
}:
let
  version = "1.0.0";
in
pkgs.stdenv.mkDerivation rec {
  pname = "open-in-native-client";
  inherit version;
  src = fetchzip {
    url = "https://github.com/andy-portmen/native-client/releases/download/${version}/linux.zip";
    hash = "sha256-6hpNyYSus7psIc3CL4TZRQ7LJV40dHmrUgx+/0nBn9Q";
    stripRoot = false;
  };

  patches = [ ./install.patch ];

  nativeBuildInputs = [
    makeWrapper
    nodejs
  ];

  installPhase = ''
    cd app
    node install.js --prefix-dir=$out --custom-dir=/lib

    wrapProgram $out/lib/com.add0n.node/run.sh \
      --suffix PATH : ${lib.makeBinPath bins}

    substituteInPlace $out/lib/mozilla/native-messaging-hosts/com.add0n.node.json \
      --replace "/lib" "$out/lib"
  '';

  meta = {
    description = "Native messaging host for open-in browser extensions";
  };
}

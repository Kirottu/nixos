{
  buildGoModule,
  pkg-config,
  fetchFromGitHub,
  ffmpeg,
  yt-dlp,
  sqlite,
  opusfile,
  libogg,
}:
buildGoModule rec {
  pname = "mumzic";
  version = "0.1";

  src = fetchFromGitHub {
    owner = "iotku";
    repo = "mumzic";
    rev = "96af8d2e540adc34ddff5f782283cc3b4914d34a";
    hash = "sha256-u8GrsA6jxJvoAF/GB2kE5bMstoE1IfOl4heqvULlfNY=";
  };

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    ffmpeg
    yt-dlp
    sqlite
    opusfile
    libogg
  ];

  vendorHash = "sha256-E87DC5jN+bxRhiluPLz1g9vBTdRskge4JmLgeFrYQQE=";

  meta = {
    mainProgram = "mumzic";
  };
}

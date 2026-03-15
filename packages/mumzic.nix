{
  buildGoModule,
  pkg-config,
  fetchFromGitHub,
  lib,
}:
buildGoModule rec {
  pname = "mumzic";
  version = "0.1";

  src = fetchFromGitHub {
    owner = "iotku";
    repo = "mumzic";
    rev = "96af8d2e540adc34ddff5f782283cc3b4914d34a";
    hash = lib.fakeHash;
  };

  vendorHash = lib.fakeHash;
}

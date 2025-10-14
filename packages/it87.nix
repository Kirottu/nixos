{
  stdenv,
  fetchFromGitHub,
  kernel,
  kmod,
}:
stdenv.mkDerivation {
  pname = "it87";
  version = "1";

  src = fetchFromGitHub {
    owner = "frankcrawford";
    repo = "it87";
    rev = "60d9def80d65e7e34a73e6f32d8677ad5bfa58a9";
    hash = "sha256-xlUyq1DQFBCvAs9DP6i1ose+6e+nmmXFRyuzRXCg+Ko=";
  };

  hardeningDisable = [
    "pic"
    "format"
  ];
  nativeBuildInputs = kernel.moduleBuildDependencies;

  postPatch = ''
    substituteInPlace Makefile \
      --replace-fail 'depmod -a -F $(SYSTEM_MAP) $(TARGET)' ""
  '';

  makeFlags = [
    "TARGET=${kernel.modDirVersion}"
    "KERNEL_MODULES=${kernel.dev}/lib/modules/${kernel.modDirVersion}"
    "KERNEL_BUILD=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "MODDESTDIR=$(out)"
  ];

  meta = {
    description = "An up to date it87 kernel module";
    homepage = "https://github.com/frankcrawford/it87/";
  };
}

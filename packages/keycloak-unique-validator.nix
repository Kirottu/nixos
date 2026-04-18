{
  lib,
  fetchFromGitHub,
  maven,
}:

maven.buildMavenPackage rec {
  pname = "keycloak-unique-validator";
  version = "1.0-SNAPSHOT"; # When updating also update mvnHash

  src = fetchFromGitHub {
    owner = "dawidgora";
    repo = "keycloak-unique-attribute-validator-provider";
    rev = "b8f6ae351b9d9be54e384b60f33c5ad161c21fef";
    hash = "sha256-W2nXJ6JdFqHTkfBT85iHKYVXyyntqsLWeYzRXl/G/oI=";
  };

  mvnHash = "sha256-D221zsacDyLUVJ8jYP0e1cqKUcJw901pOUlGunjTL8A=";

  sourceRoot = "${src.name}/unique-attribute-validator-provider";

  installPhase = ''
    install -D "target/unique-attribute-validator-provider-${version}.jar" "$out/unique-attribute-validator-provider-${version}.jar"
  '';

  meta = {
    homepage = "https://github.com/dawidgora/keycloak-unique-attribute-validator-provider/";
    description = "User attribute uniqueness validator";
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      binaryBytecode # dependencies
    ];
    license = lib.licenses.mit;
  };
}

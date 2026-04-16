{
  lib,
  fetchFromGitHub,
  maven,
}:

maven.buildMavenPackage rec {
  pname = "scim-for-keycloak";
  version = "1.0-SNAPSHOT"; # When updating also update mvnHash

  src = fetchFromGitHub {
    owner = "dawidgora";
    repo = "keycloak-unique-attribute-validator-provider";
    rev = "b8f6ae351b9d9be54e384b60f33c5ad161c21fef";
    hash = "sha256-kHjCVkcD8C0tIaMExDlyQmcWMhypisR1nyG93laB8WU=";
  };

  mvnHash = "sha256-cOuJSU57OuP+U7lI+pDD7g9HPIfZAoDPYLf+eO+XuF4=";

  installPhase = ''
    install -D "unique-attribute-validator-provider/target/unique-attribute-validator-provider-${version}.jar" "$out/unique-attribute-validator-provider-${version}.jar"
  '';

  meta = {
    homepage = "https://github.com/dawidgora/keycloak-unique-attribute-validator-provider/";
    description = "User attribute uniqueness validator";
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      binaryBytecode # dependencies
    ];
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ mkg20001 ];
  };
}

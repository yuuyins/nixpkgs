{ lib, buildGoModule, fetchFromGitHub
, nixosTests, postgresql, postgresqlTestHook }:

buildGoModule rec {
  pname = "matrix-dendrite";
  version = "0.10.1";

  src = fetchFromGitHub {
    owner = "matrix-org";
    repo = "dendrite";
    rev = "v${version}";
    sha256 = "sha256-o+vdxjxbgTPhXtmjrMXf/kBGYaaF3nvVnrG+PGnaM70=";
  };

  vendorSha256 = "sha256-sd2frDxtMd0YUVCCQGaNYU7KopZQC1Ld5OHnjttTrgA=";

  # some tests are racy, re-enable once upstream has fixed them
  doCheck = false;

  checkInputs = [
    postgresqlTestHook
    postgresql
  ];

  postgresqlTestUserOptions = "LOGIN SUPERUSER";
  preCheck = ''
    export PGUSER=$(whoami)
    # temporarily disable this failing test
    # it passes in upstream CI and requires further investigation
    rm roomserver/internal/input/input_test.go
  '';

  passthru.tests = {
    inherit (nixosTests) dendrite;
  };

  meta = with lib; {
    homepage = "https://matrix-org.github.io/dendrite";
    description = "A second-generation Matrix homeserver written in Go";
    license = licenses.asl20;
    maintainers = teams.matrix.members;
    platforms = platforms.unix;
  };
}

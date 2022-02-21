{ lib, fetchFromGitHub, buildGoModule }:

buildGoModule rec {
  pname = "ops";
  version = "0.1.30";

  src = fetchFromGitHub {
    owner = "nanovms";
    repo = pname;
    rev = version;
    sha256 = lib.fakeSha256;
  };

  vendorSha256 = lib.fakeSha256;

  nativeBuildInputs = [ ];
  buildInputs = [ ];
  checkInputs = [ ];

  doCheck = true;
  checkTarget = "test";

  meta = with lib; {
    description = "Tool for creating and running a Nanos unikernel";
    homepage = "https://github.com/nanovms/ops";
    changelog = "https://github.com/nanovms/ops/releases";
    maintainers = with lib.maintainers; [ yuu ];
    license = lib.licenses.mit;
  };
}

{ lib
, buildGoModule
, fetchFromGitHub
, gitleaks
, installShellFiles
, testers
}:

buildGoModule rec {
  pname = "gitleaks";
  version = "8.14.1";

  src = fetchFromGitHub {
    owner = "zricethezav";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-UHl+bb7Szw+gB5oy0Wsc2fhEniXNnuIXFtV62kJy3f8=";
  };

  vendorSha256 = "sha256-Ev0/CSpwJDmc+Dvu/bFDzsgsq80rWImJWXNAUqYHgoE=";

  ldflags = [
    "-s"
    "-w"
    "-X github.com/zricethezav/gitleaks/v${lib.versions.major version}/cmd.Version=${version}"
  ];

  nativeBuildInputs = [ installShellFiles ];

  # With v8 the config tests are are blocking
  doCheck = false;

  postInstall = ''
    installShellCompletion --cmd ${pname} \
      --bash <($out/bin/${pname} completion bash) \
      --fish <($out/bin/${pname} completion fish) \
      --zsh <($out/bin/${pname} completion zsh)
  '';

  passthru.tests.version = testers.testVersion {
    package = gitleaks;
    command = "${pname} version";
  };

  meta = with lib; {
    description = "Scan git repos (or files) for secrets";
    longDescription = ''
      Gitleaks is a SAST tool for detecting hardcoded secrets like passwords,
      API keys and tokens in git repos.
    '';
    homepage = "https://github.com/zricethezav/gitleaks";
    license = with licenses; [ mit ];
    maintainers = with maintainers; [ fab ];
  };
}

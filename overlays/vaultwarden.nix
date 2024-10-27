final: prev: {
  scala-cli = prev.scala-cli.overrideAttrs (old: rec {
    version = "1.32.2";
    src = prev.fetchFromGitHub {
      owner = "dani-garcia";
      repo = "vaultwarden";
      rev = version;
      hash = "sha256-69uTSZJrqDqaOVm504XbegqyBFIQCVMPBk4lybFZctE=";
    };
  });
}

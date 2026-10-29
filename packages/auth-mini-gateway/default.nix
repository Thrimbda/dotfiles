{ lib
, rustPlatform
, fetchFromGitHub
, ...
}:

rustPlatform.buildRustPackage rec {
  pname = "auth-mini-gateway";
  version = "0.1.0-unstable-2026-10-30";

  src = fetchFromGitHub {
    owner = "Thrimbda";
    repo = "auth-mini-gateway";
    rev = "f64d3359a717e374d14d18f1f4b77b0326989026";
    hash = "sha256-xgSAGXjqBE2b3BdTXSwsOMQ1TLuY3K1N7WR82N7eRD8=";
  };

  cargoHash = "sha256-0x3JtygGkt9kbhWzi57+aSPlhG7XiAqZnTXyPW4mk+I=";
  checkType = "debug";

  meta = with lib; {
    description = "nginx auth_request gateway for auth-mini sessions";
    homepage = "https://github.com/Thrimbda/auth-mini-gateway";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "auth-mini-gateway";
  };
}

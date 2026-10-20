{ lib
, rustPlatform
, fetchFromGitHub
, ...
}:

rustPlatform.buildRustPackage rec {
  pname = "auth-mini-gateway";
  version = "0.1.0-unstable-2026-10-20";

  src = fetchFromGitHub {
    owner = "Thrimbda";
    repo = "auth-mini-gateway";
    rev = "e92f0ebdbd203465d09a4698da56a636094f7246";
    hash = "sha256-BZVkgRxzNqoZmhq7qq2JawXVOtpywJ7hP5rQwvCI+bA=";
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

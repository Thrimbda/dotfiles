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
    rev = "195bfeeada3ef0a7d93ac16d2fa6cbed42290092";
    hash = "sha256-h+VhegyM16TybH8tzamE6KTg0LOho0kHFjG9QnNnZ8g=";
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

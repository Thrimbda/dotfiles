{ lib
, rustPlatform
, fetchFromGitHub
, ...
}:

rustPlatform.buildRustPackage rec {
  pname = "auth-mini-gateway";
  version = "0.1.0-unstable-2026-07-10";

  src = fetchFromGitHub {
    owner = "Thrimbda";
    repo = "auth-mini-gateway";
    rev = "f0519d1fcfbf49be43602f7a25ad2373434366fe";
    hash = "sha256-ns4909zzhmaI7BNbxtaE1m+/gLQ3nrXdKEsidlNj1Z0=";
  };

  cargoHash = "sha256-TeHBF8qw6ge58WKPnhPSFuJbX+m0c+kCo5GK4wjDUzQ=";

  meta = with lib; {
    description = "nginx auth_request gateway for auth-mini sessions";
    homepage = "https://github.com/Thrimbda/auth-mini-gateway";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "auth-mini-gateway";
  };
}

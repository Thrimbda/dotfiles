{ lib
, rustPlatform
, fetchFromGitHub
, ...
}:

rustPlatform.buildRustPackage rec {
  pname = "auth-mini-gateway";
  version = "0.1.0-unstable-2026-07-13";

  src = fetchFromGitHub {
    owner = "Thrimbda";
    repo = "auth-mini-gateway";
    rev = "3e4c273ae244e0745419ddc01d2ec02e3c140dbb";
    hash = "sha256-mPW3Q7mR9uxmsd8OJb0xE82+d7LQgSYUb/HUAFwiu2g=";
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

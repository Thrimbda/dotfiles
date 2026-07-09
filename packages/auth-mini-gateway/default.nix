{ lib
, rustPlatform
, fetchFromGitHub
, ...
}:

rustPlatform.buildRustPackage rec {
  pname = "auth-mini-gateway";
  version = "0.1.0-unstable-2026-07-09";

  src = fetchFromGitHub {
    owner = "Thrimbda";
    repo = "auth-mini-gateway";
    rev = "f3df1c0300e67468348eeb6f012abd85b8681081";
    hash = "sha256-a0kj8pt7zInfS80zqmG/GFzoA6v8xvX++IIX1GwhFfI=";
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

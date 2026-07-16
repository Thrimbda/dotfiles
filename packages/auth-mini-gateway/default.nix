{ lib
, rustPlatform
, fetchFromGitHub
, ...
}:

rustPlatform.buildRustPackage rec {
  pname = "auth-mini-gateway";
  version = "0.1.0-unstable-2026-07-16";

  src = fetchFromGitHub {
    owner = "Thrimbda";
    repo = "auth-mini-gateway";
    rev = "28a4a273ea9b2725191dce35233f55972beaac6f";
    hash = "sha256-hIOiqU/Vz/PP7wczohGOZKMDbwnvXuK+JCAnBK+pFuk=";
  };

  cargoHash = "sha256-omQV9EvK9QaTeBQOnY/sbsTlRJ/VeoIu7xEwrQdJMRw=";
  checkType = "debug";

  meta = with lib; {
    description = "nginx auth_request gateway for auth-mini sessions";
    homepage = "https://github.com/Thrimbda/auth-mini-gateway";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "auth-mini-gateway";
  };
}

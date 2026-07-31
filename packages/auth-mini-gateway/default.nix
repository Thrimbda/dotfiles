{ lib
, rustPlatform
, fetchFromGitHub
, ...
}:

rustPlatform.buildRustPackage rec {
  pname = "auth-mini-gateway";
  version = "0.1.0-unstable-2026-07-30";

  src = fetchFromGitHub {
    owner = "Thrimbda";
    repo = "auth-mini-gateway";
    rev = "e1ea3e77fc39612b7418a3a44db5e2cc2b8618d4";
    hash = "sha256-gkaFhFbPk/oyyYrnOJzeRs0oexMQTMH7y5Ci3exqPxk=";
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

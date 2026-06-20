{ lib, rustPlatform, systemd, ... }:

rustPlatform.buildRustPackage {
  pname = "axiom-mode";
  version = "0.1.0";

  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  AXIOM_MODE_SYSTEMCTL = "${systemd}/bin/systemctl";

  meta = with lib; {
    description = "Axiom host mode switcher for desktop and SSH-friendly CLI targets";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}

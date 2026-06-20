{ lib, rustPlatform, systemd, heyBin ? "hey", ... }:

rustPlatform.buildRustPackage {
  pname = "axiomctl";
  version = "0.1.0";

  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  AXIOMCTL_SYSTEMCTL = "${systemd}/bin/systemctl";
  AXIOMCTL_HEY = heyBin;

  meta = with lib; {
    description = "Axiom host control CLI for mode switching and session maintenance";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}

{ lib, rustPlatform, systemd, heyBin ? "hey", ... }:

rustPlatform.buildRustPackage {
  pname = "c1ctl";
  version = "0.1.0";

  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  C1CTL_SYSTEMCTL = "${systemd}/bin/systemctl";
  C1CTL_HEY = heyBin;

  meta = with lib; {
    description = "C1 dotfiles control CLI";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}

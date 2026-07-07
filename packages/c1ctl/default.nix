{ lib
, rustPlatform
, systemd
, openssh
, heyBin ? "hey"
, autosshRemoteHost ? ""
, autosshRemoteUser ? ""
, autosshRemotePort ? 0
, autosshRemoteHostKey ? ""
, ...
}:

rustPlatform.buildRustPackage {
  pname = "c1ctl";
  version = "0.1.0";

  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  C1CTL_SYSTEMCTL = "${systemd}/bin/systemctl";
  C1CTL_HEY = heyBin;
  C1CTL_SSH = "${openssh}/bin/ssh";
  C1CTL_AUTOSSH_REMOTE_HOST = autosshRemoteHost;
  C1CTL_AUTOSSH_REMOTE_USER = autosshRemoteUser;
  C1CTL_AUTOSSH_REMOTE_PORT = toString autosshRemotePort;
  C1CTL_AUTOSSH_REMOTE_HOST_KEY = autosshRemoteHostKey;

  meta = with lib; {
    description = "C1 dotfiles control CLI";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}

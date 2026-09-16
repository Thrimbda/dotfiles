{ pkgs, ... }:
let
  connect = pkgs.writeShellScriptBin "charlie-screen" ''
    set -eu
    if ! ${pkgs.python3}/bin/python3 - <<'PY'
    import socket
    try:
        with socket.create_connection(("10.77.0.3", 5900), timeout=5) as stream:
            stream.settimeout(5)
            if not stream.recv(12).startswith(b"RFB "):
                raise OSError("No screen-sharing server")
    except OSError:
        raise SystemExit(1)
    PY
    then
      echo "Charlie screen sharing is unavailable. Check /var/log/desktop-wireguard.log and Charlie's Sharing settings." >&2
      exit 1
    fi
    exec /usr/bin/open 'vnc://10.77.0.3'
  '';
in {
  system.build.screenSharingTools = connect;
  environment.systemPackages = [ connect ];
}

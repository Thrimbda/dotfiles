{ pkgs, ... }:
let
  connect = pkgs.writeShellScriptBin "charlie-screen" ''
    set -eu

    lan_host=192.168.10.4
    wg_host=10.77.0.3
    check=0
    if [ "''${1:-}" = "--check" ]; then
      check=1
    fi

    # Accept a connection only when the peer actually speaks RFB. A bare TCP
    # connect is not enough: Clash's TUN accepts connections to unreachable
    # addresses before failing, which is how 10.77.0.3 used to hang.
    probe() {
      ${pkgs.python3}/bin/python3 - "$1" "$2" "$3" <<'PY'
    import socket
    import sys

    host, port, timeout = sys.argv[1], int(sys.argv[2]), float(sys.argv[3])
    try:
        with socket.create_connection((host, port), timeout=timeout) as stream:
            stream.settimeout(2.0)
            if not stream.recv(12).startswith(b"RFB "):
                raise OSError("no RFB banner")
    except OSError:
        sys.exit(1)
    PY
    }

    has_addr() {
      /sbin/ifconfig 2>/dev/null | /usr/bin/grep -q "inet $1"
    }

    chosen=
    lan_status="not on a 192.168.10.0/24 network"
    if has_addr 192.168.10.; then
      if probe "$lan_host" 5900 2; then
        chosen=$lan_host
      else
        lan_status="no RFB server on $lan_host:5900"
      fi
    fi

    wg_status="WireGuard interface (10.77.0.4) is down"
    if [ -z "$chosen" ] && has_addr 10.77.0.4; then
      if probe "$wg_host" 5900 3; then
        chosen=$wg_host
      else
        wg_status="no RFB server on $wg_host:5900"
      fi
    fi

    if [ -z "$chosen" ]; then
      echo "Charlie screen sharing is unavailable." >&2
      echo "  LAN  ($lan_host): $lan_status" >&2
      echo "  WG   ($wg_host): $wg_status" >&2
      echo "Check /var/log/desktop-wireguard.log, 'launchctl print system/org.nixos.desktop-wireguard', and Charlie's Sharing settings." >&2
      echo "If you opened Screen Sharing by the name 'charlie', that name resolves through Clash and will not work; use this command instead." >&2
      exit 1
    fi

    if [ "$check" = 1 ]; then
      echo "$chosen"
      exit 0
    fi

    exec /usr/bin/open "vnc://$chosen"
  '';
in {
  system.build.screenSharingTools = connect;
  environment.systemPackages = [ connect ];
}

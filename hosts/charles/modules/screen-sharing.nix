{ pkgs, ... }:
let
  connect = pkgs.writeShellScriptBin "charlie-screen" ''
    set -eu
    if ! ${pkgs.python3}/bin/python3 - <<'PY'
    import socket
    try:
        with socket.create_connection(("127.0.0.1", 15900), timeout=5) as stream:
            stream.settimeout(5)
            if not stream.recv(12).startswith(b"RFB "):
                raise OSError("No screen-sharing server")
    except OSError:
        raise SystemExit(1)
    PY
    then
      echo "Charlie screen sharing is unavailable. Check FRP logs in ~/Library/Logs/frpc.log and Charlie's Sharing settings." >&2
      exit 1
    fi
    exec /usr/bin/open 'vnc://127.0.0.1:15900'
  '';
in {
  imports = [ ../../../config/frp/mac-client.nix ];

  modules.services.frp.client.darwinUserAgent = true;

  modules.services.frp.client.visitors = [{
    name = "charlie-screen-sharing-visitor";
    type = "stcp";
    serverName = "charlie-screen-sharing";
    secretKey = "@FRP_SCREEN_KEY@";
    bindAddr = "127.0.0.1";
    bindPort = 15900;
    transport.useEncryption = true;
  }];

  system.build.screenSharingTools = connect;
  environment.systemPackages = [ connect ];
}

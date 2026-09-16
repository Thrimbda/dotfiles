{ config, lib, pkgs, ... }:
let
  relay = import ../../../config/frp/sunshine-relay.nix { inherit config lib pkgs; };
  ant = import ../../../config/relay.nix;
  proxy = type: port: {
    name = "axiom-sunshine-${type}-${toString port}";
    inherit type;
    localIP = "127.0.0.1";
    localPort = port;
    remotePort = port;
    transport.useCompression = false;
  };
in {
  systemd.services.frpc-sunshine = lib.recursiveUpdate
    (relay.mkService "frpc" {
      inherit (relay) auth;
      serverAddr = ant.publicIp;
      serverPort = relay.port;
      loginFailExit = false;
      transport = {
        # QUIC still uses reliable streams. v2 negotiates the compact UDP
        # binary codec in frp 0.71, avoiding JSON/base64 packet expansion.
        protocol = "quic";
        wireProtocol = "v2";
        tls = {
          enable = true;
          trustedCaFile = ../../../config/frp/ant-frps.crt;
          serverName = ant.publicIp;
        };
      };
      proxies = (map (proxy "tcp") relay.tcpPorts) ++ (map (proxy "udp") relay.udpPorts);
    })
    {
      after = [ "network-online.target" ant.frpcDirectRouteUnit ];
      requires = [ ant.frpcDirectRouteUnit ];
    };
}

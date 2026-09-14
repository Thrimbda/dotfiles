{ config, lib, pkgs, ... }:
let
  relay = import ../../../config/frp/sunshine-relay.nix { inherit config lib pkgs; };
in {
  systemd.services.frps-sunshine = relay.mkService "frps" {
    inherit (relay) auth;
    bindAddr = "0.0.0.0";
    bindPort = relay.port;
    quicBindPort = relay.port;
    allowPorts = map (single: { inherit single; }) (relay.tcpPorts ++ relay.udpPorts);
    transport.tls = {
      force = true;
      certFile = ../../../config/frp/acorn-frps.crt;
      keyFile = config.age.secrets.frps-tls-key.path;
    };
  };

  networking.firewall.allowedUDPPorts = [ relay.port ] ++ relay.udpPorts;
}

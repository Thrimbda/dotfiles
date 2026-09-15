{ config, lib, pkgs, ... }:
let
  relay = import ../../../config/frp/sunshine-relay.nix { inherit config lib pkgs; };
in {
  age.secrets.frp-token = { owner = config.user.name; mode = "0400"; };
  age.secrets.frps-tls-key = { owner = config.user.name; mode = "0400"; };

  # Preserve the deployed relay shared with Sunshine; STCP needs no public VNC port.
  systemd.services.frps-sunshine = relay.mkService "frps" {
    inherit (relay) auth;
    bindAddr = "0.0.0.0";
    bindPort = relay.port;
    quicBindPort = relay.port;
    allowPorts = map (single: { inherit single; }) (relay.tcpPorts ++ relay.udpPorts);
    transport.tls = {
      force = true;
      certFile = ../../../config/frp/ant-frps.crt;
      keyFile = config.age.secrets.frps-tls-key.path;
    };
  };

  networking.firewall.allowedTCPPorts = [ relay.port ] ++ relay.tcpPorts;
  networking.firewall.allowedUDPPorts = [ relay.port ] ++ relay.udpPorts;
}

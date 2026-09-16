{ config, lib, pkgs, ... }:
let
  host = config.networking.hostName;
  net = import ./network.nix { inherit lib host; };
  hub = host == "ant";
  ipt = "${pkgs.iptables}/bin/iptables -w";
  firewall = pkgs.writeShellScript "wgdesk-firewall" ''
    set -eu
    if [ "$1" = stop ]; then
      ${ipt} -D INPUT -j wgdesk-input 2>/dev/null || true
      ${ipt} -F wgdesk-input 2>/dev/null || true
      ${ipt} -X wgdesk-input 2>/dev/null || true
      ${lib.optionalString hub ''
        ${ipt} -D FORWARD -i wgdesk -j wgdesk-forward 2>/dev/null || true
        ${ipt} -D FORWARD -o wgdesk -j wgdesk-forward 2>/dev/null || true
        ${ipt} -F wgdesk-forward 2>/dev/null || true
        ${ipt} -X wgdesk-forward 2>/dev/null || true
      ''}
      exit 0
    fi
    ${ipt} -N wgdesk-input 2>/dev/null || true
    ${ipt} -F wgdesk-input
    ${lib.optionalString hub ''${ipt} -A wgdesk-input -p udp --dport 51820 -j ACCEPT''}
    ${ipt} -A wgdesk-input -i wgdesk -p icmp -j ACCEPT
    ${lib.optionalString (!hub) ''
      ${ipt} -A wgdesk-input -i wgdesk -s ${net.peers.charles.ip} -p tcp -m multiport --dports 47984,47989,48010 -j ACCEPT
      ${ipt} -A wgdesk-input -i wgdesk -s ${net.peers.charles.ip} -p udp -m multiport --dports 47998,47999,48000 -j ACCEPT
    ''}
    ${ipt} -A wgdesk-input -i wgdesk -j DROP
    ${ipt} -C INPUT -j wgdesk-input 2>/dev/null || ${ipt} -I INPUT 1 -j wgdesk-input
    ${lib.optionalString hub ''
      ${pkgs.procps}/bin/sysctl -q -w net.ipv4.ip_forward=1
      ${ipt} -N wgdesk-forward 2>/dev/null || true
      ${ipt} -F wgdesk-forward
      ${ipt} -A wgdesk-forward -i wgdesk -o wgdesk -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
      ${ipt} -A wgdesk-forward -i wgdesk -o wgdesk -p icmp -j ACCEPT
      ${ipt} -A wgdesk-forward -i wgdesk -o wgdesk -s ${net.peers.charles.ip} -d ${net.peers.axiom.ip} -p tcp -m multiport --dports 47984,47989,48010 -j ACCEPT
      ${ipt} -A wgdesk-forward -i wgdesk -o wgdesk -s ${net.peers.charles.ip} -d ${net.peers.axiom.ip} -p udp -m multiport --dports 47998,47999,48000 -j ACCEPT
      ${ipt} -A wgdesk-forward -i wgdesk -o wgdesk -s ${net.peers.charles.ip} -d ${net.peers.charlie.ip} -p tcp --dport 5900 -j ACCEPT
      ${ipt} -A wgdesk-forward -i wgdesk -o wgdesk -s ${net.peers.charles.ip} -d ${net.peers.charlie.ip} -p udp --dport 5900:5902 -j ACCEPT
      ${ipt} -A wgdesk-forward -i wgdesk -o wgdesk -s ${net.peers.charlie.ip} -d ${net.peers.charles.ip} -p udp --dport 5900:5902 -j ACCEPT
      ${ipt} -A wgdesk-forward -j DROP
      ${ipt} -C FORWARD -i wgdesk -j wgdesk-forward 2>/dev/null || ${ipt} -I FORWARD 1 -i wgdesk -j wgdesk-forward
      ${ipt} -C FORWARD -o wgdesk -j wgdesk-forward 2>/dev/null || ${ipt} -I FORWARD 1 -o wgdesk -j wgdesk-forward
    ''}
  '';
in {
  networking.wg-quick.interfaces.wgdesk = {
    address = [ net.address ];
    mtu = 1420;
    listenPort = net.port;
    privateKeyFile = "/run/desktop-wireguard/privatekey";
    peers = net.peerConfig;
    postUp = "${firewall} start";
    postDown = "${firewall} stop";
  };
  systemd.services.wg-quick-wgdesk = {
    after = [ "firewall.service" ];
    wants = [ "firewall.service" ];
    preStart = ''
      umask 077
      ${pkgs.age}/bin/age --decrypt -i ${lib.escapeShellArg config.modules.agenix.sshKey} \
        ${config.age.secrets.desktop-wireguard.file} > /run/desktop-wireguard/privatekey.tmp
      mv /run/desktop-wireguard/privatekey.tmp /run/desktop-wireguard/privatekey
    '';
    serviceConfig = {
      RuntimeDirectory = "desktop-wireguard";
      RuntimeDirectoryMode = "0700";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
  networking.firewall.extraCommands = "${firewall} start";
  networking.firewall.extraStopCommands = "${firewall} stop";
  boot.kernel.sysctl = lib.optionalAttrs hub { "net.ipv4.ip_forward" = 1; };
}

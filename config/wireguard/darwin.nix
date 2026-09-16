{ config, lib, pkgs, ... }:
let
  host = config.networking.hostName;
  net = import ./network.nix { inherit lib host; };
  runtime = "/var/run/desktop-wireguard";
  template = pkgs.writeTextDir "wgdesk.conf" ''
    [Interface]
    Address = ${net.address}
    MTU = 1420
    PostUp = ${pkgs.wireguard-tools}/bin/wg set %i private-key ${runtime}/privatekey
    ${lib.concatMapStringsSep "\n" (peer: ''
      [Peer]
      PublicKey = ${peer.publicKey}
      AllowedIPs = ${lib.concatStringsSep ", " peer.allowedIPs}
      Endpoint = ${peer.endpoint}
      PersistentKeepalive = ${toString peer.persistentKeepalive}
    '') net.peerConfig}
  '';
  start = pkgs.writeShellScript "start-desktop-wireguard" ''
    set -eu
    export PATH=${lib.makeBinPath [ pkgs.wireguard-tools pkgs.wireguard-go pkgs.bash pkgs.coreutils ]}:/usr/bin:/bin:/usr/sbin:/sbin
    umask 077
    mkdir -p ${runtime}
    chmod 0700 ${runtime}
    ${pkgs.age}/bin/age --decrypt -i ${lib.escapeShellArg config.modules.agenix.sshKey} \
      ${config.age.secrets.desktop-wireguard.file} > ${runtime}/privatekey.tmp
    mv ${runtime}/privatekey.tmp ${runtime}/privatekey
    exec ${pkgs.wireguard-tools}/bin/wg-quick up ${template}/wgdesk.conf
  '';
in {
  modules.agenix.sshKey = "${config.user.home}/.ssh/id_ed25519";
  launchd.daemons.desktop-wireguard = {
    serviceConfig = {
      Label = "org.nixos.desktop-wireguard";
      ProgramArguments = [ "${start}" ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 5;
      ExitTimeOut = 10;
      StandardOutPath = "/var/log/desktop-wireguard.log";
      StandardErrorPath = "/var/log/desktop-wireguard.log";
    };
  };
  system.build.desktopWireguardConfig = template;
}

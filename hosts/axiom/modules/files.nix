{ config, lib, pkgs, ... }:
let
  net = import ../../../config/wireguard/network.nix { inherit lib; host = "axiom"; };
in {
  imports = [ ../../../config/axiom-files-network.nix ];
  age.secrets.axiom-smb-password = { owner = "root"; mode = "0400"; };
  age.secrets.axiom-files-key = { owner = config.user.name; mode = "0400"; };

  services.samba = {
    enable = true;
    openFirewall = false;
    nmbd.enable = false;
    winbindd.enable = false;
    settings = {
      global = {
        "server string" = "Axiom projects";
        "server min protocol" = "SMB3_00";
        "server smb encrypt" = "required";
        "map to guest" = "Never";
        # Samba rejects non-broadcast interfaces and treats /32 as a network
        # address. A synthetic /24 makes it bind this exact local IP; it does
        # not change WireGuard routes or the single-client access policy.
        "interfaces" = "127.0.0.1 ${net.peers.axiom.ip}/24";
        "bind interfaces only" = "yes";
        "smb ports" = "445";
        "hosts allow" = "127.0.0.1 ${net.peers.charles.ip}";
        "hosts deny" = "ALL";
        "load printers" = "no";
        "disable spoolss" = "yes";
        "fruit:aapl" = "yes";
        # Axiom applications also write these files outside SMB. Kernel oplocks
        # invalidate Mac caches on local writes; SMB leases cannot coordinate
        # those writers and left stale contents in the integration test.
        "kernel oplocks" = "yes";
        "smb2 leases" = "no";
        # Keep loopback P2P sessions from adding slower private WireGuard
        # channels through Samba's interface advertisements.
        "server multi channel support" = "no";
        "smb2 max read" = 1048576;
        "smb2 max write" = 1048576;
      };
      work = {
        path = "${config.user.home}/Work";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = config.user.name;
        "case sensitive" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
        "vfs objects" = "fruit streams_xattr";
        "fruit:metadata" = "stream";
        "fruit:resource" = "file";
        "fruit:veto_appledouble" = "no";
      };
    };
  };

  # Refresh the Samba account from an encrypted secret; plaintext stays in pipes.
  systemd.services.axiom-smb-account = {
    description = "Provision the Axiom SMB account";
    wantedBy = [ "multi-user.target" ];
    before = [ "samba-smbd.service" ];
    after = [ "agenix-install-secrets.service" ];
    restartTriggers = [ ../secrets/axiom-smb-password.age ];
    serviceConfig = { Type = "oneshot"; RemainAfterExit = true; UMask = "0077"; };
    script = ''
      set -eu
      credential=$(cat ${config.age.secrets.axiom-smb-password.path})
      test -n "$credential"
      printf '%s\n%s\n' "$credential" "$credential" | \
        ${config.services.samba.package}/bin/smbpasswd -s -a ${lib.escapeShellArg config.user.name}
      unset credential
    '';
  };
  systemd.services.samba-smbd = {
    after = [ "axiom-smb-account.service" "wg-quick-wgdesk.service" ];
    requires = [ "axiom-smb-account.service" ];
  };

  modules.services.frp = {
    secretNames.FRP_AXIOM_FILES_KEY = "axiom-files-key";
    client.proxies = [{
      name = "axiom-files";
      type = "stcp";
      secretKey = "@FRP_AXIOM_FILES_KEY@";
      localIP = "127.0.0.1";
      localPort = 445;
    } {
      name = "axiom-files-p2p";
      type = "xtcp";
      secretKey = "@FRP_AXIOM_FILES_KEY@";
      localIP = "127.0.0.1";
      localPort = 445;
      natTraversal.disableAssistedAddrs = true;
    }];
    client.extraConfig.natHoleStunServer = "stun.miwifi.com:3478";
  };
  systemd.services.frpc.restartTriggers = [ ../secrets/axiom-files-key.age ];
}

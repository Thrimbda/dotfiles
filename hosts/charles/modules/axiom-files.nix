{ config, lib, pkgs, ... }:
let
  relay = import ../../../config/relay.nix;
  net = import ../../../config/wireguard/network.nix { inherit lib; host = "charles"; };
  tool = pkgs.writeShellScriptBin "axiom-files" ''
    exec ${pkgs.python3}/bin/python3 ${../../../bin/axiom-files.py} \
      --age ${pkgs.age}/bin/age \
      --password-file ${config.age.secrets.axiom-smb-password.file} \
      --identity ${lib.escapeShellArg config.modules.agenix.sshKey} \
      --mountpoint ${lib.escapeShellArg "${config.user.home}/Axiom"} \
      --network-tool ${config.system.build.axiomFilesNetworkTool}/bin/axiom-files-network \
      --frp-log ${lib.escapeShellArg "${config.user.home}/Library/Logs/axiom-files-frpc.log"} \
      --wireguard-host ${net.peers.axiom.ip} "$@"
  '';
in {
  imports = [ ../../../config/axiom-files-network.nix ];
  modules.agenix.sshKey = "${config.user.home}/.ssh/id_ed25519";
  age.secrets.axiom-files-key = { owner = config.user.name; group = "staff"; mode = "0400"; };
  environment.systemPackages = [ tool ];
  system.build.axiomFilesTool = tool;

  modules.services.frp = {
    secretNames.FRP_AXIOM_FILES_KEY = "axiom-files-key";
    client = {
      enable = true;
      darwinUserAgent = true;
      serverAddr = relay.publicIp;
      extraConfig.transport.tls = {
        enable = true;
        trustedCaFile = ../../../config/frp/ant-frps.crt;
        serverName = relay.publicIp;
      };
      extraConfig.natHoleStunServer = "stun.miwifi.com:3478";
      extraConfig.log.disablePrintColor = true;
      visitors = [{
        name = "charles-axiom-files";
        type = "stcp";
        serverName = "axiom-files";
        secretKey = "@FRP_AXIOM_FILES_KEY@";
        bindAddr = "127.0.0.1";
        bindPort = 1445;
      } {
        name = "charles-axiom-files-p2p";
        type = "xtcp";
        serverName = "axiom-files-p2p";
        secretKey = "@FRP_AXIOM_FILES_KEY@";
        bindAddr = "127.0.0.1";
        bindPort = 1446;
        keepTunnelOpen = true;
        minRetryInterval = 10;
        maxRetriesAnHour = 60;
        natTraversal.disableAssistedAddrs = true;
        fallbackTo = "charles-axiom-files";
        fallbackTimeoutMs = 5000;
      }];
    };
  };

  launchd.user.agents.frpc.serviceConfig.StandardOutPath = lib.mkForce "${config.user.home}/Library/Logs/axiom-files-frpc.log";

  launchd.user.agents.axiom-files = {
    serviceConfig = {
      ProgramArguments = [ "${tool}/bin/axiom-files" "--auto" "connect" ];
      RunAtLoad = true;
      StartInterval = 60;
      ProcessType = "Background";
      StandardOutPath = "${config.user.home}/Library/Logs/axiom-files.log";
      StandardErrorPath = "${config.user.home}/Library/Logs/axiom-files.log";
    };
  };
}

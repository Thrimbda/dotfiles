{ hey, config, pkgs, ... }:

let
  facts = import ./_facts.nix;
  acorn = facts.acorn;
  reverseSsh = config.modules.services.reverse-ssh;
  c1ctl = pkgs.callPackage ../../../packages/c1ctl {
    heyBin = "${hey.binDir}/hey";
    autosshRemoteHost = reverseSsh.remoteHost;
    autosshRemoteUser = reverseSsh.remoteUser;
    autosshRemotePort = reverseSsh.remotePort;
    autosshRemoteHostKey = acorn.sshHostKey;
  };
in {
  modules.services.reverse-ssh = {
    enable = true;
    remoteHost = acorn.publicIp;
    remoteUser = "c1";
    serviceHostKey = acorn.sshHostKey;
    knownHostName = "axiom-acorn";
    userKnownHostsFile = "/dev/null";
    remotePort = 2223;
  };

  modules.services.ssh.serviceConfig = {
    MemoryAccounting = true;
    MemoryMin = "32M";
    MemoryLow = "128M";
    OOMPolicy = "continue";
    OOMScoreAdjust = -900;
  };

  environment.systemPackages = [ c1ctl ];

  systemd.targets.axiom-cli = {
    description = "Axiom SSH-friendly CLI mode";
    after = [ "multi-user.target" ];
    requires = [ "multi-user.target" ];
    wants = [ "getty@tty1.service" ];
    conflicts = [ "graphical.target" ];
    unitConfig = {
      AllowIsolate = true;
      Documentation = [ "man:systemd.special(7)" ];
    };
  };
}

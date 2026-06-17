{ hey, lib, config, pkgs, hostSystem ? null, ... }:

with lib;
with hey.lib;
let
  cfg = config.modules.services.reverse-ssh;
  system = if hostSystem != null then hostSystem else pkgs.stdenv.hostPlatform.system;
  isLinux = hasSuffix "-linux" system;
  user = if cfg.user != "" then cfg.user else config.user.name;
  home = if cfg.home != "" then cfg.home else config.user.home;
  remote = "${cfg.remoteUser}@${cfg.remoteHost}";
  remoteForward = "${cfg.remoteBindHost}:${toString cfg.remotePort}:${cfg.localHost}:${toString cfg.localPort}";
  knownHostName = if cfg.knownHostName != "" then cfg.knownHostName else "reverse-ssh-${cfg.remoteHost}";
in {
  options.modules.services.reverse-ssh = with types; {
    enable = mkBoolOpt false;
    serviceName = mkOpt str "autossh-reverse-ssh";
    package = mkOpt package pkgs.autossh;
    user = mkOpt str "";
    home = mkOpt str "";
    remoteHost = mkOpt str "";
    remoteUser = mkOpt str "root";
    remoteHostKey = mkOpt (nullOr str) null;
    knownHostName = mkOpt str "";
    remoteBindHost = mkOpt str "127.0.0.1";
    remotePort = mkOpt int 0;
    localHost = mkOpt str "127.0.0.1";
    localPort = mkOpt int 22;
    restartSec = mkOpt str "5s";
    serviceConfig = mkOpt attrs {};
  };

  config = mkIf (cfg.enable && isLinux) (mkMerge [
    {
      assertions = [
        {
          assertion = cfg.remoteHost != "";
          message = "modules.services.reverse-ssh.remoteHost must be set";
        }
        {
          assertion = cfg.remotePort != 0;
          message = "modules.services.reverse-ssh.remotePort must be set";
        }
      ];

      user.packages = [ cfg.package ];
      services.openssh.startWhenNeeded = mkForce false;

      systemd.services.${cfg.serviceName} = {
        description = "Autossh reverse SSH tunnel to ${cfg.remoteHost}";
        after = [ "network-online.target" "sshd.service" ];
        wants = [ "network-online.target" "sshd.service" ];
        wantedBy = [ "multi-user.target" ];
        unitConfig.StartLimitIntervalSec = 0;
        path = [ pkgs.openssh ];
        environment = {
          AUTOSSH_GATETIME = "0";
          HOME = home;
        };
        serviceConfig = {
          Type = "simple";
          User = user;
          WorkingDirectory = home;
          ExecStart = "${cfg.package}/bin/autossh -M 0 -N -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes -o BatchMode=yes -R ${remoteForward} ${remote}";
          Restart = "always";
          RestartSec = cfg.restartSec;
          MemoryAccounting = true;
          MemoryMin = "32M";
          MemoryLow = "128M";
          OOMPolicy = "stop";
          OOMScoreAdjust = -900;
        } // cfg.serviceConfig;
      };
    }

    (mkIf (cfg.remoteHostKey != null) {
      programs.ssh.knownHosts.${knownHostName} = {
        hostNames = [ cfg.remoteHost ];
        publicKey = cfg.remoteHostKey;
      };
    })
  ]);
}

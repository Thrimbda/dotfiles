# modules/services/clash-meta.nix

{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.services.clash-meta;
    clash-meta = pkgs.clash-meta;
in {
  options.modules.services.clash-meta = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ clash-meta ];

    environment.etc = {
      clash.source = "${hey.configDir}/clash";
    };

    systemd.services.clash-meta = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        LimitNRPC = "500";
        LimitNOFILE = "1000000";
        CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_RAW CAP_NET_BIND_SERVICE CAP_SYS_TIME CAP_SYS_PTRACE CAP_DAC_READ_SEARCH CAP_DAC_OVERRIDE";
        AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_RAW CAP_NET_BIND_SERVICE CAP_SYS_TIME CAP_SYS_PTRACE CAP_DAC_READ_SEARCH CAP_DAC_OVERRIDE";
        Restart = "always";
        ExecStartPre = "${getExe' pkgs.coreutils "sleep"} 1s";
        ExecStart = "${getExe clash-meta} -d /etc/clash";
        ExecReload = "kill -HUP $MAINPID";
      };
    };
  };
}

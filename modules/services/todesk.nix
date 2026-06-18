{ hey, lib, config, pkgs, hostSystem ? null, ... }:

with lib;
with hey.lib;
let
  cfg = config.modules.services.todesk;
  system = if hostSystem != null then hostSystem else pkgs.stdenv.hostPlatform.system;
  isLinux = hasSuffix "-linux" system;
  user = if cfg.user != "" then cfg.user else config.user.name;
  group = if cfg.group != "" then cfg.group else (config.user.group or "users");
  home = if cfg.home != "" then cfg.home else config.user.home;
in {
  options.modules.services.todesk = with types; {
    enable = mkBoolOpt false;
    package = mkOpt package pkgs.todesk;
    user = mkOpt str "";
    group = mkOpt str "";
    home = mkOpt str "";
    stateDir = mkOpt str "/var/lib/todesk";
    restartSec = mkOpt str "5s";
  };

  config = mkIf (cfg.enable && isLinux) {
    user.packages = [ cfg.package ];

    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 0700 ${user} ${group} - -"
    ];

    systemd.services.todesk = {
      description = "ToDesk background service";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = user;
        WorkingDirectory = home;
        ExecStart = "${cfg.package}/bin/todesk service";
        Restart = "on-failure";
        RestartSec = cfg.restartSec;
      };
    };
  };
}

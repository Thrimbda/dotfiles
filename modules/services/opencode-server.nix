{ hey, lib, config, pkgs, hostSystem ? null, ... }:

with lib;
with hey.lib;
let
  cfg = config.modules.services.opencode-server;
  system = if hostSystem != null then hostSystem else pkgs.stdenv.hostPlatform.system;
  isLinux = hasSuffix "-linux" system;
  user = if cfg.user != "" then cfg.user else config.user.name;
  home = if cfg.home != "" then cfg.home else config.user.home;
  opencodeBin = "${cfg.dir}/bin/opencode";
  localUrl = "http://${cfg.bindHost}:${toString cfg.port}";
  publicUrl = "https://${cfg.publicHostname}";
in {
  options.modules.services.opencode-server = with types; {
    enable = mkBoolOpt false;
    serviceName = mkOpt str "opencode-server";
    user = mkOpt str "";
    home = mkOpt str "";
    dir = mkOpt str "${config.user.home}/.opencode";
    workingDirectory = mkOpt str "${config.user.home}";
    bindHost = mkOpt str "127.0.0.1";
    port = mkOpt (ints.between 1 65535) 4096;
    publicHostname = mkOpt (nullOr str) null;
    enableExa = mkBoolOpt true;
    experimental = mkBoolOpt true;
    shellPath.enable = mkBoolOpt true;
    gatus = {
      enable = mkBoolOpt false;
      name = mkOpt str "opencode";
      group = mkOpt str "public";
      interval = mkOpt str "1m";
      conditions = mkOpt (listOf str) [
        "[STATUS] == any(200, 302, 401, 403)"
        "[CERTIFICATE_EXPIRATION] > 336h"
        "[RESPONSE_TIME] < 3000"
      ];
      labels = mkOpt attrs {};
    };
    cloudflared.enable = mkBoolOpt false;
  };

  config = mkIf (cfg.enable && isLinux) (mkMerge [
    {
      systemd.services.${cfg.serviceName} = {
        description = "Opencode server";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        path = [ pkgs.git ];
        environment = {
          HOME = home;
          OPENCODE_ENABLE_EXA = if cfg.enableExa then "1" else "0";
          OPENCODE_EXPERIMENTAL = if cfg.experimental then "true" else "false";
        };
        serviceConfig = {
          Type = "simple";
          User = user;
          WorkingDirectory = cfg.workingDirectory;
          ExecStart = "${opencodeBin} serve --hostname ${cfg.bindHost} --port ${toString cfg.port}";
          Restart = "on-failure";
          RestartSec = "10s";
        };
      };
    }

    (mkIf cfg.shellPath.enable {
      modules.shell.zsh.envInit = mkBefore ''
        path=( "${cfg.dir}/bin" "''${path[@]}" )
        typeset -U path PATH
      '';
    })

    (mkIf (cfg.publicHostname != null && cfg.gatus.enable) {
      modules.services.gatus.endpoints = [{
        name = cfg.gatus.name;
        group = cfg.gatus.group;
        url = publicUrl;
        interval = cfg.gatus.interval;
        conditions = cfg.gatus.conditions;
        extra-labels = cfg.gatus.labels;
      }];
    })

    (mkIf (cfg.publicHostname != null && cfg.cloudflared.enable) {
      modules.services.cloudflared.ingress = [{
        hostname = cfg.publicHostname;
        service = localUrl;
      }];
    })
  ]);
}

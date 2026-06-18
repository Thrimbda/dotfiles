{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.apps.clash-verge;
in {
  options.modules.desktop.apps.clash-verge = with types; {
    enable = mkBoolOpt false;
    package = mkOpt package pkgs.clash-verge-rev;
    servicePolicy = {
      enable = mkBoolOpt false;
      restart = mkOpt str "on-failure";
      restartSec = mkOpt str "5s";
      memoryMin = mkOpt (nullOr str) null;
      memoryLow = mkOpt (nullOr str) null;
      oomPolicy = mkOpt (nullOr str) null;
      oomScoreAdjust = mkOpt (nullOr int) null;
    };
    guiAutostart = {
      enable = mkBoolOpt false;
      serviceName = mkOpt str "app-clash\\x2dverge@autostart";
      restart = mkOpt str "on-failure";
      restartSec = mkOpt str "5s";
      memoryLow = mkOpt (nullOr str) null;
      oomScoreAdjust = mkOpt (nullOr int) null;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      programs.clash-verge = {
        enable = true;
        package = cfg.package;
        serviceMode = true;
        tunMode = true;
        autoStart = true;
      };

      networking.firewall = {
        trustedInterfaces = [ "Mihomo" "Meta" ];
        extraReversePathFilterRules = ''
          iifname { "Mihomo", "Meta" } accept comment "trusted mihomo tun interface"
        '';
      };
    }

    (mkIf cfg.servicePolicy.enable {
      systemd.services.clash-verge.serviceConfig = {
        Restart = mkForce cfg.servicePolicy.restart;
        RestartSec = cfg.servicePolicy.restartSec;
        MemoryAccounting = true;
      } // optionalAttrs (cfg.servicePolicy.memoryMin != null) {
        MemoryMin = cfg.servicePolicy.memoryMin;
      } // optionalAttrs (cfg.servicePolicy.memoryLow != null) {
        MemoryLow = cfg.servicePolicy.memoryLow;
      } // optionalAttrs (cfg.servicePolicy.oomPolicy != null) {
        OOMPolicy = cfg.servicePolicy.oomPolicy;
      } // optionalAttrs (cfg.servicePolicy.oomScoreAdjust != null) {
        OOMScoreAdjust = cfg.servicePolicy.oomScoreAdjust;
      };
    })

    (mkIf cfg.guiAutostart.enable {
      systemd.user.services.${cfg.guiAutostart.serviceName} = {
        overrideStrategy = "asDropin";
        serviceConfig = {
          Restart = cfg.guiAutostart.restart;
          RestartSec = cfg.guiAutostart.restartSec;
          MemoryAccounting = true;
        } // optionalAttrs (cfg.guiAutostart.memoryLow != null) {
          MemoryLow = cfg.guiAutostart.memoryLow;
        } // optionalAttrs (cfg.guiAutostart.oomScoreAdjust != null) {
          OOMScoreAdjust = cfg.guiAutostart.oomScoreAdjust;
        };
      };
    })
  ]);
}

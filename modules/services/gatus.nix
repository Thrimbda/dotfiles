# modules/services/gatus.nix
#
# Gatus status page and black-box monitoring entrypoint.

{ hey, lib, config, options, pkgs, isLinux, ... }:

with lib;
with hey.lib;
let
  cfg = config.modules.services.gatus;
  prometheusCfg = config.modules.services.prometheus;
  gatusUrl = "http://127.0.0.1:${toString cfg.port}";
  settings = recursiveUpdate {
    metrics = true;
    storage = {
      type = "sqlite";
      path = "/var/lib/gatus/gatus.db";
      maximum-number-of-results = 1000;
      maximum-number-of-events = 100;
    };
    web = {
      address = "127.0.0.1";
      port = cfg.port;
    };
    endpoints = cfg.endpoints;
  } cfg.extraSettings;
in {
  options.modules.services.gatus = with types; {
    enable = mkBoolOpt false;
    package = mkOpt package pkgs.gatus;
    port = mkOpt (ints.between 1 65535) 8080;
    domain = mkOpt (nullOr str) null;
    endpoints = mkOpt (listOf attrs) [];
    extraSettings = mkOpt attrs {};

    prometheusScrape = {
      enable = mkBoolOpt false;
      interval = mkOpt str "30s";
    };
  };

  config = mkIf (cfg.enable && isLinux) (mkMerge [
    {
      services.gatus = {
        enable = true;
        package = cfg.package;
        inherit settings;
      };
    }

    (mkIf (cfg.domain != null) {
      services.nginx = {
        enable = true;
        virtualHosts.${cfg.domain} = {
          http2 = true;
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = gatusUrl;
            proxyWebsockets = true;
          };
        };
      };
    })

    (mkIf (cfg.prometheusScrape.enable && prometheusCfg.enable) {
      modules.services.prometheus.scrapeConfigs = [
        {
          job_name = "gatus";
          scrape_interval = cfg.prometheusScrape.interval;
          metrics_path = "/metrics";
          static_configs = [{
            targets = [ "127.0.0.1:${toString cfg.port}" ];
            labels = {
              service = "gatus";
              environment = "production";
            };
          }];
        }
      ];
    })
  ]);
}

# modules/services/gatus.nix
#
# Gatus status page and black-box monitoring entrypoint.

{ hey, lib, config, options, pkgs, hostSystem ? null, ... }:

with lib;
with hey.lib;
let
  cfg = config.modules.services.gatus;
  system = if hostSystem != null then hostSystem else pkgs.stdenv.hostPlatform.system;
  isLinux = hasSuffix "-linux" system;
  prometheusCfg = config.modules.services.prometheus;
  gatusUrl = "http://127.0.0.1:${toString cfg.port}";
  publicEndpointConditions = [
    "[STATUS] == 200"
    "[CERTIFICATE_EXPIRATION] > 336h"
    "[RESPONSE_TIME] < 2000"
  ];
  selfEndpointConditions = [
    "[STATUS] == 200"
    "[RESPONSE_TIME] < 500"
  ];
  endpointLabels = service: extra: cfg.labels // { inherit service; } // extra;
  publicEndpoints = map (endpoint: {
    name = endpoint.name;
    group = endpoint.group;
    url = endpoint.url;
    interval = endpoint.interval;
    conditions = endpoint.conditions;
    extra-labels = endpointLabels endpoint.service endpoint.labels;
  }) cfg.publicEndpoints;
  selfEndpoints = optional cfg.selfEndpoint.enable {
    name = cfg.selfEndpoint.name;
    group = cfg.selfEndpoint.group;
    url = gatusUrl;
    interval = cfg.selfEndpoint.interval;
    conditions = cfg.selfEndpoint.conditions;
    extra-labels = endpointLabels cfg.selfEndpoint.service cfg.selfEndpoint.labels;
  };
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
    endpoints = cfg.endpoints ++ publicEndpoints ++ selfEndpoints;
  } cfg.extraSettings;
in {
  options.modules.services.gatus = with types; {
    enable = mkBoolOpt false;
    package = mkOpt package pkgs.gatus;
    port = mkOpt (ints.between 1 65535) 8080;
    domain = mkOpt (nullOr str) null;
    publicHostname = mkOpt (nullOr str) null;
    labels = mkOpt attrs {};
    endpoints = mkOpt (listOf attrs) [];
    publicEndpoints = mkOpt (listOf (submodule {
      options = {
        name = mkOpt str "";
        service = mkOpt str "";
        group = mkOpt str "public";
        url = mkOpt str "";
        interval = mkOpt str "1m";
        conditions = mkOpt (listOf str) publicEndpointConditions;
        labels = mkOpt attrs {};
      };
    })) [];
    selfEndpoint = {
      enable = mkBoolOpt false;
      name = mkOpt str "status-page";
      service = mkOpt str "gatus";
      group = mkOpt str "infra";
      interval = mkOpt str "1m";
      conditions = mkOpt (listOf str) selfEndpointConditions;
      labels = mkOpt attrs {};
    };
    cloudflared.enable = mkBoolOpt false;
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

    (mkIf (cfg.publicHostname != null && cfg.cloudflared.enable) {
      modules.services.cloudflared.ingress = [{
        hostname = cfg.publicHostname;
        service = gatusUrl;
      }];
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

{ config, ... }:

let
  userName = config.user.name;
in {
  modules.services.prometheus.enable = true;

  modules.services.opencode-server = {
    enable = true;
    publicHostname = "opencode-axiom.0xc1.space";
    gatus = {
      enable = true;
      name = "opencode-axiom";
      labels.service = "opencode";
    };
    cloudflared.enable = true;
  };

  modules.services.gatus = {
    enable = true;
    port = 8080;
    publicHostname = "status-axiom.0xc1.space";
    labels = {
      environment = "production";
      owner = userName;
    };
    prometheusScrape.enable = true;
    cloudflared.enable = true;
    publicEndpoints = [{
      name = "vaultwarden-web";
      service = "vaultwarden";
      url = "https://vault.0xc1.space";
    }];
    selfEndpoint.enable = true;
  };

  modules.services.healthchecks.checks.cloudflared-healthcheck = {
    description = "Cloudflared readiness health check";
    runtimeDirectory = "axiom-healthchecks";
    stateFile = "cloudflared.failures";
    threshold = 3;
    failureMessage = "cloudflared ready check failed";
    restartUnit = "cloudflared.service";
    after = [ "cloudflared.service" ];
    wants = [ "cloudflared.service" ];
    onUnitActiveSec = "45s";
    http.url = "http://127.0.0.1:20241/ready";
  };

  modules.services.cloudflared = {
    enable = true;
    tunnelId = "bc8b3291-de93-4f7f-807a-23f802ef021f";
    tunnelName = "home-axiom";
    credentialsFile = ../secrets/cloudflared-credentials.age;
    warpRouting.enabled = false;
    extraConfig = {
      metrics = "127.0.0.1:20241";
      protocol = "http2";
    };
    ingress = [{ service = "http_status:404"; }];
    servicePolicy = {
      startLimitIntervalSec = 0;
      restart = "always";
      restartSec = "5s";
      memoryAccounting = true;
      memoryMin = "128M";
      memoryLow = "512M";
      oomPolicy = "stop";
      oomScoreAdjust = -850;
    };
  };
}

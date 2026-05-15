{ config, ... }:

let
  gatusPort = config.modules.services.gatus.port;
  publicLabels = service: {
    inherit service;
    environment = "production";
    owner = "c1";
  };
in {
  modules.services.prometheus.enable = true;

  modules.services.gatus = {
    enable = true;
    domain = "status.0xc1.space";
    prometheusScrape.enable = true;

    endpoints = [
      {
        name = "vaultwarden-web";
        group = "public";
        url = "https://vault.0xc1.space";
        interval = "1m";
        conditions = [
          "[STATUS] == 200"
          "[CERTIFICATE_EXPIRATION] > 336h"
          "[RESPONSE_TIME] < 2000"
        ];
        extra-labels = publicLabels "vaultwarden";
      }
      {
        name = "status-page";
        group = "infra";
        url = "http://127.0.0.1:${toString gatusPort}";
        interval = "1m";
        conditions = [
          "[STATUS] == 200"
          "[RESPONSE_TIME] < 500"
        ];
        extra-labels = publicLabels "gatus";
      }
      {
        name = "opencode-axiom";
        group = "public";
        url = "https://opencode-axiom.0xc1.space";
        interval = "1m";
        conditions = [
          "[STATUS] == any(200, 302, 401, 403)"
          "[CERTIFICATE_EXPIRATION] > 336h"
          "[RESPONSE_TIME] < 3000"
        ];
        extra-labels = publicLabels "opencode";
      }
    ];
  };
}

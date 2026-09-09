{ pkgs, ... }:

let
  releaseSha = "20260909T073055Z-31d4517-2752a7527539";
  releaseBinary = "/home/c1/.local/share/we-bot/releases/${releaseSha}/we-bot";
  credentialDir = "/home/c1/.config/we-bot";
  hostName = "notify.0xc1.wang";
  port = 3099;
in
{
  systemd.services.we-bot = {
    description = "Agent notification gateway";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      RUST_LOG = "we_bot=info";
      WE_BOT_ALLOWED_HOSTS = "${hostName},localhost,127.0.0.1";
      WE_BOT_API_TOKEN_FILE = "/run/credentials/we-bot.service/api-token";
      WE_BOT_BIND_ADDR = "127.0.0.1:${toString port}";
      WE_BOT_STATE_PATH = "/var/lib/we-bot/state.json";
    };

    serviceConfig = {
      Type = "simple";
      User = "c1";
      Group = "users";
      WorkingDirectory = "/var/lib/we-bot";
      StateDirectory = "we-bot";
      StateDirectoryMode = "0700";
      ExecStartPre = "${pkgs.coreutils}/bin/test -x ${releaseBinary}";
      ExecStart = releaseBinary;
      LoadCredential = [ "api-token:${credentialDir}/api-token" ];
      Restart = "on-failure";
      RestartSec = "5s";
      UMask = "0077";
      LimitCORE = 0;
      CapabilityBoundingSet = "";
      AmbientCapabilities = "";
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateTmp = true;
      ProtectHome = "read-only";
      ProtectSystem = "strict";
      RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
    };
  };

  services.nginx.virtualHosts.${hostName} = {
    onlySSL = true;
    useACMEHost = hostName;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString port}";
      recommendedProxySettings = false;
      extraConfig = ''
        proxy_http_version 1.1;
        proxy_set_header Host ${hostName};
        proxy_set_header X-Forwarded-Host ${hostName};
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Authorization $http_authorization;
        proxy_request_buffering off;
        proxy_buffering off;
        proxy_cache off;
        proxy_connect_timeout 10s;
        proxy_send_timeout 1h;
        proxy_read_timeout 1h;
        proxy_intercept_errors off;
        proxy_next_upstream off;
        proxy_redirect off;
      '';
    };
  };

  modules.services.nginx.cloudflareDnsAcme.hosts = [ hostName ];
}

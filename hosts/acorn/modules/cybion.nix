{ ... }:

# cybion runs as a manually managed process on 127.0.0.1:1858 (see AGENTS.md deploy
# command for acorn). This module only owns its public ingress: the vhost below and
# the Cloudflare DNS-01 certificate. cybion enforces its own Auth Mini JWT and
# executor token boundaries, so no auth-mini-gateway fronts it.
let
  cybionHost = "cybion.0xc1.wang";
in {
  modules.services.nginx.cloudflareDnsAcme.hosts = [ cybionHost ];

  services.nginx.virtualHosts.${cybionHost} = {
    onlySSL = true;
    useACMEHost = cybionHost;
    extraConfig = ''
      underscores_in_headers on;
      ignore_invalid_headers on;
      client_max_body_size 0;
    '';
    locations."/" = {
      proxyPass = "http://127.0.0.1:1858";
      recommendedProxySettings = false;
      extraConfig = ''
        proxy_http_version 1.1;
        proxy_set_header Host ${cybionHost};
        proxy_set_header X-Forwarded-Host ${cybionHost};
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header Cookie $http_cookie;
        proxy_request_buffering off;
        proxy_buffering off;
        proxy_cache off;
        gzip off;
        proxy_connect_timeout 10s;
        proxy_send_timeout 24h;
        proxy_read_timeout 24h;
        proxy_intercept_errors off;
        proxy_next_upstream off;
        proxy_redirect off;
      '';
    };
  };
}

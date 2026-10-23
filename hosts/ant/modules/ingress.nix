{ config, lib, ... }:
with lib;
let
  gatewayInstances.frps-acorn = {
    hostName = "frps-acorn.0xc1.wang";
    port = 7781;
    dbName = "frps-acorn";
    protectedUpstream = "http://127.0.0.1:7500";
    proxyWebsockets = false;
  };
  gatewayUrl = instance: "http://127.0.0.1:${toString instance.port}";

  gatewayForwardHeaders = ''
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
  '';

  mkGatewayRoute = instance: path: {
    proxyPass = "${gatewayUrl instance}${path}";
    extraConfig = gatewayForwardHeaders;
  };

  mkGatewayRoutes = instance: {
    "= /healthz" = mkGatewayRoute instance "/healthz";
    "= /login" = mkGatewayRoute instance "/login";
    "= /auth/callback" = mkGatewayRoute instance "/auth/callback";
    "= /auth/callback/session" = mkGatewayRoute instance "/auth/callback/session";
    "= /logout" = mkGatewayRoute instance "/logout";
    "= /_auth" = {
      proxyPass = "${gatewayUrl instance}/auth/check";
      extraConfig = ''
        internal;
        proxy_pass_request_body off;
        proxy_set_header Content-Length "";
        proxy_set_header X-Original-URI $request_uri;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header Cookie $http_cookie;
      '';
    };
  };

  mkProtectedLocations = instance: optionalAttrs (instance.protectedUpstream != null) {
    "= /__auth_mini_login_redirect" = {
      proxyPass = "${gatewayUrl instance}/login";
      extraConfig = gatewayForwardHeaders + ''
        internal;
        proxy_set_header X-Original-URI $request_uri;
      '';
    };
    "@auth_mini_forbidden".extraConfig = ''
      return 403 "Forbidden\n";
    '';
    "/" = {
      proxyPass = instance.protectedUpstream;
      proxyWebsockets = instance.proxyWebsockets;
      extraConfig = ''
        auth_request /_auth;
        auth_request_set $auth_user_id $upstream_http_x_auth_mini_user_id;
        auth_request_set $auth_email $upstream_http_x_auth_mini_email;
        error_page 401 = /__auth_mini_login_redirect;
        error_page 403 = @auth_mini_forbidden;
        proxy_set_header Cookie "";
        proxy_set_header X-Auth-Mini-User-Id $auth_user_id;
        proxy_set_header X-Auth-Mini-Email $auth_email;
        ${instance.protectedExtraConfig or ""}
      '';
    };
  };

  mkRunEnvironmentPeerLocation = instance: path: {
    proxyPass = "${instance.runEnvironmentUpstream}${path}";
    proxyWebsockets = false;
    extraConfig = instance.runEnvironmentPeerExtraConfig or "";
  };

  mkRunEnvironmentPeerLocations = instance:
    optionalAttrs (instance ? runEnvironmentUpstream) {
      "= /api/run-environments/pair" =
        mkRunEnvironmentPeerLocation instance "/api/run-environments/pair";
      "= /api/run-environments/connect" =
        mkRunEnvironmentPeerLocation instance "/api/run-environments/connect";
      "= /api/run-environments/heartbeats" =
        mkRunEnvironmentPeerLocation instance "/api/run-environments/heartbeats";
      "= /api/run-environments/tool-results" =
        mkRunEnvironmentPeerLocation instance "/api/run-environments/tool-results";
    };

  mkGatewayVhost = instance: {
    onlySSL = true;
    useACMEHost = instance.hostName;
    locations = mkGatewayRoutes instance // mkRunEnvironmentPeerLocations instance // mkProtectedLocations instance // optionalAttrs (instance.protectedUpstream == null) {
      "/".extraConfig = ''
        return 404 "Not found\n";
      '';
    };
  } // optionalAttrs (instance ? vhostExtraConfig) {
    extraConfig = instance.vhostExtraConfig;
  };

  # lol.0xc1.wang: the gateway runs here in adapter mode, so one session covers both backends.
  # Research replays come from Axiom (frp 18083, lol-replay-server), the live view and the
  # watchlist from the lol-live instance on AWS (frp 18084). Neither backend authenticates; their
  # frps ports are closed in the firewall (platform.nix), so only this nginx reaches them.
  # Rollback of the live paths to Axiom, effective on the next request (no reload):
  #   sudo touch /var/lib/lol-ingress/live-on-axiom     (undo: sudo rm it)
  # Axiom must have its live view enabled (LIVE_TAP) for that to serve anything.
  lol = {
    hostName = "lol.0xc1.wang";
    port = 7782;
    replayUpstream = "http://127.0.0.1:18083";
    liveUpstream = "http://127.0.0.1:18084";
    liveOnAxiomFlag = "/var/lib/lol-ingress/live-on-axiom";
  };

  lolGateway = lol // { protectedUpstream = null; };

  lolProtected = upstream: {
    proxyPass = upstream;
    recommendedProxySettings = false;
    extraConfig = ''
      auth_request /_auth;
      error_page 401 = /__auth_mini_login_redirect;
      error_page 403 = @auth_mini_forbidden;
      proxy_http_version 1.1;
      proxy_set_header Host ${lol.hostName};
      proxy_set_header X-Forwarded-Proto https;
      proxy_set_header X-Forwarded-For $remote_addr;
      proxy_set_header Cookie "";
      proxy_set_header Connection "";
      proxy_request_buffering off;
      # Live SSE streams: pass through unbuffered and keep them open.
      proxy_buffering off;
      proxy_cache off;
      gzip off;
      proxy_connect_timeout 10s;
      proxy_send_timeout 24h;
      proxy_read_timeout 24h;
      proxy_next_upstream off;
      proxy_redirect off;
    '';
  };

  lolVhost = {
    onlySSL = true;
    useACMEHost = lol.hostName;
    extraConfig = ''
      client_max_body_size 1m;
      set $lol_live ${lol.liveUpstream};
      if (-f ${lol.liveOnAxiomFlag}) {
        set $lol_live ${lol.replayUpstream};
      }
    '';
    locations = mkGatewayRoutes lolGateway // {
      "= /__auth_mini_login_redirect" = {
        proxyPass = "${gatewayUrl lolGateway}/login";
        extraConfig = gatewayForwardHeaders + ''
          internal;
          proxy_set_header X-Original-URI $request_uri;
        '';
      };
      "@auth_mini_forbidden".extraConfig = ''
        return 403 "This account has no access to lol.0xc1.wang\n";
      '';
      "/" = lolProtected lol.replayUpstream;
      # Every live and watchlist route of replay-server (src/main.rs).
      "^~ /live/" = lolProtected "$lol_live";
      "= /api/wallets" = lolProtected "$lol_live";
      "^~ /api/wallets/" = lolProtected "$lol_live";
    };
  };

  mkNodeProxyVhost = hostName: remotePort: extraLocationConfig: {
    onlySSL = true;
    useACMEHost = hostName;
    extraConfig = ''
      underscores_in_headers on;
      ignore_invalid_headers on;
      client_max_body_size 0;
    '';
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString remotePort}";
      recommendedProxySettings = false;
      extraConfig = ''
        proxy_http_version 1.1;
        proxy_set_header Host ${hostName};
        proxy_set_header X-Forwarded-Host ${hostName};
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header Cookie $http_cookie;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
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
        ${extraLocationConfig}
      '';
    };
  };

in {
  modules.services.nginx = {
    enable = true;
    cloudflareDnsAcme = {
      enable = true;
      email = "siyuan.arc@gmail.com";
      credentialsFile = ../secrets/cloudflare-dns.env.age;
      hosts = [ "status-axiom.0xc1.wang" "opencode-axiom.0xc1.wang" "frps-acorn.0xc1.wang" "lol.0xc1.wang" ];
    };
  };
  modules.services.auth-mini-gateway = {
    enable = true;
    instances = mapAttrs (_: instance: {
      publicHost = instance.hostName;
      inherit (instance) port;
      stateDirectory = "auth-mini-gateway";
      stateDirectoryMode = "0750";
      databaseFile = "${instance.dbName}.sqlite";
    }) gatewayInstances // {
      lol-replay = {
        publicHost = lol.hostName;
        inherit (lol) port;
        stateDirectory = "auth-mini-gateway";
        stateDirectoryMode = "0750";
        databaseFile = "lol-replay.sqlite";
        # Own cookie secret and the allowlist c1@ntnl.io, siyuan.arc@gmail.com, froggy2818@gmail.com.
        environmentFiles = [ config.age.secrets.lol-replay-gateway-env.path ];
        extraEnvironment = {
          SESSION_ABSOLUTE_TTL_SECONDS = "2592000";
          SESSION_TOUCH_INTERVAL_SECONDS = "3600";
        };
      };
    };
  };
  age.secrets.lol-replay-gateway-env = {
    owner = config.modules.services.auth-mini-gateway.user;
    group = config.modules.services.auth-mini-gateway.user;
    mode = "0400";
  };
  # Holds the live-on-axiom rollback flag; nginx only reads it.
  systemd.tmpfiles.rules = [ "d /var/lib/lol-ingress 0755 root root -" ];
  services.nginx.virtualHosts = mapAttrs' (_: instance:
    nameValuePair instance.hostName (mkGatewayVhost instance)) gatewayInstances // {
    "status-axiom.0xc1.wang" = mkNodeProxyVhost "status-axiom.0xc1.wang" 18080 "";
    "opencode-axiom.0xc1.wang" = mkNodeProxyVhost "opencode-axiom.0xc1.wang" 18081 "";
    "lol.0xc1.wang" = lolVhost;
  };
}

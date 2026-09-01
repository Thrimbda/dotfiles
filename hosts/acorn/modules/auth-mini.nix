{ lib, pkgs, ... }:

with lib;

let
  authMiniPackage = pkgs.callPackage ../../../packages/auth-mini {};

  authUser = "auth-mini";
  authHost = "auth.0xc1.wang";
  authPort = 7777;
  authUrl = "http://127.0.0.1:${toString authPort}";

  gatewayInstances = {
    auth-gateway = {
      hostName = "auth-gateway.0xc1.wang";
      port = 7778;
      dbName = "auth-gateway";
      protectedUpstream = null;
      proxyWebsockets = false;
    };
    frps-acorn = {
      hostName = "frps-acorn.0xc1.wang";
      port = 7781;
      dbName = "frps-acorn";
      protectedUpstream = "http://127.0.0.1:7500";
      proxyWebsockets = false;
    };
    constx = {
      hostName = "constx.0xc1.wang";
      port = 7782;
      dbName = "constx";
      protectedUpstream = "http://127.0.0.1:3210";
      proxyWebsockets = false;
      vhostExtraConfig = ''
        client_max_body_size 22m;
      '';
      protectedExtraConfig = ''
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
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

  mkGatewayVhost = instance: {
    onlySSL = true;
    useACMEHost = instance.hostName;
    locations = mkGatewayRoutes instance // mkProtectedLocations instance // optionalAttrs (instance.protectedUpstream == null) {
      "/".extraConfig = ''
        return 404 "Not found\n";
      '';
    };
  } // optionalAttrs (instance ? vhostExtraConfig) {
    extraConfig = instance.vhostExtraConfig;
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

in

{
  users.groups.${authUser} = {};

  users.users.${authUser} = {
    isSystemUser = true;
    group = authUser;
    home = "/var/lib/${authUser}";
  };

  modules.services.auth-mini-gateway = {
    enable = true;
    instances = mapAttrs (_: instance: {
      publicHost = instance.hostName;
      inherit (instance) port;
      dependencies = [ "auth-mini.service" ];
      stateDirectory = "auth-mini-gateway";
      stateDirectoryMode = "0750";
      databaseFile = "${instance.dbName}.sqlite";
    }) gatewayInstances;
  };

  modules.services.nginx.cloudflareDnsAcme.hosts = [
    authHost
    "status-axiom.0xc1.wang"
    "opencode-axiom.0xc1.wang"
    "pi-axiom.0xc1.wang"
  ] ++ mapAttrsToList (_: instance: instance.hostName) gatewayInstances;

  age.secrets.auth-mini-resend-api-key = {
    owner = authUser;
    group = authUser;
    mode = "0400";
  };

  systemd.services.auth-mini = {
    description = "auth-mini authentication server";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      User = authUser;
      Group = authUser;
      ExecStart = "${authMiniPackage}/bin/auth-mini --host 127.0.0.1 --port ${toString authPort} --db /var/lib/${authUser}/auth-mini.sqlite";
      Restart = "on-failure";
      RestartSec = "5s";
      StateDirectory = authUser;
      StateDirectoryMode = "0750";
      WorkingDirectory = "/var/lib/${authUser}";
      ReadWritePaths = [ "/var/lib/${authUser}" ];
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
    };
  };

  # SameSite cookies do not prevent sibling-origin WebSocket handshakes.
  services.nginx.commonHttpConfig = ''
    map "$http_upgrade:$http_origin" $pi_axiom_websocket_origin_rejected {
      default 0;
      ~*^websocket:https://pi-axiom\.0xc1\.wang$ 0;
      ~*^websocket: 1;
    }
  '';

  services.nginx.virtualHosts = {
    ${authHost} = {
      onlySSL = true;
      useACMEHost = authHost;
      locations = {
        "= /".extraConfig = ''
          return 302 /web/;
        '';
        "/" = {
          proxyPass = authUrl;
          proxyWebsockets = true;
        };
      };
    };
  } // mapAttrs' (_: instance: nameValuePair instance.hostName (mkGatewayVhost instance)) gatewayInstances // {
    "status-axiom.0xc1.wang" = mkNodeProxyVhost "status-axiom.0xc1.wang" 18080 "";
    "opencode-axiom.0xc1.wang" = mkNodeProxyVhost "opencode-axiom.0xc1.wang" 18081 "";
    "pi-axiom.0xc1.wang" = mkNodeProxyVhost "pi-axiom.0xc1.wang" 18082 ''
      if ($pi_axiom_websocket_origin_rejected) {
        return 403;
      }
    '';
  };
}

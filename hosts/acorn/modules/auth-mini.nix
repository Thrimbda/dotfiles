{ config, lib, pkgs, ... }:

with lib;

let
  authMiniPackage = pkgs.callPackage ../../../packages/auth-mini {};
  gatewayPackage = pkgs.callPackage ../../../packages/auth-mini-gateway {};

  authUser = "auth-mini";
  gatewayUser = "auth-mini-gateway";
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
    status-axiom = {
      hostName = "status-axiom.0xc1.wang";
      port = 7779;
      dbName = "status-axiom";
      protectedUpstream = "http://127.0.0.1:18080";
      proxyWebsockets = true;
    };
    opencode-axiom = {
      hostName = "opencode-axiom.0xc1.wang";
      port = 7780;
      dbName = "opencode-axiom";
      protectedUpstream = "http://127.0.0.1:18081";
      proxyWebsockets = true;
    };
    frps-acorn = {
      hostName = "frps-acorn.0xc1.wang";
      port = 7781;
      dbName = "frps-acorn";
      protectedUpstream = "http://127.0.0.1:7500";
      proxyWebsockets = false;
    };
  };

  acmeCert = {
    dnsProvider = "cloudflare";
    environmentFile = config.age.secrets.cloudflare-dns-env.path;
    group = "nginx";
    reloadServices = [ "nginx.service" ];
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
  };

  mkGatewayService = name: instance: {
    description = "auth-mini gateway for ${instance.hostName}";
    after = [ "network-online.target" "auth-mini.service" ];
    wants = [ "network-online.target" "auth-mini.service" ];
    wantedBy = [ "multi-user.target" ];
    environment = {
      HOST = "127.0.0.1";
      PORT = toString instance.port;
      GATEWAY_PUBLIC_BASE_URL = "https://${instance.hostName}";
      AUTH_MINI_ISSUER = "https://${authHost}";
      AUTH_MINI_PUBLIC_BASE_URL = "https://${authHost}";
      GATEWAY_DB = "/var/lib/${gatewayUser}/${instance.dbName}.sqlite";
      COOKIE_SECURE = "true";
      COOKIE_SAME_SITE = "lax";
      SESSION_TTL_SECONDS = "28800";
      LOGIN_STATE_TTL_SECONDS = "300";
      REFRESH_SKEW_SECONDS = "60";
      LOGOUT_REDIRECT = "/";
    };
    serviceConfig = {
      Type = "simple";
      User = gatewayUser;
      Group = gatewayUser;
      EnvironmentFile = config.age.secrets.auth-mini-gateway-env.path;
      ExecStart = "${gatewayPackage}/bin/auth-mini-gateway";
      Restart = "on-failure";
      RestartSec = "5s";
      StateDirectory = gatewayUser;
      StateDirectoryMode = "0750";
      WorkingDirectory = "/var/lib/${gatewayUser}";
      ReadWritePaths = [ "/var/lib/${gatewayUser}" ];
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
    };
  };
in

{
  users.groups = {
    ${authUser} = {};
    ${gatewayUser} = {};
  };

  users.users = {
    ${authUser} = {
      isSystemUser = true;
      group = authUser;
      home = "/var/lib/${authUser}";
    };
    ${gatewayUser} = {
      isSystemUser = true;
      group = gatewayUser;
      home = "/var/lib/${gatewayUser}";
    };
  };

  age.secrets.auth-mini-gateway-env = {
    owner = gatewayUser;
    group = gatewayUser;
    mode = "0400";
  };

  systemd.services = {
    auth-mini = {
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
  } // mapAttrs' (name: instance: nameValuePair "auth-mini-gateway-${name}" (mkGatewayService name instance)) gatewayInstances;

  services.nginx.virtualHosts = {
    ${authHost} = {
      onlySSL = true;
      useACMEHost = authHost;
      locations."/" = {
        proxyPass = authUrl;
        proxyWebsockets = true;
      };
    };
  } // mapAttrs' (_: instance: nameValuePair instance.hostName (mkGatewayVhost instance)) gatewayInstances;

  security.acme.certs = {
    ${authHost} = acmeCert;
    "auth-gateway.0xc1.wang" = acmeCert;
  };
}

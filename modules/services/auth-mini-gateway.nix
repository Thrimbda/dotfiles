{ hey, lib, config, pkgs, ... }:

with lib;
with hey.lib;
let
  cfg = config.modules.services.auth-mini-gateway;
  mkService = instance:
    let
      dependencies = instance.dependencies or [];
      stateDirectory = instance.stateDirectory or cfg.user;
      stateDirectoryMode = instance.stateDirectoryMode or "0700";
      databaseFile = instance.databaseFile or "gateway.sqlite";
      environment = {
        HOST = "127.0.0.1";
        PORT = toString instance.port;
        GATEWAY_PUBLIC_BASE_URL = "https://${instance.publicHost}";
        AUTH_MINI_ISSUER = cfg.issuer;
        AUTH_MINI_PUBLIC_BASE_URL = cfg.issuer;
        GATEWAY_DB = "/var/lib/${stateDirectory}/${databaseFile}";
        COOKIE_SECURE = "true";
        COOKIE_SAME_SITE = "lax";
        SESSION_TTL_SECONDS = "28800";
        LOGIN_STATE_TTL_SECONDS = "300";
        REFRESH_SKEW_SECONDS = "60";
        LOGOUT_REDIRECT = "/";
      }
      // optionalAttrs (instance ? upstreamUrl) {
        UPSTREAM_URL = instance.upstreamUrl;
      }
      // optionalAttrs (instance ? upstreamProtocol) {
        UPSTREAM_PROTOCOL = instance.upstreamProtocol;
      }
      // (instance.extraEnvironment or {});
    in {
      description = "auth-mini gateway for ${instance.publicHost}";
      after = [ "network-online.target" ] ++ dependencies;
      wants = [ "network-online.target" ] ++ dependencies;
      wantedBy = [ "multi-user.target" ];
      inherit environment;
      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.user;
        EnvironmentFile = config.age.secrets.auth-mini-gateway-env.path;
        ExecStart = "${cfg.package}/bin/auth-mini-gateway";
        Restart = "on-failure";
        RestartSec = "5s";
        StateDirectory = stateDirectory;
        StateDirectoryMode = stateDirectoryMode;
        WorkingDirectory = "/var/lib/${stateDirectory}";
        ReadWritePaths = [ "/var/lib/${stateDirectory}" ];
        UMask = "0077";
        LimitNOFILE = 4096;
        LimitCORE = 0;
        CapabilityBoundingSet = "";
        AmbientCapabilities = "";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
      };
    };
in {
  options.modules.services.auth-mini-gateway = with types; {
    enable = mkBoolOpt false;
    package = mkOpt package hey.packages.auth-mini-gateway;
    user = mkOpt str "auth-mini-gateway";
    issuer = mkOpt str "https://auth.0xc1.wang";
    instances = mkOpt attrs {};
  };

  config = mkIf cfg.enable {
    assertions = mapAttrsToList (name: instance: {
      assertion = instance ? publicHost && instance ? port;
      message = "modules.services.auth-mini-gateway.instances.${name} requires publicHost and port";
    }) cfg.instances;

    users.groups.${cfg.user} = {};
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.user;
      home = "/var/lib/${cfg.user}";
    };

    age.secrets.auth-mini-gateway-env = {
      owner = cfg.user;
      group = cfg.user;
      mode = "0400";
    };

    systemd.services = mapAttrs' (name: instance:
      nameValuePair "auth-mini-gateway-${name}" (mkService instance)
    ) cfg.instances;
  };
}

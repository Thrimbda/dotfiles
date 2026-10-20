{ config, pkgs, ... }:

# LoL replay workbench at lol.0xc1.wang, for C1's own research.
# The server reads research data live from the repository; releases of the binary and
# frontend come from laugh-out-loud/replay-server/release.sh into appRoot.
# Path: Ant nginx (TLS) -> frps 18083 -> frpc -> gateway 7783 -> server 7790.
let
  userName = config.user.name;
  repo = "${config.user.home}/Work/laugh-out-loud";
  appRoot = "/var/lib/lol-replay/app";
  serverPort = 7790;
  gatewayPort = 7783;
  gatewayEnvironment = {
    GATEWAY_MAX_DOWNSTREAM_CONNECTIONS = "256";
    GATEWAY_MAX_ACTIVE_UPSTREAMS = "128";
    GATEWAY_MAX_BLOCKING_RESOLVERS = "8";
    TRUSTED_PROXY_CIDRS = "";
    SESSION_ABSOLUTE_TTL_SECONDS = "2592000";
    SESSION_TOUCH_INTERVAL_SECONDS = "3600";
  };
in {
  # Own cookie secret and an allowlist of c1@ntnl.io only, overriding the shared file.
  age.secrets.lol-replay-gateway-env = {
    owner = config.modules.services.auth-mini-gateway.user;
    group = config.modules.services.auth-mini-gateway.user;
    mode = "0400";
  };

  # release.sh runs as the user and needs the directory before the first start.
  systemd.tmpfiles.rules = [ "d ${appRoot} 0755 ${userName} users -" ];

  systemd.services.lol-replay = {
    description = "LoL replay workbench server";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    # Nothing to run until the first release is installed.
    unitConfig.ConditionPathExists = "${appRoot}/current/bin/lol-replay-server";
    environment = {
      REPLAY_LISTEN = "127.0.0.1:${toString serverPort}";
      REPLAY_ROOT = repo;
      REPLAY_DIST = "${appRoot}/current/dist";
      REPLAY_CACHE = "/var/cache/lol-replay";
      RUST_LOG = "info";
    };
    serviceConfig = {
      Type = "simple";
      User = userName;
      ExecStart = "${appRoot}/current/bin/lol-replay-server";
      Restart = "on-failure";
      RestartSec = "5s";
      CacheDirectory = "lol-replay";
      UMask = "0027";
      # Reads the repository and releases; writes only its cache.
      ProtectHome = "read-only";
      ProtectSystem = "strict";
      PrivateTmp = true;
      PrivateDevices = true;
      NoNewPrivileges = true;
      CapabilityBoundingSet = "";
      AmbientCapabilities = "";
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
      RestrictNamespaces = true;
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      SystemCallArchitectures = "native";
      SystemCallFilter = [ "@system-service" ];
      LimitNOFILE = 4096;
      LimitCORE = 0;
    };
  };

  # release.sh renames a new `current` into appRoot; restarting here keeps releases
  # sudo-free. The directory is watched because replacing an existing symlink does
  # not trigger PathChanged on the link itself.
  systemd.paths.lol-replay-release = {
    wantedBy = [ "multi-user.target" ];
    pathConfig = {
      PathChanged = appRoot;
      Unit = "lol-replay-restart.service";
    };
  };
  systemd.services.lol-replay-restart = {
    description = "Restart the LoL replay server on a new release";
    serviceConfig.Type = "oneshot";
    script = "${pkgs.systemd}/bin/systemctl restart lol-replay.service";
  };

  modules.services.auth-mini-gateway.instances.lol-replay = {
    publicHost = "lol.0xc1.wang";
    port = gatewayPort;
    upstreamUrl = "http://127.0.0.1:${toString serverPort}";
    upstreamProtocol = "http1";
    dependencies = [ "lol-replay.service" ];
    stateDirectory = "auth-mini-gateway-lol-replay";
    environmentFiles = [ config.age.secrets.lol-replay-gateway-env.path ];
    extraEnvironment = gatewayEnvironment;
  };

  modules.services.frp.client.proxies = [{
    name = "axiom-lol-replay-http";
    type = "tcp";
    localIP = "127.0.0.1";
    localPort = gatewayPort;
    remotePort = 18083;
  }];
  systemd.services.frpc = {
    after = [ "auth-mini-gateway-lol-replay.service" ];
    wants = [ "auth-mini-gateway-lol-replay.service" ];
  };

  modules.services.gatus = {
    endpoints = [{
      name = "lol-replay";
      group = "internal";
      url = "http://127.0.0.1:${toString serverPort}/healthz";
      interval = "1m";
      conditions = [ "[STATUS] == 200" "[BODY].ok == true" ];
      extra-labels = config.modules.services.gatus.labels // { service = "lol-replay"; };
    }];
    # Anonymous requests follow the gateway's login redirect: this checks TLS, the
    # tunnel and the gateway, not the data behind them.
    publicEndpoints = [{
      name = "lol-replay-web";
      service = "lol-replay";
      url = "https://lol.0xc1.wang/";
    }];
  };
}

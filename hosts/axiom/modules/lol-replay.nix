{ config, pkgs, ... }:

# LoL replay workbench at lol.0xc1.wang, for C1's own research.
# The server reads research data live from the repository; releases of the binary and
# frontend come from laugh-out-loud/replay-server/release.sh into appRoot.
# Path: Ant nginx (TLS) -> frps 18083 -> frpc -> gateway 7783 -> server 7790.
#
# Live view: oracle-trader runs on the GRID Hub host (AWS eu-west-1, i-089e6a0595feb271b) and
# trader-tap serves its journal directory read-only on that host's 127.0.0.1:17790. The tunnel
# below forwards it to 127.0.0.1:17791 here through SSM (outbound only, no inbound port on the
# Hub host); the server mirrors the files into liveMirror and streams them to the browser.
# The tunnel's IAM user (lol-live-tunnel) may only start sessions of the SSM document
# NTNL-LolLiveTapForward, whose remote port is fixed to 17790, on that one instance.
let
  userName = config.user.name;
  repo = "${config.user.home}/Work/laugh-out-loud";
  appRoot = "/var/lib/lol-replay/app";
  serverPort = 7790;
  liveMirror = "/var/lib/lol-replay/live";
  tapLocalPort = 17791;
  hubInstance = "i-089e6a0595feb271b";
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
  # Own cookie secret and an allowlist of c1@ntnl.io and siyuan.arc@gmail.com,
  # overriding the shared file.
  age.secrets.lol-replay-gateway-env = {
    owner = config.modules.services.auth-mini-gateway.user;
    group = config.modules.services.auth-mini-gateway.user;
    mode = "0400";
  };

  # AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY / AWS_REGION of IAM user lol-live-tunnel; read by
  # systemd before it drops to the tunnel's dynamic user.
  age.secrets.lol-live-tunnel-aws = {
    owner = "root";
    mode = "0400";
  };

  # release.sh runs as the user and needs the directory before the first start.
  systemd.tmpfiles.rules = [
    "d ${appRoot} 0755 ${userName} users -"
    "d ${liveMirror} 0750 ${userName} users -"
    # Watched wallets' live fills (replay-server's wallet poller), kept beside the mirror.
    "d ${liveMirror}-wallets 0750 ${userName} users -"
  ];

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
      LIVE_TAP = "127.0.0.1:${toString tapLocalPort}";
      LIVE_MIRROR = liveMirror;
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
      # Reads the repository and releases; writes only its cache, the live mirror and its wallets file.
      ProtectHome = "read-only";
      ProtectSystem = "strict";
      ReadWritePaths = [ liveMirror "${liveMirror}-wallets" ];
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

  # SSM port forward to trader-tap on the GRID Hub host. Restarts by itself when a session ends;
  # the server reconnects to it on its own and resumes from its mirror's sizes.
  systemd.services.lol-live-tunnel = {
    description = "SSM port forward to trader-tap on the GRID Hub host (127.0.0.1:${toString tapLocalPort})";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.awscli2 pkgs.ssm-session-manager-plugin ];
    environment = {
      AWS_CONFIG_FILE = "/dev/null";
      AWS_SHARED_CREDENTIALS_FILE = "/dev/null";
      HOME = "/tmp";
    };
    serviceConfig = {
      Type = "simple";
      DynamicUser = true;
      EnvironmentFile = config.age.secrets.lol-live-tunnel-aws.path;
      ExecStart = "${pkgs.awscli2}/bin/aws ssm start-session --target ${hubInstance} --document-name NTNL-LolLiveTapForward --parameters localPortNumber=${toString tapLocalPort}";
      Restart = "always";
      RestartSec = "5s";
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      PrivateDevices = true;
      NoNewPrivileges = true;
      CapabilityBoundingSet = "";
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" "AF_NETLINK" ];
      RestrictNamespaces = true;
      LockPersonality = true;
      SystemCallArchitectures = "native";
      MemoryMax = "256M";
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

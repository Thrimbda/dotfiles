{ config, pkgs, ... }:

# LoL replay workbench at lol.0xc1.wang, for C1's own research.
# The server reads research data live from the repository; releases of the binary and
# frontend come from laugh-out-loud/replay-server/release.sh into appRoot.
# Path: Ant nginx (TLS) -> frps 18083 -> frpc -> gateway 7783 -> server 7790.
#
# Live view: not here. lol.0xc1.space (the lol-live instance on AWS, behind Cloudflare; laugh-out-loud
# replay-server/deploy/aws) mirrors trader-tap and serves the live view, the watchlist and the Worlds
# oracle replays, which lol-worlds-push below keeps in S3 for it. Without LIVE_TAP this server answers
# /live/* with 404; the old mirror (/var/lib/lol-replay/live) and watchlist stay on disk, unused.
let
  userName = config.user.name;
  repo = "${config.user.home}/Work/laugh-out-loud";
  appRoot = "/var/lib/lol-replay/app";
  serverPort = 7790;
  liveMirror = "/var/lib/lol-replay/live";
  worldsDir = "${repo}/research/replay/out/worlds";
  worldsS3 = "s3://ntnl-oracle-trader-prod-deploy-524909477426-eu-west-1/lol-live-data/worlds";
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
  # Own cookie secret and an allowlist of c1@ntnl.io, siyuan.arc@gmail.com and
  # froggy2818@gmail.com, overriding the shared file.
  age.secrets.lol-replay-gateway-env = {
    owner = config.modules.services.auth-mini-gateway.user;
    group = config.modules.services.auth-mini-gateway.user;
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

  # Worlds oracle replays for lol.0xc1.space: the lol-live instance on AWS pulls them from S3
  # (laugh-out-loud replay-server/deploy/aws). Pushed whenever worlds_oracle.py rewrites the
  # manifest; files first, manifest last. IAM user lol-worlds-push may only write that prefix.
  age.secrets.lol-worlds-push-aws = {
    owner = "root";
    mode = "0400";
  };
  systemd.paths.lol-worlds-push = {
    wantedBy = [ "multi-user.target" ];
    pathConfig = {
      PathChanged = "${worldsDir}/manifest.json";
      Unit = "lol-worlds-push.service";
    };
  };
  systemd.services.lol-worlds-push = {
    description = "Push the Worlds oracle replays to S3 for lol.0xc1.space";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [ pkgs.awscli2 ];
    environment = {
      AWS_CONFIG_FILE = "/dev/null";
      AWS_SHARED_CREDENTIALS_FILE = "/dev/null";
      HOME = "/tmp";
    };
    script = ''
      # worlds_oracle.py writes the manifest after the files; let it finish.
      sleep 10
      aws s3 sync --only-show-errors --delete --exclude manifest.json ${worldsDir}/ ${worldsS3}/
      aws s3 cp --only-show-errors ${worldsDir}/manifest.json ${worldsS3}/manifest.json
    '';
    serviceConfig = {
      Type = "oneshot";
      # Reads the repository under the user's home.
      User = userName;
      EnvironmentFile = config.age.secrets.lol-worlds-push-aws.path;
      Restart = "on-failure";
      RestartSec = "60s";
      ProtectHome = "read-only";
      ProtectSystem = "strict";
      PrivateTmp = true;
      NoNewPrivileges = true;
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

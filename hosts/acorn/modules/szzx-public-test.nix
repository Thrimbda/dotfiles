{ pkgs, ... }:

# SZzX mini program public test backend: mock HIS patients (HIS_MODE=fixture)
# behind real WeChat login, for testing the patient mini program on phones.
# Guide: docs/iterations/08-launch-readiness/public-test-environment.md in the
# szzx-mini-program repository. Test data only; never promote this to production.
#
# Not managed here (written on the host, outside the store):
# - /opt/szzx/releases/<sha>/  backend binaries built on Axiom (cargo build --release);
#   /opt/szzx/current points at the active release.
# - /opt/szzx/admin/current     admin frontend build (frontend/dist).
# - /etc/szzx/backend.env       root:szzx 0640; WeChat AppSecret and generated keys.
# - /etc/szzx/mock/             cycles-source.json fixture copied from the repository.
# The service stays inactive until both the env file and the binary exist.
#
# Operator commands run as the service user with the same environment, e.g.:
#   sudo -u szzx sh -c 'set -a; . /etc/szzx/backend.env; set +a; exec /opt/szzx/current/szzx-migrate info'
let
  hostName = "szzx-test.0xc1.wang";
  port = 3000;
  id = 20001;
  current = "/opt/szzx/current";
  envFile = "/etc/szzx/backend.env";
  mediaRoot = "/mnt/szzx/media";
  exportRoot = "/srv/szzx/media-data";
  backend = "http://127.0.0.1:${toString port}";
  apiProxy = ''
    proxy_http_version 1.1;
    proxy_set_header Connection "";
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto https;
  '';
in
{
  users.groups.szzx.gid = id;
  users.users.szzx = {
    isSystemUser = true;
    uid = id;
    group = "szzx";
  };

  # Release binaries are built on Axiom against this nixpkgs and link these paths.
  system.extraDependencies = [ pkgs.glibc pkgs.stdenv.cc.cc.lib ];

  # --- PostgreSQL 18, sized for a 2 GiB host shared with other services ---
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
    enableTCPIP = false;
    ensureDatabases = [ "szzx" ];
    ensureUsers = [{ name = "szzx"; ensureDBOwnership = true; }];
    settings = {
      max_connections = 20;
      shared_buffers = "64MB";
      work_mem = "4MB";
      maintenance_work_mem = "32MB";
      effective_cache_size = "256MB";
      wal_buffers = "2MB";
      min_wal_size = "64MB";
      max_wal_size = "256MB";
      huge_pages = "off";
    };
  };
  systemd.services.postgresql.serviceConfig = {
    MemoryHigh = "256M";
    MemoryMax = "384M";
  };

  # --- Loopback NFSv4.1 media storage (the backend refuses plain directories) ---
  services.nfs.server = {
    enable = true;
    nproc = 2;
    exports = ''
      ${exportRoot} 127.0.0.1(rw,sync,root_squash,no_subtree_check,fsid=0,sec=sys)
    '';
  };
  services.nfs.settings.nfsd = {
    vers3 = "n";
    vers4 = "y";
    "vers4.0" = "n";
    "vers4.1" = "y";
    "vers4.2" = "y";
  };

  fileSystems.${mediaRoot} = {
    device = "127.0.0.1:/";
    fsType = "nfs";
    options = [
      "vers=4.1"
      "proto=tcp"
      "rw"
      "hard"
      "resvport"
      "nofail"
      "_netdev"
      "x-systemd.requires=nfs-server.service"
      "x-systemd.after=nfs-server.service"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /srv/szzx 0700 root root -"
    "d ${exportRoot} 2770 szzx szzx -"
    "d /etc/szzx 0750 root szzx -"
    "d /etc/szzx/mock 0750 root szzx -"
    "d /opt/szzx 0755 c1 users -"
    "d /opt/szzx/releases 0755 c1 users -"
    "d /opt/szzx/admin 0755 c1 users -"
  ];

  # --- Backend ---
  systemd.services.szzx-backend = {
    description = "SZzX public test backend (mock HIS)";
    after = [ "network-online.target" "postgresql.service" ];
    wants = [ "network-online.target" ];
    requires = [ "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig = {
      RequiresMountsFor = mediaRoot;
      ConditionPathExists = [ envFile "${current}/szzx-backend" ];
    };
    environment = {
      FFPROBE_PATH = "${pkgs.ffmpeg-headless}/bin/ffprobe";
    };
    serviceConfig = {
      Type = "simple";
      User = "szzx";
      Group = "szzx";
      EnvironmentFile = envFile;
      ExecStart = "${current}/szzx-backend";
      Restart = "on-failure";
      RestartSec = "5s";
      TimeoutStopSec = "30s";
      MemoryHigh = "256M";
      MemoryMax = "384M";
      UMask = "0007";
      NoNewPrivileges = true;
      PrivateTmp = true;
      PrivateDevices = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ReadWritePaths = [ mediaRoot ];
      RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
    };
  };

  # --- Public ingress: admin static files and API on one origin ---
  modules.services.nginx.cloudflareDnsAcme.hosts = [ hostName ];

  services.nginx.virtualHosts.${hostName} = {
    onlySSL = true;
    useACMEHost = hostName;
    root = "/opt/szzx/admin/current";
    extraConfig = ''
      server_tokens off;
      add_header Strict-Transport-Security "max-age=31536000" always;
      add_header X-Content-Type-Options "nosniff" always;
      add_header Referrer-Policy "same-origin" always;
    '';
    # Defence in depth; the backend also refuses these in live mode.
    locations."^~ /api/v1/patient/".return = "404";
    locations."^~ /api/docs".return = "404";
    locations."= /api/openapi.json".return = "404";
    locations."/api/" = {
      proxyPass = backend;
      recommendedProxySettings = false;
      extraConfig = apiProxy + ''
        client_max_body_size 210m;
        proxy_request_buffering off;
        proxy_read_timeout 300s;
        proxy_send_timeout 300s;
      '';
    };
    locations."= /health" = {
      proxyPass = backend;
      recommendedProxySettings = false;
      extraConfig = apiProxy;
    };
    locations."/assets/".extraConfig = ''
      expires 1y;
      try_files $uri =404;
    '';
    locations."/".extraConfig = ''
      expires -1;
      try_files $uri /index.html;
    '';
  };
}

{ config, pkgs, ... }:

let
  serviceUser = "oneex-portfolio-adapter";
  hostName = "1ex-portfolio.0xc1.wang";
  adapterPackage = pkgs.unstable.rustPlatform.buildRustPackage {
    pname = "oneex-portfolio-adapter";
    # Force a fresh source build; Axiom's prior output is registered but missing.
    version = "0.1.0-8dcf21f-audience-rebuild1";

    src = ../../../packages/oneex-portfolio-adapter/vendor;
    cargoLock.lockFile = ../../../packages/oneex-portfolio-adapter/vendor/Cargo.lock;

    postPatch = ''
      substituteInPlace src/main.rs \
        --replace-fail \
          "const READ_TIMEOUT: Duration = Duration::from_millis(4_500);" \
          "const READ_TIMEOUT: Duration = Duration::from_millis(5_800);"
    '';
  };
in

{
  users.groups.${serviceUser} = {};
  users.users.${serviceUser} = {
    isSystemUser = true;
    group = serviceUser;
  };

  age.secrets.oneex-portfolio-adapter-env = {
    owner = serviceUser;
    group = serviceUser;
    mode = "0400";
  };

  systemd.services.oneex-portfolio-adapter = {
    description = "1Ex portfolio Custom Account Source adapter";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    restartTriggers = [ ../secrets/oneex-portfolio-adapter-env.age ];

    serviceConfig = {
      Type = "simple";
      User = serviceUser;
      Group = serviceUser;
      EnvironmentFile = config.age.secrets.oneex-portfolio-adapter-env.path;
      ExecStart = "${adapterPackage}/bin/oneex-portfolio-adapter";
      Restart = "on-failure";
      RestartSec = "5s";
      UMask = "0077";
      LimitCORE = 0;
      CapabilityBoundingSet = "";
      AmbientCapabilities = "";
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
    };
  };

  services.nginx.virtualHosts.${hostName} = {
    onlySSL = true;
    useACMEHost = hostName;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8090";
      extraConfig = ''
        proxy_read_timeout 10s;
      '';
    };
  };

  modules.services.nginx.cloudflareDnsAcme.hosts = [ hostName ];
}

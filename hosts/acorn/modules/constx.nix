{ pkgs, ... }:

let
  releaseSha = "45c21f0a2f437cb11cb5e316c29d5ff08cbef471";
  serviceUser = "c1";
  serviceGroup = "users";
  stateDir = "/var/lib/constx";
  releaseBinary = "/home/${serviceUser}/.local/share/constx/releases/${releaseSha}/constxd";
in
{
  systemd.services.constxd = {
    description = "Const X control plane";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    path = [ pkgs.nodejs_22 ];
    environment = {
      HOME = stateDir;
      XDG_CONFIG_HOME = "${stateDir}/config";
      XDG_DATA_HOME = "${stateDir}/data";
      RUST_LOG = "info";
    };

    serviceConfig = {
      Type = "simple";
      User = serviceUser;
      Group = serviceGroup;
      WorkingDirectory = stateDir;
      StateDirectory = "constx";
      StateDirectoryMode = "0700";
      ExecStartPre = [ "${pkgs.coreutils}/bin/test -x ${releaseBinary}" ];
      ExecStart = "${releaseBinary} serve";
      Restart = "on-failure";
      RestartSec = "5s";
      UMask = "0077";
      LimitCORE = 0;
      CapabilityBoundingSet = "";
      AmbientCapabilities = "";
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateTmp = true;
      ProtectHome = "read-only";
      ProtectSystem = "strict";
      ReadWritePaths = [ stateDir ];
      RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
    };
  };
}

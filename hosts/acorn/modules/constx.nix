{ config, lib, pkgs, ... }:

with lib;

let
  releaseSha = "a3cb397751e0101d957494be43c6a94bed1e611b";
  serviceUser = "c1";
  serviceGroup = "users";
  stateDir = "/var/lib/constx";
  constxHost = "constx.0xc1.wang";
  authIssuer = "https://auth.0xc1.wang";
  authAudience = constxHost;
  releaseBinary = "/home/${serviceUser}/.local/share/constx/releases/${releaseSha}/constxd";
  directIngress = config.modules.services.constx.nativeAuthIngress == "direct";
  authConfigCheck = pkgs.writeShellScript "constxd-auth-config-check" ''
    exec ${releaseBinary} configure-auth \
      --check \
      --issuer ${authIssuer} \
      --audience ${authAudience}
  '';
in
{
  options.modules.services.constx.nativeAuthIngress = mkOption {
    type = types.enum [ "direct" "gateway" ];
    default = "direct";
    description = "Whether constx.0xc1.wang uses its native Auth Mini boundary or the temporary gateway staging ingress.";
  };

  config = mkMerge [
    {
      modules.services.nginx.cloudflareDnsAcme.hosts = [ constxHost ];

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
          ExecStartPre = [
            "${pkgs.coreutils}/bin/test -x ${releaseBinary}"
            authConfigCheck
          ];
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

    (mkIf directIngress {
      services.nginx.virtualHosts.${constxHost} = {
        onlySSL = true;
        useACMEHost = constxHost;
        extraConfig = ''
          client_max_body_size 22m;
        '';
        locations."/" = {
          proxyPass = "http://127.0.0.1:3210";
          recommendedProxySettings = false;
          extraConfig = ''
            proxy_http_version 1.1;
            proxy_set_header Host ${constxHost};
            proxy_set_header X-Forwarded-Host ${constxHost};
            proxy_set_header X-Forwarded-Proto https;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header Authorization $http_authorization;
            proxy_set_header Cookie $http_cookie;
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
    })
  ];
}

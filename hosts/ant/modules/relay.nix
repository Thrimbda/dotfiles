{ config, ... }:
{
  age.secrets.frp-token = { owner = config.user.name; mode = "0400"; };
  age.secrets.frps-tls-key = { owner = config.user.name; mode = "0400"; };

  modules.services.frp.server = {
    enable = true;
    extraConfig = {
      allowPorts = map (single: { inherit single; }) [ 2225 18080 18081 18082 ];
      webServer = { addr = "127.0.0.1"; port = 7500; };
      transport.tls = {
        force = true;
        certFile = ../../../config/frp/ant-frps.crt;
        keyFile = config.age.secrets.frps-tls-key.path;
      };
    };
  };
  systemd.services.frps.restartTriggers = [ ../secrets/frp-token.age ../secrets/frps-tls-key.age ];
}

{ config, ... }:
{
  age.secrets.frps-tls-key = { owner = config.user.name; mode = "0400"; };
  modules.services.frp.server.extraConfig.transport.tls = {
    certFile = ../../../config/frp/acorn-frps.crt;
    keyFile = config.age.secrets.frps-tls-key.path;
  };
  systemd.services.frps.restartTriggers = [ ../secrets/frps-tls-key.age ];
}

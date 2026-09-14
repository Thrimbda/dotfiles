{ config, ... }:
{
  modules.agenix.sshKey = "${config.user.home}/.ssh/id_ed25519";
  age.secrets.frp-token = { owner = config.user.name; group = "staff"; mode = "0400"; };
  age.secrets.screen-sharing-key = { owner = config.user.name; group = "staff"; mode = "0400"; };

  modules.services.frp = {
    secretNames.FRP_SCREEN_KEY = "screen-sharing-key";
    client = {
      enable = true;
      serverAddr = "8.159.128.125";
      extraConfig = {
        transport.tls = {
          enable = true;
          trustedCaFile = ./acorn-frps.crt;
          serverName = "8.159.128.125";
        };
        log = {
          to = "${config.user.home}/Library/Logs/frpc.log";
          level = "info";
          maxDays = 7;
          disablePrintColor = true;
        };
      };
    };
  };
}

{ config, ... }:
{
  modules.agenix.sshKey = "${config.user.home}/.ssh/id_ed25519";
  age.secrets.frp-token = { owner = config.user.name; group = "staff"; mode = "0400"; };
  age.secrets.screen-sharing-key = { owner = config.user.name; group = "staff"; mode = "0400"; };

  modules.services.frp = {
    secretNames.FRP_SCREEN_KEY = "screen-sharing-key";
    client = {
      enable = true;
      serverAddr = "106.15.156.143";
      serverPort = 7001;
      extraConfig = {
        transport.protocol = "quic";
        transport.tls = {
          enable = true;
          trustedCaFile = ./ant-frps.crt;
          serverName = "106.15.156.143";
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

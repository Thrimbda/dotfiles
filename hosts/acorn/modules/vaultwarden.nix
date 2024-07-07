{ config, lib, ... }:

{
  modules.services.vaultwarden.enable = true;

  services.vaultwarden = {
    backupDir = "/backup/vaultwarden";
    # Inject secrets at runtime
    environmentFile = config.age.secrets.vaultwarden-env.path;
    config = {
      domain = "https://vault.0xc1.space";
      invitationsAllowed = true;
      rocketPort = 8000;
      signupsAllowed = false;
      websocketEnabled = true;
      # Bitwarden apps bombard the server every 30s.
      loginRatelimitSeconds = 30;
    };
  };

  services.nginx.virtualHosts."vault.0xc1.space" = {
    http2 = true;
    forceSSL = true;
    enableACME = true;
    root = "/srv/www/vault.0xc1.space";
    extraConfig = ''
      client_max_body_size 64M;
    '';
    locations = {
      "/notifications/hub/negotiate" = {
        proxyPass = "http://127.0.0.1:8000";
        proxyWebsockets = true;
      };
      "/notifications/hub" = {
        proxyPass = "http://127.0.0.1:3012";
        proxyWebsockets = true;
      };
      "/".proxyPass = "http://127.0.0.1:8000";
    };
  };

  systemd.tmpfiles.rules = [
    "z ${config.services.vaultwarden.backupDir} 750 vaultwarden vaultwarden - -"
    "d ${config.services.vaultwarden.backupDir} 750 vaultwarden vaultwarden - -"
  ];
}

{ config, ... }:

let
  mkVaultwardenVhost = domain: {
    # TLS listener ownership is staged from the host module.
    root = "/srv/www/${domain}";
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
in

{
  modules.services.vaultwarden.enable = true;

  age.secrets.vaultwarden-env = {
    owner = "vaultwarden";
    group = "vaultwarden";
    mode = "0400";
  };

  services.vaultwarden = {
    backupDir = "/backup/vaultwarden";
    environmentFile = config.age.secrets.vaultwarden-env.path;
    config = {
      domain = "https://vault.0xc1.wang";
      invitationsAllowed = true;
      rocketPort = 8000;
      signupsAllowed = false;
      websocketEnabled = true;
      # Bitwarden apps bombard the server every 30s.
      loginRatelimitSeconds = 30;
    };
  };

  services.nginx.virtualHosts = {
    "vault.0xc1.wang" = mkVaultwardenVhost "vault.0xc1.wang";
  };

  systemd.tmpfiles.rules = [
    "z ${config.services.vaultwarden.backupDir} 750 vaultwarden vaultwarden - -"
    "d ${config.services.vaultwarden.backupDir} 750 vaultwarden vaultwarden - -"
  ];
}

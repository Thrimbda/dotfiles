{ config, lib, ... }:

{
  modules.services.nginx.cloudflareDnsAcme = {
    enable = true;
    email = "siyuan.arc@gmail.com";
    credentialsFile = ../secrets/cloudflare-dns.env.age;
  };

  age.secrets.nginx-status-htpasswd = {
    owner = "nginx";
    group = "nginx";
  };

  assertions = [{
    assertion = !(lib.elem 18082 config.networking.firewall.allowedTCPPorts);
    message = "acorn PI WEB FRP remote port must remain closed in the host firewall";
  }];
}

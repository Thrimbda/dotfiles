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
}

{ hey, lib, config, options, pkgs, ... }:

with builtins;
with lib;
with hey.lib;
let
  cfg = config.modules.services.nginx;
  acmeCfg = cfg.cloudflareDnsAcme;
in {
  options.modules.services.nginx = with types; {
    enable = mkBoolOpt false;
    enableCloudflareSupport = mkBoolOpt false;
    cloudflareDnsAcme = {
      enable = mkBoolOpt false;
      email = mkOpt str "";
      credentialsFile = mkOpt (nullOr path) null;
      hosts = mkOpt (listOf str) [];
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      networking.firewall.allowedTCPPorts = [ 80 443 ];

      user.extraGroups = [ "nginx" ];

      services.nginx = {
        enable = true;

        # Use recommended settings
        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;

        # Reduce the permitted size of client requests, to reduce the likelihood
        # of buffer overflow attacks. This can be tweaked on a per-vhost basis,
        # as needed.
        clientMaxBodySize = "256k";  # default 10m
        # Significantly speed up regex matchers
        appendConfig = ''pcre_jit on;'';
        commonHttpConfig = ''
          client_body_buffer_size  4k;       # default: 8k
          large_client_header_buffers 2 4k;  # default: 4 8k

          map $sent_http_content_type $expires {
              default                    off;
              text/html                  10m;
              text/css                   max;
              application/javascript     max;
              application/pdf            max;
              ~image/                    max;
          }
        '';
      };
    })

    (mkIf cfg.enableCloudflareSupport {
      services.nginx.commonHttpConfig = ''
        ${concatMapStrings (ip: "set_real_ip_from ${ip};\n")
          (filter (line: line != "")
            (splitString "\n" ''
              ${readFile (fetchurl "https://www.cloudflare.com/ips-v4/")}
              ${readFile (fetchurl "https://www.cloudflare.com/ips-v6/")}
            ''))}
        real_ip_header CF-Connecting-IP;
      '';
    })

    (mkIf acmeCfg.enable {
      assertions = [{
        assertion = acmeCfg.credentialsFile != null && acmeCfg.email != "";
        message = "modules.services.nginx.cloudflareDnsAcme requires credentialsFile and email";
      }];

      age.secrets.cloudflare-dns-env = {
        file = acmeCfg.credentialsFile;
        owner = "acme";
        group = "acme";
        mode = "0400";
      };

      security.acme.defaults.email = acmeCfg.email;
      security.acme.certs = genAttrs (unique acmeCfg.hosts) (_: {
        dnsProvider = "cloudflare";
        environmentFile = config.age.secrets.cloudflare-dns-env.path;
        group = "nginx";
        reloadServices = [ "nginx.service" ];
      });
    })
  ];
}

# Helpful nginx snippets
#
# Set expires headers for static files and turn off logging.
#   location ~* ^.+\.(js|css|swf|xml|txt|ogg|ogv|svg|svgz|eot|otf|woff|mp4|ttf|r ss|atom|jpg|jpeg|gif|png|ico|zip|tgz|gz|rar|bz2|doc|xls|exe|ppt|tar|mid|midi|wav |bmp|rtf)$ {
#     access_log off; log_not_found off; expires 30d;
#   }
#
# Deny all attempts to access PHP Files in the uploads directory
#   location ~* /(?:uploads|files)/.*\.php$ {
#     deny all;
#   }

{ hey, lib, ... }:

{
  system = "x86_64-linux";

  modules = {
    profiles = {
      user = "c1";
      role = "server";
    };

    editors = {
      default = "nvim";
      vim.enable = true;
    };

    shell = {
      git.enable = true;
      tmux.enable = true;
      zsh.enable = true;
    };

    services = {
      ssh.enable = true;
      fail2ban.enable = true;
      frp.server.enable = true;
      nginx.enable = true;
    };

    theme.active = null;
    theme.useX = false;
  };

  config = { config, modulesPath, lib, pkgs, ... }:
  let
    stagedTlsDomains = [
      "status-axiom.0xc1.wang"
    ];
    stagedTlsDir = domain: "/var/lib/nginx-selfsigned/${domain}";
    mkStagedTlsVhost = domain: {
      onlySSL = true;
      sslCertificate = "${stagedTlsDir domain}/fullchain.pem";
      sslCertificateKey = "${stagedTlsDir domain}/key.pem";
    };
  in {
    imports = [
      "${modulesPath}/profiles/qemu-guest.nix"
      ./modules/vaultwarden.nix
    ];

    modules.agenix.sshKey = "/home/c1/.ssh/id_ed25519";

    age.secrets.nginx-status-htpasswd = {
      owner = "nginx";
      group = "nginx";
    };

    age.secrets.cloudflare-dns-env = {
      file = ./secrets/cloudflare-dns.env.age;
      owner = "acme";
      group = "acme";
      mode = "0400";
    };

    nix.settings = {
      substituters = lib.mkBefore [
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
        "https://mirrors.ustc.edu.cn/nix-channels/store"
        "https://mirror.sjtu.edu.cn/nix-channels/store"
      ];
      max-jobs = 1;
      cores = 1;
      http-connections = 4;
    };

    programs.nix-ld.enable = lib.mkForce false;

    documentation = {
      enable = false;
      man.enable = false;
      info.enable = false;
      nixos.enable = false;
    };

    virtualisation.docker.enableOnBoot = lib.mkForce false;

    boot = {
      growPartition = true;
      kernelParams = [ "console=ttyS0,115200n8" ];
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = false;
      };
    };

    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
      autoResize = true;
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-label/ESP";
      fsType = "vfat";
    };

    networking = {
      hostName = "aliyun-acorn";
      useDHCP = lib.mkForce false;
      firewall = {
        allowedTCPPorts = lib.mkForce [ 22 443 2222 2223 2224 2225 7000 34197 ];
        allowedUDPPorts = [ 34197 ];
      };
    };

    systemd.network = {
      enable = true;
      networks."10-aliyun-dhcp" = {
        matchConfig.Name = "eth* ens* enp*";
        networkConfig = {
          DHCP = "ipv4";
          IPv6AcceptRA = true;
        };
      };
    };

    services.cloud-init = {
      enable = true;
      network.enable = true;
      settings = {
        datasource_list = [ "AliYun" "NoCloud" "None" ];
      };
    };

    systemd.services.nginx = {
      serviceConfig = {
        StateDirectory = "nginx-selfsigned";
        StateDirectoryMode = "0750";
      };
      preStart = lib.mkBefore ''
        set -eu
        for domain in ${lib.escapeShellArgs stagedTlsDomains}; do
          dir=/var/lib/nginx-selfsigned/$domain
          cert=$dir/fullchain.pem
          key=$dir/key.pem
          if [ ! -s "$cert" ] || [ ! -s "$key" ]; then
            mkdir -p "$dir"
            ${pkgs.openssl}/bin/openssl req -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes \
              -keyout "$key" -out "$cert" \
              -subj "/CN=$domain" -addext "subjectAltName=DNS:$domain"
            chmod 600 "$key"
            chmod 644 "$cert"
          fi
        done
      '';
    };

    services.nginx.virtualHosts."vault.0xc1.wang" = {
      onlySSL = true;
      useACMEHost = "vault.0xc1.wang";
    };

    services.nginx.virtualHosts."status-axiom.0xc1.wang" = mkStagedTlsVhost "status-axiom.0xc1.wang" // {
      # Staged HTTPS stays public; ACME is re-enabled after DNS cutover is ready.
      locations."/" = {
        proxyPass = "http://127.0.0.1:18080";
        proxyWebsockets = true;
        basicAuthFile = config.age.secrets.nginx-status-htpasswd.path;
      };
    };

    programs.ssh.startAgent = true;
    services.openssh = {
      startWhenNeeded = lib.mkForce false;
      extraConfig = lib.mkForce "";
    };
    security.acme.defaults.email = "siyuan.arc@gmail.com";
    security.acme.certs."vault.0xc1.wang" = {
      dnsProvider = "cloudflare";
      environmentFile = config.age.secrets.cloudflare-dns-env.path;
      group = "nginx";
      reloadServices = [ "nginx.service" ];
    };

    time.timeZone = "Asia/Shanghai";

    systemd.services."serial-getty@ttyS0".enable = lib.mkForce true;
    systemd.services."getty@tty1".enable = lib.mkForce true;
    systemd.services."autovt@".enable = lib.mkForce true;

    systemd.services.cloud-init.path = [ pkgs.e2fsprogs pkgs.iproute2 ];
    systemd.services.cloud-config.path = [ pkgs.e2fsprogs pkgs.iproute2 ];
    systemd.services.cloud-final.path = [ pkgs.e2fsprogs pkgs.iproute2 ];
  };
}

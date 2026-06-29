{ hey, lib, ... }:

{
  system = "x86_64-linux";

  modules = {
    profiles = {
      user = "c1";
      role = "server";
    };

    dev = {
      node.enable = true;
      deno.enable = true;
      rust.enable = true;
      python.enable = true;
    };

    editors = {
      default = "nvim";
      vim.enable = true;
    };

    shell = {
      adl.enable = true;
      direnv.enable = true;
      git.enable = true;
      gnupg.enable = true;
      tmux.enable = true;
      zsh.enable = true;
    };

    services = {
      ssh.enable = true;
      docker.enable = true;
      fail2ban.enable = true;
      frp.server.enable = true;
      nginx.enable = true;
    };

    theme.active = null;
    theme.useX = false;
  };

  config = { config, modulesPath, lib, pkgs, ... }: {
    imports = [
      "${modulesPath}/profiles/qemu-guest.nix"
    ];

    modules.agenix.sshKey = "/home/c1/.ssh/id_ed25519";

    age.secrets.nginx-status-htpasswd = {
      owner = "nginx";
      group = "nginx";
    };

    nix.settings.substituters = lib.mkBefore [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirror.sjtu.edu.cn/nix-channels/store"
    ];

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
        allowedTCPPorts = [ 22 80 443 2222 2225 7000 34197 ];
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

    services.nginx.virtualHosts."status-axiom.0xc1.wang" = {
      http2 = true;
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:18080";
        proxyWebsockets = true;
        basicAuthFile = config.age.secrets.nginx-status-htpasswd.path;
      };
    };

    virtualisation.docker.enableOnBoot = lib.mkForce true;

    programs.ssh.startAgent = true;
    services.openssh.startWhenNeeded = true;
    security.acme.defaults.email = "siyuan.arc@gmail.com";

    time.timeZone = "Asia/Shanghai";

    systemd.services."serial-getty@ttyS0".enable = lib.mkForce true;
    systemd.services."getty@tty1".enable = lib.mkForce true;
    systemd.services."autovt@".enable = lib.mkForce true;

    systemd.services.cloud-init.path = [ pkgs.e2fsprogs pkgs.iproute2 ];
    systemd.services.cloud-config.path = [ pkgs.e2fsprogs pkgs.iproute2 ];
    systemd.services.cloud-final.path = [ pkgs.e2fsprogs pkgs.iproute2 ];
  };
}

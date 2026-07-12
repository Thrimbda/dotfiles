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
      rustdeskSecret = config.age.secrets.rustdesk-server-key;
      rustdeskSecretMetadata =
        "${rustdeskSecret.owner}:${rustdeskSecret.group}:${lib.removePrefix "0" rustdeskSecret.mode}";
      rustdeskKeyPreflight = pkgs.writeShellScript "acorn-rustdesk-key-preflight" ''
        set -eu

        configured=${lib.escapeShellArg rustdeskSecret.path}
        target=$(${pkgs.coreutils}/bin/readlink -e -- "$configured" 2>/dev/null) \
          || exit 1
        [ -n "$target" ] && [ -f "$target" ] && [ ! -L "$target" ] \
          || exit 1
        metadata=$(${pkgs.coreutils}/bin/stat --format='%U:%G:%a' -- "$target" 2>/dev/null) \
          || exit 1
        [ "$metadata" = ${lib.escapeShellArg rustdeskSecretMetadata} ] \
          || exit 1
        [ -r "$target" ] && [ -s "$target" ]
      '';
    in {
    imports = [
      "${modulesPath}/profiles/qemu-guest.nix"
      ./modules/auth-mini.nix
      ./modules/vaultwarden.nix
    ];

    modules.agenix.sshKey = "/home/c1/.ssh/id_ed25519";

    modules.services.frp.server.extraConfig.webServer = {
      addr = "127.0.0.1";
      port = 7500;
    };

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

    age.secrets.rustdesk-server-key = {
      path = "/var/lib/rustdesk/id_ed25519";
      owner = "rustdesk";
      group = "rustdesk";
      mode = "0400";
    };

    assertions = [{
      assertion = config.services.rustdesk-server.package.version == "1.1.14";
      message = "acorn RustDesk Server must remain pinned to 1.1.14";
    }];

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
      hostName = "acorn";
      useDHCP = lib.mkForce false;
      firewall = {
        allowedTCPPorts = lib.mkForce [ 22 443 2222 2223 2224 2225 7000 21115 21116 21117 34197 ];
        allowedUDPPorts = [ 21116 34197 ];
      };
    };

    services.rustdesk-server = {
      enable = true;
      openFirewall = false;
      signal = {
        relayHosts = [ "rustdesk.0xc1.wang" ];
        extraArgs = [ "-k" "_" ];
      };
      relay.extraArgs = [ "-k" "_" ];
    };

    systemd.tmpfiles.rules = [
      "L+ /var/lib/rustdesk/id_ed25519.pub - - - - ${./secrets/rustdesk-server-key.pub}"
    ];

    systemd.services.rustdesk-signal = {
      restartTriggers = [
        ./secrets/rustdesk-server-key.age
        ./secrets/rustdesk-server-key.pub
      ];
      serviceConfig = {
        ExecStartPre = [
          rustdeskKeyPreflight
          "${pkgs.coreutils}/bin/test -r /var/lib/rustdesk/id_ed25519.pub"
          "${pkgs.coreutils}/bin/test -s /var/lib/rustdesk/id_ed25519.pub"
        ];
        LimitCORE = 0;
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    systemd.services.rustdesk-relay = {
      restartTriggers = [
        ./secrets/rustdesk-server-key.age
        ./secrets/rustdesk-server-key.pub
      ];
      serviceConfig = {
        ExecStartPre = [
          rustdeskKeyPreflight
          "${pkgs.coreutils}/bin/test -r /var/lib/rustdesk/id_ed25519.pub"
          "${pkgs.coreutils}/bin/test -s /var/lib/rustdesk/id_ed25519.pub"
        ];
        LimitCORE = 0;
        Restart = "on-failure";
        RestartSec = "5s";
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

    services.nginx.virtualHosts."vault.0xc1.wang" = {
      onlySSL = true;
      useACMEHost = "vault.0xc1.wang";
    };

    programs.ssh.startAgent = true;
    services.openssh = {
      startWhenNeeded = lib.mkForce false;
    };
    security.acme.defaults.email = "siyuan.arc@gmail.com";
    security.acme.certs."vault.0xc1.wang" = {
      dnsProvider = "cloudflare";
      environmentFile = config.age.secrets.cloudflare-dns-env.path;
      group = "nginx";
      reloadServices = [ "nginx.service" ];
    };
    security.acme.certs."status-axiom.0xc1.wang" = {
      dnsProvider = "cloudflare";
      environmentFile = config.age.secrets.cloudflare-dns-env.path;
      group = "nginx";
      reloadServices = [ "nginx.service" ];
    };
    security.acme.certs."opencode-axiom.0xc1.wang" = {
      dnsProvider = "cloudflare";
      environmentFile = config.age.secrets.cloudflare-dns-env.path;
      group = "nginx";
      reloadServices = [ "nginx.service" ];
    };
    security.acme.certs."frps-acorn.0xc1.wang" = {
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

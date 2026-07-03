# Axiom -- C1's Ryzen 9950X + RTX 5090 workstation

{ hey, lib, ... }:

with lib;
with builtins;
{
  system = "x86_64-linux";

  ## Modules
  modules = {
    theme = {
      active = "autumnal";
      wallpapers."*" = {
        path = "/home/c1/the-great-sage.jpg";
      };
    };

    profiles = {
      role = "workstation";
      user = "c1";
      networks = [ "sh" ];
      hardware = [
        "cpu/amd"
        "gpu/nvidia"
        "audio"
        "audio/realtime"
        "ssd"
        "bluetooth"
        "wifi"
      ];
    };

    desktop = {
      caelestia.wallpaper.enable = true;
      hyprland = {
        enable = true;
        extraConfig = ''
          render {
            # Work around Hyprland 0.53.x color-management crashes on DPMS/resume.
            # HDR is lower priority than 240Hz and needs color management, so keep
            # this guard until the Axiom session is re-tested on the real display.
            cm_enabled = false
          }

          misc {
            # Permit relaunching the Caelestia WlSessionLock client if it exits.
            allow_session_lock_restore = true
          }
        '';
        monitors = [
          {
            output = "DP-4";
            modePolicy = "native-max-refresh";
            fallbackMode = "3840x2160@240";
            position = "0x0";
            scale = 1.5;
            primary = true;
            match = {
              make = "Microstep";
              model = "MPG272UX OLED";
              serial = "0x01010101";
            };
          }
          {
            output = "DP-5";
            modePolicy = "native-max-refresh";
            fallbackMode = "3840x2160@60";
            position = "2560x0";
            scale = 1.5;
            match = {
              make = "Dell Inc.";
              model = "DELL U2720QM";
              serial = "42N2YG3";
            };
          }
        ];
        monitorHotplug = {
          enable = true;
          unknown = {
            enable = true;
            modePolicy = "native-max-refresh";
            position = "auto";
            scale = 1.5;
          };
        };
        workspaces.secondary.enable = true;
      };
      apps = {
        clash-verge.enable = true;
        discord.enable = true;
        sidra.enable = true;
        steam = {
          enable = true;
          dwproton.enable = true;
        };
        thunar.enable = true;
      };
      input = {
        colemak.enable = true;
        fcitx5 = {
          enable = true;
          rime.enable = true;
          pinyin.enable = true;
        };
      };
      browsers = {
        zen.enable = true;
      };
      term = {
        default = "foot";
        foot.enable = true;
      };
      media.video.enable = true;
    };

    dev = {
      node.enable = true;
      deno.enable = true;
      playwright.enable = true;
      rust.enable = true;
      python.enable = true;
      java.enable = true;
    };
    editors = {
      default = "nvim";
      vim.enable = true;
      vscode.enable = true;
    };
    shell = {
      direnv.enable = true;
      git.enable = true;
      gnupg.enable = true;
      tmux.enable = true;
      zsh.enable = true;
    };
    services = {
      ssh.enable = true;
      docker.enable = true;
      calibre.enable = true;
      gnome-keyring.enable = true;
    };
    system = {
      utils.enable = true;
    };
  };

  ## Local config
  config = { config, pkgs, ... }:
    let
      userName = config.user.name;
      opencodeDir = config.modules.services.opencode-server.dir;
      reverseSsh = config.modules.services.reverse-ssh;
      autosshRemoteHostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAHARUNf8QKGEqfBx2pCtJkBp5HEqoBjp9XyqIos07nA";
      aliyunAcornPublicIp = "8.159.128.125";
      cloudflaredReadyUrl = "http://127.0.0.1:20241/ready";
      frpcDirectRouteUnit = "frpc-aliyun-acorn-direct-route.service";
      frpcDirectRoutePriority = 8500;
      gatusPort = 8080;
      feishuLauncherId = "bytedance-feishu";
      legacyFeishuDesktopId = "bytedance-feishu.desktop";
      c1ctl = pkgs.callPackage ../../packages/c1ctl {
        heyBin = "${hey.binDir}/hey";
      };
      caelestiaIdleSettings = {
        lockBeforeSleep = true;
        inhibitWhenAudio = true;
        timeouts = [
          {
            timeout = 900;
            idleAction = "lock";
          }
          {
            timeout = 1800;
            idleAction = "dpms off";
            returnAction = "dpms on";
          }
        ];
      };
    in {
    modules.desktop.input.fcitx5.theme = {
      enable = true;
      name = "FluentDark";
      package = pkgs.fcitx5-fluent;
    };
    modules.desktop.caelestia = {
      settings = {
        general.idle = caelestiaIdleSettings;
        launcher.favouriteApps = [ feishuLauncherId ];
      };
      mutableConfig = {
        enable = true;
        settings.general.idle = caelestiaIdleSettings;
        launcher = {
          favouriteApps = [ feishuLauncherId ];
          removeFavouriteApps = [ legacyFeishuDesktopId ];
        };
      };
      localControls.polkit.enable = true;
      session = {
        extraPath = [ opencodeDir ];
        includePackageDataDirs = true;
      };
    };

    modules.desktop.audio.hdmi = {
      enable = true;
      card = "alsa_card.pci-0000_01_00.1";
      sink = "alsa_output.pci-0000_01_00.1.hdmi-stereo";
      lowPrioritySinks = [ "alsa_output.pci-0000_11_00.6.iec958-stereo" ];
    };

    modules.services.todesk.enable = true;
    modules.services.docker.package = pkgs.docker_29;
    modules.virt.libvirt.enable = true;
    modules.profiles.workstation = {
      logrotate.disableConfigCheck = true;
      userManager.oomScoreAdjust = 0;
      networkManager.ethernetInterfaces = [ "enp14s0" ];
      zram.enable = true;
    };
    modules.system.firewall.lanTcpAllows = [{
      source = "192.168.50.0/24";
      ports = [ 5173 8765 ];
      comment = "Allow the local research workbench only from the home LAN.";
    }];

    environment.systemPackages = [ c1ctl ];

    user.packages = with pkgs; [
      unstable.antigravity-fhs
      aria2
      feishu
      git-lfs
      htop
      k9s
      kubectl
      nvtopPackages.nvidia
      sops
      uv
    ];

    modules.desktop.apps.discord.package = pkgs.unstable.vesktop.override (
      optionalAttrs (pkgs.unstable.vesktop.override.__functionArgs ? pnpm_10_29_2) {
        # Newer nixpkgs temporarily pins pnpm_10_29_2 here, which is insecure.
        pnpm_10_29_2 = pkgs.unstable.pnpm_10;
      }
    );

    modules.desktop.apps.clash-verge = {
      servicePolicy = {
        enable = true;
        memoryMin = "256M";
        memoryLow = "1G";
        oomPolicy = "stop";
        oomScoreAdjust = -850;
      };
      guiAutostart = {
        enable = true;
        memoryLow = "256M";
        oomScoreAdjust = 0;
      };
    };

    modules.agenix.sshKey = "/etc/ssh/ssh_host_ed25519_key";

    modules.services.prometheus.enable = true;

    modules.services.reverse-ssh = {
      enable = true;
      remoteHost = aliyunAcornPublicIp;
      remoteHostKey = autosshRemoteHostKey;
      knownHostName = "autossh-remote-8.159.128.125";
      remotePort = 2223;
    };

    systemd.services.frpc-aliyun-acorn-direct-route = {
      description = "Route Axiom frpc traffic to aliyun-acorn outside Clash Meta";
      after = [ "network-online.target" "clash-verge.service" ];
      wants = [ "network-online.target" ];
      before = [ "frpc.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.iproute2 ];
      serviceConfig = {
        Type = "oneshot";
      };
      script = ''
        set -eu

        priority=${toString frpcDirectRoutePriority}
        target=${aliyunAcornPublicIp}/32

        ip -4 rule del priority "$priority" 2>/dev/null || true
        ip -4 rule add priority "$priority" to "$target" lookup main
        ip -4 route flush cache || true
      '';
    };

    systemd.services.frpc = {
      after = [ frpcDirectRouteUnit ];
      wants = [ frpcDirectRouteUnit ];
      requires = [ frpcDirectRouteUnit ];
    };

    modules.services.frp.client = {
      enable = true;
      serverAddr = aliyunAcornPublicIp;
      proxies = [
        {
          name = "axiom-ssh";
          type = "tcp";
          localIP = "127.0.0.1";
          localPort = 22;
          remotePort = 2225;
        }
        {
          name = "axiom-gatus-http";
          type = "tcp";
          localIP = "127.0.0.1";
          localPort = gatusPort;
          remotePort = 18080;
        }
      ];
    };

    modules.services.opencode-server = {
      enable = true;
      publicHostname = "opencode-axiom.0xc1.space";
      gatus = {
        enable = true;
        name = "opencode-axiom";
        labels.service = "opencode";
      };
      cloudflared.enable = true;
    };

    modules.services.gatus = {
      enable = true;
      port = gatusPort;
      publicHostname = "status-axiom.0xc1.space";
      labels = {
        environment = "production";
        owner = userName;
      };
      prometheusScrape.enable = true;
      cloudflared.enable = true;
      publicEndpoints = [{
        name = "vaultwarden-web";
        service = "vaultwarden";
        url = "https://vault.0xc1.space";
      }];
      selfEndpoint.enable = true;
    };

    modules.services.ssh.serviceConfig = {
      MemoryAccounting = true;
      MemoryMin = "32M";
      MemoryLow = "128M";
      OOMPolicy = "continue";
      OOMScoreAdjust = -900;
    };

    systemd.targets.axiom-cli = {
      description = "Axiom SSH-friendly CLI mode";
      after = [ "multi-user.target" ];
      requires = [ "multi-user.target" ];
      wants = [ "getty@tty1.service" ];
      conflicts = [ "graphical.target" ];
      unitConfig = {
        AllowIsolate = true;
        Documentation = [ "man:systemd.special(7)" ];
      };
    };

    modules.services.healthchecks.checks = {
      cloudflared-healthcheck = {
        description = "Cloudflared readiness health check";
        runtimeDirectory = "axiom-healthchecks";
        stateFile = "cloudflared.failures";
        threshold = 3;
        failureMessage = "cloudflared ready check failed";
        restartUnit = "cloudflared.service";
        after = [ "cloudflared.service" ];
        wants = [ "cloudflared.service" ];
        onUnitActiveSec = "45s";
        http.url = cloudflaredReadyUrl;
      };

      autossh-reverse-ssh-healthcheck = {
        description = "Autossh reverse SSH endpoint health check";
        runtimeDirectory = "axiom-healthchecks";
        stateFile = "autossh-reverse-ssh.failures";
        threshold = 3;
        failureMessage = "autossh reverse endpoint key check failed";
        restartUnit = "autossh-reverse-ssh.service";
        after = [ "network-online.target" "autossh-reverse-ssh.service" ];
        wants = [ "network-online.target" "autossh-reverse-ssh.service" ];
        autosshEndpointKey = {
          enable = true;
          remoteHost = reverseSsh.remoteHost;
          remotePort = reverseSsh.remotePort;
        };
      };

      clash-verge-healthcheck = {
        description = "Clash Verge service-mode health check";
        runtimeDirectory = "axiom-healthchecks";
        stateFile = "clash-verge.failures";
        threshold = 2;
        failureMessage = "clash-verge service/core health check failed";
        restartUnit = "clash-verge.service";
        after = [ "clash-verge.service" ];
        wants = [ "clash-verge.service" ];
        serviceCore = {
          enable = true;
          service = "clash-verge.service";
          childPattern = "verge-mihomo|mihomo|clash";
          interfaces = [ "Mihomo" "Meta" ];
        };
      };
    };

    modules.services.cloudflared = {
      enable = true;
      tunnelId = "bc8b3291-de93-4f7f-807a-23f802ef021f";
      credentialsFile = ./secrets/cloudflared-credentials.age;
      warpRouting.enabled = false;
      extraConfig = {
        metrics = "127.0.0.1:20241";
        protocol = "http2";
        tunnelName = "home-axiom";
      };
      ingress = [{ service = "http_status:404"; }];
      servicePolicy = {
        startLimitIntervalSec = 0;
        restart = "always";
        restartSec = "5s";
        memoryAccounting = true;
        memoryMin = "128M";
        memoryLow = "512M";
        oomPolicy = "stop";
        oomScoreAdjust = -850;
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ 22 ];
    };
  };

  ## Hardware
  hardware = { ... }: {
    boot.supportedFilesystems = [ "ntfs" ];

    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
      options = [ "noatime" ];
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-label/BOOT";
      fsType = "vfat";
    };

    swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];
  };
}

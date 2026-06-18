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
      };
      apps = {
        clash-verge.enable = true;
        discord.enable = true;
        sidra.enable = true;
        steam.enable = true;
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
      cloudflaredReadyUrl = "http://127.0.0.1:20241/ready";
      gatusPort = 8080;
      statusLabels = service: {
        inherit service;
        environment = "production";
        owner = userName;
      };
      feishuLauncherId = "bytedance-feishu";
      legacyFeishuDesktopId = "bytedance-feishu.desktop";
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
    modules.virt.libvirt.enable = true;

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

    # ISSUE: https://discourse.nixos.org/t/logrotate-config-fails-due-to-missing-group-30000/28501
    services.logrotate.checkConfig = false;

    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 20;
      memoryMax = 8589934592;
      priority = 100;
    };

    systemd.user.services."app-clash\\x2dverge@autostart" = {
      overrideStrategy = "asDropin";
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = "5s";
        MemoryAccounting = true;
        MemoryLow = "256M";
        OOMScoreAdjust = 0;
      };
    };

    modules.agenix.sshKey = "/etc/ssh/ssh_host_ed25519_key";

    modules.services.prometheus.enable = true;

    modules.services.reverse-ssh = {
      enable = true;
      remoteHost = "8.159.128.125";
      remoteHostKey = autosshRemoteHostKey;
      knownHostName = "autossh-remote-8.159.128.125";
      remotePort = 2223;
    };

    modules.services.opencode-server = {
      enable = true;
      publicHostname = "opencode-axiom.0xc1.space";
      gatus = {
        enable = true;
        name = "opencode-axiom";
        labels = statusLabels "opencode";
      };
      cloudflared.enable = true;
    };

    modules.services.gatus = {
      enable = true;
      port = gatusPort;
      prometheusScrape.enable = true;

      endpoints = [
        {
          name = "vaultwarden-web";
          group = "public";
          url = "https://vault.0xc1.space";
          interval = "1m";
          conditions = [
            "[STATUS] == 200"
            "[CERTIFICATE_EXPIRATION] > 336h"
            "[RESPONSE_TIME] < 2000"
          ];
          extra-labels = statusLabels "vaultwarden";
        }
        {
          name = "status-page";
          group = "infra";
          url = "http://127.0.0.1:${toString gatusPort}";
          interval = "1m";
          conditions = [
            "[STATUS] == 200"
            "[RESPONSE_TIME] < 500"
          ];
          extra-labels = statusLabels "gatus";
        }
      ];
    };

    systemd.services.sshd.serviceConfig = {
      MemoryAccounting = true;
      MemoryMin = "32M";
      MemoryLow = "128M";
      OOMPolicy = "continue";
      OOMScoreAdjust = -900;
    };

    systemd.services."user@${toString config.users.users.${userName}.uid}" = {
      overrideStrategy = "asDropin";
      serviceConfig.OOMScoreAdjust = mkForce 0;
    };

    systemd.services.cloudflared = {
      unitConfig.StartLimitIntervalSec = 0;
      serviceConfig = {
        Restart = mkForce "always";
        RestartSec = mkForce "5s";
        MemoryAccounting = true;
        MemoryMin = "128M";
        MemoryLow = "512M";
        OOMPolicy = "stop";
        OOMScoreAdjust = -850;
      };
    };

    systemd.services.clash-verge = {
      serviceConfig = {
        Restart = mkForce "on-failure";
        RestartSec = "5s";
        MemoryAccounting = true;
        MemoryMin = "256M";
        MemoryLow = "1G";
        OOMPolicy = "stop";
        OOMScoreAdjust = -850;
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
      ingress = [
        {
          hostname = "status-axiom.0xc1.space";
          service = "http://127.0.0.1:${toString gatusPort}";
        }
        { service = "http_status:404"; }
      ];
    };

    networking.firewall = {
      allowedTCPPorts = [ 22 ];
      extraCommands = ''
        # Allow the local research workbench only from the home LAN.
        iptables -w -A nixos-fw -s 192.168.50.0/24 -p tcp -m multiport --dports 5173,8765 -j nixos-fw-accept
      '';
    };
  };

  ## Hardware
  hardware = { ... }: {
    networking = {
      dhcpcd.enable = mkForce false;
      networkmanager = {
        ensureProfiles.profiles.enp14s0 = {
          connection = {
            id = "enp14s0";
            type = "ethernet";
            interface-name = "enp14s0";
            autoconnect = true;
          };
          ipv4.method = "auto";
          ipv6 = {
            method = "auto";
            addr-gen-mode = "stable-privacy";
          };
        };
      };
    };

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

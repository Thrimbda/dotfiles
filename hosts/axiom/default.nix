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
      acornPublicIp = "8.159.128.125";
      acornSshHostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE6WwypfVtdA16Au8kXoCVJgkTDlvgu98sqA0Z04Ux3l";
      acornAutosshKnownHosts = pkgs.writeText "axiom-acorn-known-hosts" ''
        ${acornPublicIp} ${acornSshHostKey}
      '';
      cloudflaredReadyUrl = "http://127.0.0.1:20241/ready";
      frpcDirectRouteUnit = "frpc-acorn-direct-route.service";
      frpcDirectRoutePriority = 8500;
      rustdeskHost = "rustdesk.0xc1.wang";
      rustdeskPackage = pkgs.unstable.rustdesk;
      rustdeskPublicKey = removeSuffix "\n" (readFile ../acorn/secrets/rustdesk-server-key.pub);
      rustdeskPublicConfig = pkgs.writeShellScript "axiom-rustdesk-public-config" ''
        set -eu
        rustdesk=${rustdeskPackage}/bin/rustdesk
        timeout=${pkgs.coreutils}/bin/timeout

        if [ "''${1:-apply}" = apply ]; then
          "$timeout" 15s "$rustdesk" --config \
            "rustdesk-host=${rustdeskHost},key=${rustdeskPublicKey},relay=${rustdeskHost}" \
            >/dev/null 2>&1
          set_option() {
            "$timeout" 15s "$rustdesk" --option "$1" "$2" >/dev/null 2>&1
          }
          set_option verification-method use-permanent-password
          set_option approve-mode password
          set_option allow-auto-update N
        elif [ "$1" != --check ]; then
          exit 2
        fi

        check() {
          value=$("$timeout" 15s "$rustdesk" --option "$1" 2>/dev/null)
          [ "$value" = "$2" ]
        }
        check custom-rendezvous-server ${escapeShellArg rustdeskHost}
        check key ${escapeShellArg rustdeskPublicKey}
        check relay-server ${escapeShellArg rustdeskHost}
        check verification-method use-permanent-password
        check approve-mode password
        check allow-auto-update N
      '';
      rustdeskRevision = pkgs.writeText "axiom-rustdesk-revision" ''
        package=${rustdeskPackage.version}
        public-config=${rustdeskPublicConfig}
        provision=axiom-rustdesk-provision-v1
        ciphertext=${./secrets/rustdesk-password.age}
      '';
      rustdeskProvision = pkgs.writeShellScript "axiom-rustdesk-provision" ''
        set -eu
        umask 077

        rustdesk=${rustdeskPackage}/bin/rustdesk
        state=/var/lib/rustdesk-provision
        stamp=$state/stamp
        stamp_tmp=$state/stamp.tmp.$$
        result=
        cleanup() {
          [ -z "$result" ] || ${pkgs.coreutils}/bin/rm -f "$result"
          ${pkgs.coreutils}/bin/rm -f "$stamp_tmp"
        }
        trap cleanup EXIT
        trap 'exit 1' HUP INT TERM
        fail() { echo "RustDesk provisioning failed: $1" >&2; exit 1; }

        if [ -f "$stamp" ] \
          && ${pkgs.diffutils}/bin/cmp -s "$stamp" ${rustdeskRevision}; then
          ${rustdeskPublicConfig} --check || fail public-config
          exit 0
        fi

        ready=0
        attempt=0
        while [ "$attempt" -lt 60 ]; do
          pid=$(${pkgs.systemd}/bin/systemctl show -p MainPID --value rustdesk.service)
          case "$pid" in ""|0|*[!0-9]*) ;; *)
            if ${pkgs.systemd}/bin/systemctl is-active --quiet rustdesk.service \
              && [ -S /tmp/RustDesk/ipc ] \
              && ${rustdeskPublicConfig} --check; then
              ready=1
              break
            fi
            ;;
          esac
          attempt=$((attempt + 1))
          ${pkgs.coreutils}/bin/sleep 1
        done
        [ "$ready" -eq 1 ] || fail readiness

        secret=${config.age.secrets.rustdesk-password.path}
        [ -r "$secret" ] && [ -f "$secret" ] || fail secret
        bytes=$(${pkgs.coreutils}/bin/wc -c < "$secret")
        password=
        IFS= read -r password < "$secret" || [ -n "$password" ] || fail secret
        [ "$bytes" -eq "''${#password}" ] \
          && [ "''${#password}" -ge 32 ] && [ "''${#password}" -le 64 ] \
          || fail secret-format
        case "$password" in *[!A-Za-z0-9_-]*) fail secret-format ;; esac

        result=$(${pkgs.coreutils}/bin/mktemp "$state/result.XXXXXX")
        status=0
        ${pkgs.coreutils}/bin/timeout --signal=TERM --kill-after=5s 15s \
          "$rustdesk" --password "$password" > "$result" 2>&1 || status=$?
        unset password
        [ "$status" -eq 0 ] || fail password-command
        exec 3< "$result"
        IFS= read -r line <&3 || fail password-result
        if IFS= read -r _ <&3; then fail password-result; fi
        exec 3<&-
        [ "$line" = "Done!" ] || fail password-result
        unset line
        ${pkgs.coreutils}/bin/rm -f "$result"
        result=

        ${pkgs.systemd}/bin/systemctl restart rustdesk.service
        attempt=0
        until ${pkgs.systemd}/bin/systemctl is-active --quiet rustdesk.service \
          && [ -S /tmp/RustDesk/ipc ] \
          && ${rustdeskPublicConfig} --check; do
          [ "$attempt" -lt 60 ] || fail restart
          attempt=$((attempt + 1))
          ${pkgs.coreutils}/bin/sleep 1
        done
        ${pkgs.coreutils}/bin/install -m 0600 ${rustdeskRevision} "$stamp_tmp"
        ${pkgs.coreutils}/bin/mv -f "$stamp_tmp" "$stamp"
        trap - EXIT HUP INT TERM
      '';
      gatusPort = 8080;
      feishuLauncherId = "bytedance-feishu";
      legacyFeishuDesktopId = "bytedance-feishu.desktop";
      c1ctl = pkgs.callPackage ../../packages/c1ctl {
        heyBin = "${hey.binDir}/hey";
        autosshRemoteHost = reverseSsh.remoteHost;
        autosshRemoteUser = reverseSsh.remoteUser;
        autosshRemotePort = reverseSsh.remotePort;
        autosshRemoteHostKey = acornSshHostKey;
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
      rustdeskPackage
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

    assertions = [{
      assertion = rustdeskPackage.version == "1.4.8";
      message = "axiom RustDesk client must remain pinned to 1.4.8";
    }];

    age.secrets.rustdesk-password = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

    systemd.services.rustdesk-config = {
      description = "Configure RustDesk public self-host parameters";
      before = [ "rustdesk.service" ];
      requiredBy = [ "rustdesk.service" ];
      restartTriggers = [ rustdeskRevision ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = rustdeskPublicConfig;
        RemainAfterExit = true;
        UMask = "0077";
        LimitCORE = 0;
      };
    };

    systemd.services.rustdesk = {
      description = "RustDesk system service";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      requires = [ "rustdesk-config.service" frpcDirectRouteUnit ];
      after = [
        "network-online.target"
        "systemd-user-sessions.service"
        "rustdesk-config.service"
        frpcDirectRouteUnit
      ];
      path = with pkgs; [ bash coreutils gawk gnugrep gnused procps sudo systemd util-linux ];
      environment = {
        PIPEWIRE_LATENCY = "1024/48000";
        PULSE_LATENCY_MSEC = "60";
      };
      serviceConfig = {
        Type = "simple";
        ExecStart = "${rustdeskPackage}/bin/rustdesk --service";
        User = "root";
        KillMode = "mixed";
        LimitNOFILE = 100000;
        LimitCORE = 0;
        TimeoutStopSec = "30s";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    systemd.services.rustdesk-provision = {
      description = "Provision RustDesk permanent password once";
      wantedBy = [ "multi-user.target" ];
      wants = [ "rustdesk.service" ];
      after = [ "rustdesk.service" ];
      restartTriggers = [ ./secrets/rustdesk-password.age rustdeskRevision ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = rustdeskProvision;
        RemainAfterExit = true;
        StateDirectory = "rustdesk-provision";
        StateDirectoryMode = "0700";
        UMask = "0077";
        TimeoutStartSec = "4min";
        LimitCORE = 0;
      };
    };

    modules.services.prometheus.enable = true;

    modules.services.reverse-ssh = {
      enable = true;
      remoteHost = acornPublicIp;
      remoteUser = "c1";
      globalKnownHostsFile = "${acornAutosshKnownHosts}";
      userKnownHostsFile = "/dev/null";
      remotePort = 2223;
    };

    systemd.services.frpc-acorn-direct-route = {
      description = "Route Axiom frpc traffic to acorn outside Clash Meta";
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
        target=${acornPublicIp}/32

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
      serverAddr = acornPublicIp;
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
        {
          name = "axiom-opencode-http";
          type = "tcp";
          localIP = "127.0.0.1";
          localPort = 4096;
          remotePort = 18081;
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

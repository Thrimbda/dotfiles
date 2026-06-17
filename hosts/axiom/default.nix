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
      userHome = config.user.home;
      opencode = config.modules.services.opencode-server;
      opencodeDir = opencode.dir;
      axiomHdmiAudioCard = "alsa_card.pci-0000_01_00.1";
      axiomHdmiAudioSink = "alsa_output.pci-0000_01_00.1.hdmi-stereo";
      reverseSsh = config.modules.services.reverse-ssh;
      autosshRemoteHost = reverseSsh.remoteHost;
      autosshRemotePort = reverseSsh.remotePort;
      autosshRemoteHostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAHARUNf8QKGEqfBx2pCtJkBp5HEqoBjp9XyqIos07nA";
      cloudflaredReadyUrl = "http://127.0.0.1:20241/ready";
      gatusPort = 8080;
      statusLabels = service: {
        inherit service;
        environment = "production";
        owner = userName;
      };
      cloudflaredReadyCheck = ''
        ${pkgs.curl}/bin/curl --fail --silent --show-error --max-time 5 ${escapeShellArg cloudflaredReadyUrl} >/dev/null
      '';
      autosshEndpointKeyCheck = ''
        remote_host=${escapeShellArg autosshRemoteHost}
        remote_port=${toString autosshRemotePort}
        expected_key_file=/etc/ssh/ssh_host_ed25519_key.pub

        if [ ! -r "$expected_key_file" ]; then
          printf 'autossh healthcheck: missing local SSH host key %s\n' "$expected_key_file" >&2
          exit 1
        fi

        expected_key="$(${pkgs.coreutils}/bin/cut -d ' ' -f 1,2 "$expected_key_file")"
        remote_scan_cmd="timeout 8 ssh-keyscan -T 5 -p $remote_port 127.0.0.1 2>/dev/null"
        remote_scan="$(${pkgs.util-linux}/bin/runuser -u ${escapeShellArg userName} -- \
          ${pkgs.coreutils}/bin/env HOME=${escapeShellArg userHome} \
          ${pkgs.openssh}/bin/ssh \
            -o BatchMode=yes \
            -o ConnectTimeout=8 \
            -o StrictHostKeyChecking=yes \
            -o UpdateHostKeys=no \
            root@"$remote_host" "$remote_scan_cmd" 2>/dev/null || true)"
        remote_key="$(printf '%s\n' "$remote_scan" \
          | ${pkgs.gnugrep}/bin/grep -m1 'ssh-ed25519 ' \
          | ${pkgs.gnused}/bin/sed 's/^[^[:space:]]*[[:space:]]//' || true)"

        if [ "$remote_key" = "$expected_key" ]; then
          exit 0
        fi

        listener="$(${pkgs.util-linux}/bin/runuser -u ${escapeShellArg userName} -- \
          ${pkgs.coreutils}/bin/env HOME=${escapeShellArg userHome} \
          ${pkgs.openssh}/bin/ssh \
            -o BatchMode=yes \
            -o ConnectTimeout=8 \
            -o StrictHostKeyChecking=yes \
            -o UpdateHostKeys=no \
            root@"$remote_host" \
            "ss -H -ltnp '( sport = :$remote_port )' 2>/dev/null || true" 2>/dev/null || true)"

        if [ -n "$listener" ]; then
          printf 'remote listener evidence on %s:%s: %s\n' "$remote_host" "$remote_port" "$listener" >&2
        else
          printf 'remote listener evidence on %s:%s: none or unreachable\n' "$remote_host" "$remote_port" >&2
        fi

        exit 1
      '';
      clashVergeServiceCheck = ''
        healthy=false
        if ${pkgs.systemd}/bin/systemctl is-active --quiet clash-verge.service; then
          main_pid="$(${pkgs.systemd}/bin/systemctl show -P MainPID clash-verge.service 2>/dev/null || printf '0')"
          if [ "$main_pid" != "0" ] \
              && ${pkgs.procps}/bin/pgrep -P "$main_pid" -f 'verge-mihomo|mihomo|clash' >/dev/null 2>&1; then
            healthy=true
          fi
          if ${pkgs.iproute2}/bin/ip link show Mihomo >/dev/null 2>&1 \
              || ${pkgs.iproute2}/bin/ip link show Meta >/dev/null 2>&1; then
            healthy=true
          fi
        fi

        if [ "$healthy" = true ]; then
          exit 0
        fi

        exit 1
      '';
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
      caelestiaLauncherDataDirs = makeSearchPath "share" (
        unique (config.users.users.${config.user.name}.packages
          ++ config.environment.systemPackages)
      );
      ensureCaelestiaSettings = pkgs.writeShellScript "axiom-ensure-caelestia-settings" ''
        set -eu

        config_dir=${escapeShellArg "${config.home.configDir}/caelestia"}
        config_path="$config_dir/shell.json"
        launcher_id=${escapeShellArg feishuLauncherId}
        legacy_desktop_id=${escapeShellArg legacyFeishuDesktopId}
        idle_json=${escapeShellArg (toJSON caelestiaIdleSettings)}

        ${pkgs.coreutils}/bin/install -d -m 0755 "$config_dir"
        if [ ! -s "$config_path" ]; then
          printf '{}\n' > "$config_path"
        fi

        tmp="$(${pkgs.coreutils}/bin/mktemp "$config_path.XXXXXX")"
        trap '${pkgs.coreutils}/bin/rm -f "$tmp"' EXIT

        if ! ${pkgs.jq}/bin/jq --arg app "$launcher_id" --arg legacy "$legacy_desktop_id" --argjson idle "$idle_json" '
          .general = (.general // {})
          | .general.idle = $idle
          | .launcher = (.launcher // {})
          | .launcher.favouriteApps = ((.launcher.favouriteApps // []) as $apps
              | ($apps | map(select(. != $legacy))) as $normalized
              | if ($normalized | index($app)) then $normalized else $normalized + [$app] end)
        ' "$config_path" > "$tmp"; then
          printf 'axiom-ensure-caelestia-settings: unable to update %s\n' "$config_path" >&2
          exit 0
        fi

        if ! ${pkgs.diffutils}/bin/cmp -s "$tmp" "$config_path"; then
          ${pkgs.coreutils}/bin/install -m 0644 "$tmp" "$config_path"
        fi
      '';
      ensureAxiomHdmiAudio = pkgs.writeShellScript "axiom-ensure-hdmi-audio" ''
        set -eu

        # A stray real PulseAudio daemon can autospawn and hold hdmi:0 before
        # PipeWire creates the HDMI sink.
        ${pkgs.procps}/bin/pkill -x pulseaudio || true

        for _ in $(${pkgs.coreutils}/bin/seq 1 20); do
          if ${pkgs.pulseaudio}/bin/pactl list short cards \
              | ${pkgs.gnugrep}/bin/grep -F -q ${escapeShellArg axiomHdmiAudioCard}; then
            break
          fi
          ${pkgs.coreutils}/bin/sleep 0.25
        done

        ${pkgs.pulseaudio}/bin/pactl set-card-profile ${escapeShellArg axiomHdmiAudioCard} off || true
        ${pkgs.pulseaudio}/bin/pactl set-card-profile ${escapeShellArg axiomHdmiAudioCard} output:hdmi-stereo
        ${pkgs.pulseaudio}/bin/pactl set-default-sink ${escapeShellArg axiomHdmiAudioSink}
      '';
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
      session = {
        extraPath = [ opencodeDir ];
        preStart = [ "${ensureCaelestiaSettings}" ];
        xdgDataDirs = caelestiaLauncherDataDirs;
      };
    };

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
      todesk
      uv
    ];

    user.extraGroups = [ "kvm" "libvirtd" ];

    environment.systemPackages = with pkgs; [
      virt-viewer
      virtio-win
    ];

    programs.virt-manager.enable = true;

    virtualisation.libvirtd = {
      enable = true;
      qemu.swtpm.enable = true;
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/todesk 0700 ${userName} ${config.user.group} - -"
    ];

    systemd.services.todesk = {
      description = "ToDesk background service";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = userName;
        WorkingDirectory = userHome;
        ExecStart = "${pkgs.todesk}/bin/todesk service";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        var login1PowerActions = {
          "org.freedesktop.login1.hibernate": true,
          "org.freedesktop.login1.hibernate-multiple-sessions": true,
          "org.freedesktop.login1.power-off": true,
          "org.freedesktop.login1.power-off-multiple-sessions": true,
          "org.freedesktop.login1.reboot": true,
          "org.freedesktop.login1.reboot-multiple-sessions": true,
          "org.freedesktop.login1.suspend": true,
          "org.freedesktop.login1.suspend-multiple-sessions": true
        };
        var networkManagerActions = {
          "org.freedesktop.NetworkManager.enable-disable-network": true,
          "org.freedesktop.NetworkManager.enable-disable-wifi": true,
          "org.freedesktop.NetworkManager.network-control": true,
          "org.freedesktop.NetworkManager.settings.modify.own": true,
          "org.freedesktop.NetworkManager.settings.modify.system": true,
          "org.freedesktop.NetworkManager.wifi.scan": true
        };

        if (subject.local == true && subject.user == "${config.user.name}"
            && (login1PowerActions[action.id] || networkManagerActions[action.id])) {
          return polkit.Result.YES;
        }
      });
    '';

    # ISSUE: https://discourse.nixos.org/t/logrotate-config-fails-due-to-missing-group-30000/28501
    services.logrotate.checkConfig = false;

    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 20;
      memoryMax = 8589934592;
      priority = 100;
    };

    services.pipewire.wireplumber.extraConfig."51-axiom-audio-priority" = {
      "monitor.alsa.rules" = [
        {
          matches = [{
            "node.name" = axiomHdmiAudioSink;
          }];
          actions.update-props = {
            "priority.driver" = 1100;
            "priority.session" = 1100;
          };
        }
        {
          matches = [{
            "node.name" = "alsa_output.pci-0000_11_00.6.iec958-stereo";
          }];
          actions.update-props = {
            "priority.driver" = 100;
            "priority.session" = 100;
          };
        }
      ];
    };

    home.configFile."pulse/client.conf" = {
      force = true;
      text = ''
        autospawn = no
      '';
    };

    systemd.user.services.axiom-hdmi-audio = {
      wantedBy = [ "graphical-session.target" ];
      unitConfig = {
        Description = "Ensure axiom HDMI audio output exists";
        After = [ "pipewire.service" "pipewire-pulse.service" "wireplumber.service" ];
        Wants = [ "pipewire.service" "pipewire-pulse.service" "wireplumber.service" ];
        Before = [ "easyeffects.service" ];
        PartOf = [ "graphical-session.target" ];
      };
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${ensureAxiomHdmiAudio}";
      };
    };

    systemd.user.services.easyeffects.unitConfig = {
      After = mkAfter [ "axiom-hdmi-audio.service" ];
      Wants = mkAfter [ "axiom-hdmi-audio.service" ];
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
        check = cloudflaredReadyCheck;
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
        check = autosshEndpointKeyCheck;
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
        check = clashVergeServiceCheck;
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

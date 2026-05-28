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
        mode = "stretch";
        path = "/home/c1/the-great-sage.jpg";
      };
    };
    xdg.ssh.enable = true;

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
            cm_enabled = false
          }

          misc {
            # Permit relaunching the Caelestia WlSessionLock client if it exits.
            allow_session_lock_restore = true
          }
        '';
        monitors = [{
          mode = "3840x2160@60";
          position = "0x0";
          scale = 1.5;
        }];
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
      fs.enable = true;
    };
  };

  ## Local config
  config = { config, pkgs, ... }:
    let
      opencodeDir = "${config.user.home}/.opencode";
      axiomHdmiAudioCard = "alsa_card.pci-0000_01_00.1";
      axiomHdmiAudioSink = "alsa_output.pci-0000_01_00.1.hdmi-stereo";
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
      autossh
      feishu
      git-lfs
      htop
      k9s
      kubectl
      nvtopPackages.nvidia
      todesk
      uv
    ];

    systemd.tmpfiles.rules = [
      "d /var/lib/todesk 0700 c1 users - -"
    ];

    systemd.services.todesk = {
      description = "ToDesk background service";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = "c1";
        WorkingDirectory = "/home/c1";
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

    programs.ssh.startAgent = true;
    services.openssh.startWhenNeeded = mkForce false;
    # ISSUE: https://discourse.nixos.org/t/logrotate-config-fails-due-to-missing-group-30000/28501
    services.logrotate.checkConfig = false;

    services.pipewire.wireplumber.extraConfig."51-axiom-audio-priority" = {
      "monitor.alsa.rules" = [
        {
          matches = [{
            "node.name" = "alsa_output.pci-0000_01_00.1.hdmi-stereo";
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

    modules.shell.zsh.envInit = mkBefore ''
      path=( "${opencodeDir}/bin" "''${path[@]}" )
      typeset -U path PATH
    '';

    modules.agenix.sshKey = "/etc/ssh/ssh_host_ed25519_key";

    systemd.services.opencode-server = {
      description = "Opencode server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      environment = {
        HOME = "/home/c1";
        OPENCODE_ENABLE_EXA = "1";
        OPENCODE_EXPERIMENTAL = "true";
      };
      serviceConfig = {
        Type = "simple";
        User = "c1";
        WorkingDirectory = "/home/c1";
        ExecStart = "/home/c1/.opencode/bin/opencode serve --hostname 127.0.0.1 --port 4096";
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };

    systemd.services.autossh-reverse-ssh = {
      description = "Autossh reverse SSH tunnel to 8.159.128.125";
      after = [ "network-online.target" "sshd.service" ];
      wants = [ "network-online.target" "sshd.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.openssh ];
      environment = {
        AUTOSSH_GATETIME = "0";
        HOME = "/home/c1";
      };
      serviceConfig = {
        Type = "simple";
        User = "c1";
        WorkingDirectory = "/home/c1";
        ExecStart = "${pkgs.autossh}/bin/autossh -M 0 -N -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes -o BatchMode=yes -R 127.0.0.1:2223:127.0.0.1:22 root@8.159.128.125";
        Restart = "always";
        RestartSec = "10s";
      };
    };

    modules.services.cloudflared = {
      enable = true;
      tunnelName = "home-axiom";
      tunnelId = "bc8b3291-de93-4f7f-807a-23f802ef021f";
      credentialsFile = ./secrets/cloudflared-credentials.age;
      warpRouting.enabled = false;
      extraConfig = {
        protocol = "http2";
        tunnelName = "home-axiom";
        ingress = [
          {
            hostname = "opencode-axiom.0xc1.space";
            service = "http://127.0.0.1:4096";
          }
          { service = "http_status:404"; }
        ];
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ 22 ];
      allowedUDPPorts = [ 7844 ];
      allowedTCPPortRanges = [{
        from = 49152;
        to = 65535;
      }];
      allowedUDPPortRanges = [{
        from = 49152;
        to = 65535;
      }];
    };
  };

  ## Hardware
  hardware = { ... }: {
    networking = {
      dhcpcd.enable = mkForce false;
      networkmanager = {
        enable = true;
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

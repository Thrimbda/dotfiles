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
        monitors = [{
          mode = "3840x2160@60";
          position = "0x0";
          scale = 1.5;
        }];
      };
      apps = {
        clash-verge.enable = true;
        discord.enable = true;
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
      inherit (hey.lib.pkgs.for pkgs) mkLauncherEntry;
      opencodeDir = "${config.user.home}/.opencode";
      axiomSleepMode = pkgs.writeShellScriptBin "axiom-sleep-mode" ''
        set -euo pipefail

        state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/axiom-power-mode"
        state_file="$state_dir/sleep-mode"
        default_mode="no-sleep"

        current_mode() {
          if [[ -r "$state_file" ]]; then
            case "$(< "$state_file")" in
              no-sleep|allow-sleep) cat "$state_file" ;;
              *) printf '%s\n' "$default_mode" ;;
            esac
          else
            printf '%s\n' "$default_mode"
          fi
        }

        write_mode() {
          mkdir -p "$state_dir"
          printf '%s\n' "$1" > "$state_file"
        }

        notify_mode() {
          if [[ -n "''${DISPLAY:-}" || -n "''${WAYLAND_DISPLAY:-}" ]]; then
            ${pkgs.libnotify}/bin/notify-send "Axiom power mode" "$1" >/dev/null 2>&1 || true
          fi
        }

        apply_mode() {
          case "$(current_mode)" in
            no-sleep)
              ${pkgs.systemd}/bin/systemctl --user start axiom-no-sleep-inhibit.service
              ;;
            allow-sleep)
              ${pkgs.systemd}/bin/systemctl --user stop axiom-no-sleep-inhibit.service || true
              ;;
          esac
        }

        set_mode() {
          write_mode "$1"
          apply_mode
          case "$1" in
            no-sleep) notify_mode "No-sleep mode enabled" ;;
            allow-sleep) notify_mode "Sleep is allowed" ;;
          esac
          status
        }

        maybe_suspend() {
          if [[ "$(current_mode)" == "allow-sleep" ]]; then
            ${pkgs.systemd}/bin/systemctl suspend || ${pkgs.systemd}/bin/loginctl suspend
          else
            notify_mode "Automatic suspend skipped because no-sleep mode is active"
          fi
        }

        status() {
          local inhibitor="inactive"
          if ${pkgs.systemd}/bin/systemctl --user is-active --quiet axiom-no-sleep-inhibit.service; then
            inhibitor="active"
          fi
          printf 'mode=%s\ninhibitor=%s\n' "$(current_mode)" "$inhibitor"
        }

        toggle() {
          if [[ "$(current_mode)" == "no-sleep" ]]; then
            set_mode allow-sleep
          else
            set_mode no-sleep
          fi
        }

        case "''${1:-status}" in
          no-sleep) set_mode no-sleep ;;
          allow-sleep) set_mode allow-sleep ;;
          toggle) toggle ;;
          apply) apply_mode ;;
          maybe-suspend) maybe_suspend ;;
          status) status ;;
          *)
            printf 'usage: axiom-sleep-mode {no-sleep|allow-sleep|toggle|apply|maybe-suspend|status}\n' >&2
            exit 2
            ;;
        esac
      '';
    in {
    modules.desktop.input.fcitx5.theme = {
      enable = true;
      name = "FluentDark";
      package = pkgs.fcitx5-fluent;
    };

    user.packages = with pkgs; [
      axiomSleepMode
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
      (mkLauncherEntry "Power Mode: No Sleep" {
        icon = "system-suspend";
        exec = "axiom-sleep-mode no-sleep";
        categories = [ "Settings" "System" ];
      })
      (mkLauncherEntry "Power Mode: Allow Sleep" {
        icon = "system-suspend";
        exec = "axiom-sleep-mode allow-sleep";
        categories = [ "Settings" "System" ];
      })
      (mkLauncherEntry "Power Mode: Toggle Sleep" {
        icon = "system-suspend";
        exec = "axiom-sleep-mode toggle";
        categories = [ "Settings" "System" ];
      })
    ];

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

    modules.shell.zsh.envInit = mkBefore ''
      path=( "${opencodeDir}/bin" "''${path[@]}" )
      typeset -U path PATH
    '';

    home.configFile."hypr/hypridle.conf".text = ''
      # Generated by NixOS for Axiom sleep-mode policy.
      $lock_cmd = pidof hyprlock || hyprlock
      $suspend_cmd = axiom-sleep-mode maybe-suspend

      general {
          lock_cmd = $lock_cmd
          before_sleep_cmd = $lock_cmd
          after_sleep_cmd = hyprctl dispatch dpms on
          inhibit_sleep = 3
      }

      listener {
          timeout = 300 # 5mins
          on-timeout = $lock_cmd
      }

      listener {
          timeout = 600 # 10mins
          on-timeout = hyprctl dispatch dpms off
          on-resume = hyprctl dispatch dpms on
      }

      listener {
          timeout = 900 # 15mins
          on-timeout = $suspend_cmd
      }
    '';

    systemd.user.services.axiom-no-sleep-inhibit = {
      description = "Axiom no-sleep power mode inhibitor";
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.systemd}/bin/systemd-inhibit --what=sleep --mode=block --who=axiom-sleep-mode --why=Axiom-no-sleep-power-mode ${pkgs.coreutils}/bin/sleep infinity";
        Restart = "on-failure";
        RestartSec = 2;
      };
    };

    systemd.user.services.axiom-sleep-mode-apply = {
      description = "Apply Axiom sleep-mode state";
      wantedBy = [ "hyprland-session.target" ];
      after = [ "hyprland-session.target" ];
      partOf = [ "hyprland-session.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${axiomSleepMode}/bin/axiom-sleep-mode apply";
      };
    };

    systemd.user.services.caelestia-shell.path = mkBefore [ opencodeDir ];

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

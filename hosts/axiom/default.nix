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
      rustdeskVersion = "1.4.9";
      rustdeskHost = "rustdesk.0xc1.wang";
      rustdeskUser = config.users.users.${userName};
      rustdeskUserUid = rustdeskUser.uid;
      rustdeskRuntimeStabilitySeconds = 30;
      rustdeskRuntimeEnvironment = {
        HOME = "/root";
        XDG_CONFIG_HOME = "/root/.config";
        DISPLAY = ":0";
        WAYLAND_DISPLAY = "wayland-1";
        XDG_RUNTIME_DIR = "/run/user/${toString rustdeskUserUid}";
        DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/${toString rustdeskUserUid}/bus";
        XDG_CURRENT_DESKTOP = "Hyprland";
        XDG_SESSION_TYPE = "wayland";
        GST_PLUGIN_SYSTEM_PATH_1_0 = "${pkgs.pipewire}/lib/gstreamer-1.0";
        PIPEWIRE_LATENCY = "1024/48000";
        PULSE_LATENCY_MSEC = "60";
      };
      rustdeskSourceHash = "sha256-AnwdIO4TveC48uMioBCvH60xun24ckK420ONSEB9lQI=";
      rustdeskCargoHash = "sha256-HPvvsTcjSErGfdNwsHgWhs930Fe0hmK1g5J/ngtlkKM=";
      rustdeskWaylandPatch = ./rustdesk-wayland-output.patch;
      rustdeskSource = pkgs.unstable.fetchFromGitHub {
        owner = "rustdesk";
        repo = "rustdesk";
        rev = "6c578292e8ebbbec708b76986ba8c4bc7c509747";
        fetchSubmodules = true;
        hash = rustdeskSourceHash;
      };
      rustdeskCargoDeps = pkgs.unstable.rustPlatform.fetchCargoVendor {
        name = "rustdesk-${rustdeskVersion}";
        src = rustdeskSource;
        hash = rustdeskCargoHash;
      };
      rustdeskPackage = pkgs.unstable.rustdesk.overrideAttrs (_finalAttrs: previousAttrs: {
        version = rustdeskVersion;
        src = rustdeskSource;
        cargoHash = rustdeskCargoHash;
        cargoDeps = rustdeskCargoDeps;
        patches = (previousAttrs.patches or [ ]) ++ [ rustdeskWaylandPatch ];
      });
      rustdeskSecret = config.age.secrets.rustdesk-password;
      rustdeskSecretMetadata =
        "${rustdeskSecret.owner}:${rustdeskSecret.group}:${removePrefix "0" rustdeskSecret.mode}";
      rustdeskPublicKey = removeSuffix "\n" (readFile ../acorn/secrets/rustdesk-server-key.pub);
      rustdeskPublicConfig = pkgs.writeShellScript "axiom-rustdesk-public-config" ''
        set -eu
        umask 077

        rustdesk=${rustdeskPackage}/bin/rustdesk
        timeout=${pkgs.coreutils}/bin/timeout

        context=$(${pkgs.coreutils}/bin/mktemp -d \
          /tmp/axiom-rustdesk-public-config.XXXXXX)
        home=$context/home
        config_home=$context/config
        # Invoked indirectly by the EXIT trap.
        # shellcheck disable=SC2329
        cleanup() {
          ${pkgs.coreutils}/bin/rm -rf -- "$context"
        }
        trap cleanup EXIT
        trap 'exit 1' HUP INT TERM

        ${pkgs.coreutils}/bin/chmod 0700 "$context"
        ${pkgs.coreutils}/bin/install -d -m 0700 -o root -g root \
          "$home" "$config_home"
        for directory in "$context" "$home" "$config_home"; do
          metadata=$(${pkgs.coreutils}/bin/stat --format='%u:%g:%a' \
            -- "$directory" 2>/dev/null) || exit 1
          [ "$metadata" = 0:0:700 ] || exit 1
        done

        quiet=0
        case "''${1:-}" in
          apply-server)
            quiet=1
            set -- --config \
              "rustdesk-host=${rustdeskHost},key=${rustdeskPublicKey},relay=${rustdeskHost}"
            ;;
          apply-verification-method)
            quiet=1
            set -- --option verification-method use-permanent-password
            ;;
          apply-approve-mode)
            quiet=1
            set -- --option approve-mode password
            ;;
          apply-auto-update)
            quiet=1
            set -- --option allow-auto-update N
            ;;
          query-host)
            set -- --option custom-rendezvous-server
            ;;
          query-key)
            set -- --option key
            ;;
          query-relay)
            set -- --option relay-server
            ;;
          query-verification-method)
            set -- --option verification-method
            ;;
          query-approve-mode)
            set -- --option approve-mode
            ;;
          query-auto-update)
            set -- --option allow-auto-update
            ;;
          *)
            exit 2
            ;;
        esac

        status=0
        if [ "$quiet" -eq 1 ]; then
          HOME="$home" XDG_CONFIG_HOME="$config_home" \
            ${pkgs.coreutils}/bin/env \
            "$timeout" --signal=TERM --kill-after=5s 15s \
            "$rustdesk" "$@" >/dev/null 2>&1 || status=$?
        else
          HOME="$home" XDG_CONFIG_HOME="$config_home" \
            ${pkgs.coreutils}/bin/env \
            "$timeout" --signal=TERM --kill-after=5s 15s \
            "$rustdesk" "$@" 2>/dev/null || status=$?
        fi
        exit "$status"
      '';
      rustdeskRevisionValue = "axiom-rustdesk-provision-v4:${hashString "sha256" ''
        package=${rustdeskPackage}
        version=${rustdeskVersion}
        source=${rustdeskSourceHash}
        cargo=${rustdeskCargoHash}
        public-config=${rustdeskPublicConfig}
        provision=axiom-rustdesk-provision-v8
        ready-to-finalize=axiom-rustdesk-ready-v1
        manual-finalize=axiom-rustdesk-finalize-v2
        runtime-contract=axiom-rustdesk-runtime-v1
        runtime-stability-seconds=${toString rustdeskRuntimeStabilitySeconds}
        resolver=${rustdeskHost}:${acornPublicIp}
        service-environment=${builtins.toJSON rustdeskRuntimeEnvironment}
        ciphertext=${./secrets/rustdesk-password.age}
      ''}";
      rustdeskRevision = pkgs.writeText "axiom-rustdesk-revision" ''
        ${rustdeskRevisionValue}
      '';
      rustdeskProvision = pkgs.writeShellScript "axiom-rustdesk-provision" ''
        set -eu
        umask 077

        rustdesk=${rustdeskPackage}/bin/rustdesk
        rustdesk_server_exe=${rustdeskPackage}/lib/rustdesk/rustdesk
        rustdesk_user=${escapeShellArg userName}
        password_home=/root
        password_config_home=/root/.config
        state=/var/lib/rustdesk-provision
        stamp=$state/stamp
        reservation=$state/attempt
        ready=$state/ready-to-finalize
        operation_lock=$state/operation.lock
        revision_prefix=axiom-rustdesk-provision-v4:
        current_revision=${escapeShellArg rustdeskRevisionValue}
        object_tmp=
        ready_tmp=
        ready_cleanup_required=0
        result=
        cleanup() {
          [ -z "$result" ] || ${pkgs.coreutils}/bin/rm -f "$result"
          [ -z "$object_tmp" ] || ${pkgs.coreutils}/bin/rm -f "$object_tmp"
          [ -z "$ready_tmp" ] || ${pkgs.coreutils}/bin/rm -f "$ready_tmp"
          if [ "$ready_cleanup_required" -eq 1 ]; then
            remove_current_ready >/dev/null 2>&1 || true
          fi
        }
        trap cleanup EXIT
        trap 'exit 1' HUP INT TERM
        fail() { echo "RustDesk provisioning failed: $1" >&2; exit 1; }

        validate_state_directory() {
          [ -d "$state" ] && [ ! -L "$state" ] || return 1
          metadata=$(${pkgs.coreutils}/bin/stat --format='%u:%g:%a' \
            -- "$state" 2>/dev/null) || return 1
          [ "$metadata" = 0:0:700 ]
        }

        validate_operation_lock() {
          [ -f "$operation_lock" ] && [ ! -L "$operation_lock" ] \
            || return 1
          metadata=$(${pkgs.coreutils}/bin/stat \
            --format='%u:%g:%a:%s:%h' -- "$operation_lock" 2>/dev/null) \
            || return 1
          [ "$metadata" = 0:0:600:0:1 ]
        }

        acquire_operation_lock() {
          [ "$(${pkgs.coreutils}/bin/id -u)" = 0 ] || return 1
          validate_state_directory || return 1
          if [ ! -e "$operation_lock" ] && [ ! -L "$operation_lock" ]; then
            ( set -C; : > "$operation_lock" ) 2>/dev/null || true
          fi
          validate_operation_lock || return 1
          exec 9<> "$operation_lock" || return 1
          ${pkgs.util-linux}/bin/flock --nonblock 9 || {
            exec 9>&-
            return 1
          }
          path_identity=$(${pkgs.coreutils}/bin/stat \
            --format='%d:%i:%u:%g:%a:%s:%h' \
            -- "$operation_lock" 2>/dev/null) || return 1
          fd_identity=$(${pkgs.coreutils}/bin/stat --dereference \
            --format='%d:%i:%u:%g:%a:%s:%h' \
            -- /proc/self/fd/9 2>/dev/null) || return 1
          [ "$path_identity" = "$fd_identity" ] \
            && validate_operation_lock
        }

        inspect_revision_object() {
          object_path=$1
          object_state=
          if [ ! -e "$object_path" ] && [ ! -L "$object_path" ]; then
            object_state=absent
            return 0
          fi

          [ -f "$object_path" ] && [ ! -L "$object_path" ] || return 1
          metadata=$(${pkgs.coreutils}/bin/stat --format='%u:%g:%a' \
            -- "$object_path" 2>/dev/null) || return 1
          [ "$metadata" = 0:0:600 ] || return 1

          bytes=$(${pkgs.coreutils}/bin/wc -c < "$object_path") || return 1
          object_value=
          IFS= read -r object_value < "$object_path" || return 1
          [ "$bytes" -eq $(( ''${#object_value} + 1 )) ] || return 1
          case "$object_value" in
            "$revision_prefix"*)
              object_digest=''${object_value#"$revision_prefix"}
              ;;
            *)
              return 1
              ;;
          esac
          [ "''${#object_digest}" -eq 64 ] || return 1
          case "$object_digest" in *[!0-9a-f]*) return 1 ;; esac

          if ${pkgs.diffutils}/bin/cmp -s \
            "$object_path" ${rustdeskRevision}; then
            object_state=current
          else
            object_state=stale
          fi
        }

        publish_revision_object() {
          publish_object_path=$1
          object_name=$2
          object_tmp=$(${pkgs.coreutils}/bin/mktemp \
            "$state/$object_name.tmp.XXXXXX") || return 1
          ${pkgs.coreutils}/bin/install -m 0600 -o root -g root \
            ${rustdeskRevision} "$object_tmp" || return 1
          inspect_revision_object "$object_tmp" || return 1
          [ "$object_state" = current ] || return 1
          ${pkgs.coreutils}/bin/timeout --signal=TERM --kill-after=5s 15s \
            ${pkgs.coreutils}/bin/sync -f "$object_tmp" || return 1
          ${pkgs.coreutils}/bin/mv -fT -- "$object_tmp" "$publish_object_path" \
            || return 1
          object_tmp=
          ${pkgs.coreutils}/bin/timeout --signal=TERM --kill-after=5s 15s \
            ${pkgs.coreutils}/bin/sync -f "$state" || return 1
          inspect_revision_object "$publish_object_path" || return 1
          [ "$object_state" = current ]
        }

        inspect_ready_object() {
          ready_path=$1
          ready_state=
          if [ ! -e "$ready_path" ] && [ ! -L "$ready_path" ]; then
            ready_state=absent
            return 0
          fi

          [ -f "$ready_path" ] && [ ! -L "$ready_path" ] || return 1
          metadata=$(${pkgs.coreutils}/bin/stat --format='%u:%g:%a:%h' \
            -- "$ready_path" 2>/dev/null) || return 1
          [ "$metadata" = 0:0:600:1 ] || return 1
          ready_line_count=$(${pkgs.coreutils}/bin/wc -l < "$ready_path") \
            || return 1
          [ "$ready_line_count" -eq 11 ] || return 1

          exec 4< "$ready_path" || return 1
          IFS= read -r ready_line1 <&4 || { exec 4<&-; return 1; }
          IFS= read -r ready_line2 <&4 || { exec 4<&-; return 1; }
          IFS= read -r ready_line3 <&4 || { exec 4<&-; return 1; }
          IFS= read -r ready_line4 <&4 || { exec 4<&-; return 1; }
          IFS= read -r ready_line5 <&4 || { exec 4<&-; return 1; }
          IFS= read -r ready_line6 <&4 || { exec 4<&-; return 1; }
          IFS= read -r ready_line7 <&4 || { exec 4<&-; return 1; }
          IFS= read -r ready_line8 <&4 || { exec 4<&-; return 1; }
          IFS= read -r ready_line9 <&4 || { exec 4<&-; return 1; }
          IFS= read -r ready_line10 <&4 || { exec 4<&-; return 1; }
          IFS= read -r ready_line11 <&4 || { exec 4<&-; return 1; }
          if IFS= read -r _ <&4; then
            exec 4<&-
            return 1
          fi
          exec 4<&-

          ready_bytes=$(${pkgs.coreutils}/bin/wc -c < "$ready_path") \
            || return 1
          ready_expected_bytes=$((
            ''${#ready_line1} + ''${#ready_line2} + ''${#ready_line3} \
            + ''${#ready_line4} + ''${#ready_line5} + ''${#ready_line6} \
            + ''${#ready_line7} + ''${#ready_line8} + ''${#ready_line9} \
            + ''${#ready_line10} + ''${#ready_line11} + 11
          ))
          [ "$ready_bytes" -eq "$ready_expected_bytes" ] || return 1
          [ "$ready_line1" = format=rustdesk-ready-v1 ] || return 1
          [ "$ready_line2" = host=axiom ] || return 1

          case "$ready_line3" in revision=*) ;; *) return 1 ;; esac
          ready_revision=''${ready_line3#revision=}
          case "$ready_revision" in
            "$revision_prefix"*)
              ready_digest=''${ready_revision#"$revision_prefix"}
              ;;
            *)
              return 1
              ;;
          esac
          [ "''${#ready_digest}" -eq 64 ] || return 1
          case "$ready_digest" in *[!0-9a-f]*) return 1 ;; esac

          case "$ready_line4" in main.pid=*) ;; *) return 1 ;; esac
          ready_main_pid=''${ready_line4#main.pid=}
          case "$ready_main_pid" in ""|*[!0-9]*) return 1 ;; esac
          [ "$ready_main_pid" -gt 1 ] || return 1
          case "$ready_line5" in main.start=*) ;; *) return 1 ;; esac
          ready_main_start=''${ready_line5#main.start=}
          case "$ready_main_start" in ""|*[!0-9]*) return 1 ;; esac
          [ "$ready_main_start" -gt 0 ] || return 1
          case "$ready_line6" in main.executable=*) ;; *) return 1 ;; esac
          ready_main_exe=''${ready_line6#main.executable=}
          case "$ready_main_exe" in
            /nix/store/*/lib/rustdesk/rustdesk) ;;
            *) return 1 ;;
          esac
          case "$ready_line7" in main.uid=*) ;; *) return 1 ;; esac
          ready_main_uid=''${ready_line7#main.uid=}
          [ "$ready_main_uid" = 0 ] || return 1

          case "$ready_line8" in server.pid=*) ;; *) return 1 ;; esac
          ready_server_pid=''${ready_line8#server.pid=}
          case "$ready_server_pid" in ""|*[!0-9]*) return 1 ;; esac
          [ "$ready_server_pid" -gt 1 ] || return 1
          case "$ready_line9" in server.start=*) ;; *) return 1 ;; esac
          ready_server_start=''${ready_line9#server.start=}
          case "$ready_server_start" in ""|*[!0-9]*) return 1 ;; esac
          [ "$ready_server_start" -gt 0 ] || return 1
          case "$ready_line10" in server.executable=*) ;; *) return 1 ;; esac
          ready_server_exe=''${ready_line10#server.executable=}
          case "$ready_server_exe" in
            /nix/store/*/lib/rustdesk/rustdesk) ;;
            *) return 1 ;;
          esac
          case "$ready_line11" in server.uid=*) ;; *) return 1 ;; esac
          ready_server_uid=''${ready_line11#server.uid=}
          case "$ready_server_uid" in ""|*[!0-9]*) return 1 ;; esac
          [ "$ready_server_uid" -gt 0 ] || return 1

          if [ "$ready_revision" = "$current_revision" ]; then
            expected_server_uid=$(${pkgs.coreutils}/bin/id -u \
              "$rustdesk_user" 2>/dev/null) || return 1
            [ "$ready_main_exe" = "$rustdesk_server_exe" ] \
              && [ "$ready_server_exe" = "$rustdesk_server_exe" ] \
              && [ "$ready_server_uid" = "$expected_server_uid" ] \
              || return 1
            ready_state=current
          else
            ready_state=stale
          fi
        }

        remove_ready_object() {
          expected_ready_state=$1
          inspect_ready_object "$ready" || return 1
          [ "$ready_state" = "$expected_ready_state" ] || return 1
          ${pkgs.coreutils}/bin/rm -f -- "$ready" || return 1
          ${pkgs.coreutils}/bin/timeout --signal=TERM --kill-after=5s 15s \
            ${pkgs.coreutils}/bin/sync -f "$state" || return 1
          inspect_ready_object "$ready" || return 1
          [ "$ready_state" = absent ]
        }

        remove_current_ready() {
          inspect_ready_object "$ready" || return 1
          case "$ready_state" in
            absent) return 0 ;;
            current) remove_ready_object current ;;
            *) return 1 ;;
          esac
        }

        publish_ready_object() {
          publish_main_pid=$1
          publish_main_start=$2
          publish_main_exe=$3
          publish_main_uid=$4
          publish_server_pid=$5
          publish_server_start=$6
          publish_server_exe=$7
          publish_server_uid=$8

          inspect_ready_object "$ready" || return 1
          [ "$ready_state" = absent ] || return 1
          ready_tmp=$(${pkgs.coreutils}/bin/mktemp \
            "$state/ready-to-finalize.tmp.XXXXXX") || return 1
          ${pkgs.coreutils}/bin/printf '%s\n' \
            format=rustdesk-ready-v1 \
            host=axiom \
            "revision=$current_revision" \
            "main.pid=$publish_main_pid" \
            "main.start=$publish_main_start" \
            "main.executable=$publish_main_exe" \
            "main.uid=$publish_main_uid" \
            "server.pid=$publish_server_pid" \
            "server.start=$publish_server_start" \
            "server.executable=$publish_server_exe" \
            "server.uid=$publish_server_uid" > "$ready_tmp" || return 1
          ${pkgs.coreutils}/bin/chmod 0600 "$ready_tmp" || return 1
          ${pkgs.coreutils}/bin/chown root:root "$ready_tmp" || return 1
          inspect_ready_object "$ready_tmp" || return 1
          [ "$ready_state" = current ] || return 1
          ${pkgs.coreutils}/bin/timeout --signal=TERM --kill-after=5s 15s \
            ${pkgs.coreutils}/bin/sync -f "$ready_tmp" || return 1
          ready_cleanup_required=1
          ${pkgs.coreutils}/bin/mv -fT -- "$ready_tmp" "$ready" || return 1
          ready_tmp=
          ${pkgs.coreutils}/bin/timeout --signal=TERM --kill-after=5s 15s \
            ${pkgs.coreutils}/bin/sync -f "$state" || return 1
          inspect_ready_object "$ready" || return 1
          [ "$ready_state" = current ]
        }

        resolve_secret() {
          configured=${escapeShellArg rustdeskSecret.path}
          target=$(${pkgs.coreutils}/bin/readlink -e -- "$configured" 2>/dev/null) \
            || return 1
          [ -n "$target" ] && [ -f "$target" ] && [ ! -L "$target" ] \
            || return 1
          metadata=$(${pkgs.coreutils}/bin/stat --format='%U:%G:%a' -- "$target" 2>/dev/null) \
            || return 1
          [ "$metadata" = ${escapeShellArg rustdeskSecretMetadata} ] \
            || return 1
          [ -r "$target" ] || return 1
          printf '%s\n' "$target"
        }

        prepare_password_context() {
          [ -d "$password_home" ] && [ ! -L "$password_home" ] \
            || return 1
          metadata=$(${pkgs.coreutils}/bin/stat --format='%u:%g' \
            -- "$password_home" 2>/dev/null) || return 1
          [ "$metadata" = 0:0 ] || return 1

          if [ -e "$password_config_home" ] \
            || [ -L "$password_config_home" ]; then
            [ -d "$password_config_home" ] \
              && [ ! -L "$password_config_home" ] || return 1
          else
            ${pkgs.coreutils}/bin/install -d -m 0700 -o root -g root \
              "$password_config_home" || return 1
          fi
          metadata=$(${pkgs.coreutils}/bin/stat --format='%u:%g' \
            -- "$password_config_home" 2>/dev/null) || return 1
          [ "$metadata" = 0:0 ]
        }

        proc_start_identity() {
          identity_pid=$1
          identity_line=
          IFS= read -r identity_line < "/proc/$identity_pid/stat" \
            || [ -n "$identity_line" ] || return 1
          identity_stat_pid=''${identity_line%% *}
          [ "$identity_stat_pid" = "$identity_pid" ] || return 1
          identity_tail=''${identity_line##*) }
          [ "$identity_tail" != "$identity_line" ] || return 1
          identity_old_ifs=$IFS
          IFS=' '
          set -f
          # Word splitting is intentional for the fixed fields after comm.
          # shellcheck disable=SC2086
          set -- $identity_tail
          set +f
          IFS=$identity_old_ifs
          [ "$#" -ge 20 ] || return 1
          shift 19
          identity_start=$1
          case "$identity_start" in ""|*[!0-9]*) return 1 ;; esac
          [ "$identity_start" -gt 0 ] || return 1
          ${pkgs.coreutils}/bin/printf '%s\n' "$identity_start"
        }

        validate_main_service() {
          main_pid=$(${pkgs.systemd}/bin/systemctl show \
            -p MainPID --value rustdesk.service 2>/dev/null) || return 1
          case "$main_pid" in ""|0|1|*[!0-9]*) return 1 ;; esac
          ${pkgs.systemd}/bin/systemctl is-active --quiet rustdesk.service \
            || return 1

          [ -d "/proc/$main_pid" ] && [ ! -L "/proc/$main_pid" ] \
            || return 1
          process_start=$(proc_start_identity "$main_pid") || return 1
          process_uid=$(${pkgs.coreutils}/bin/stat --format='%u' \
            -- "/proc/$main_pid" 2>/dev/null) || return 1
          [ "$process_uid" = 0 ] || return 1
          process_exe=$(${pkgs.coreutils}/bin/readlink -e \
            -- "/proc/$main_pid/exe" 2>/dev/null) || return 1
          [ "$process_exe" = "$rustdesk_server_exe" ] || return 1

          process_args=()
          while IFS= read -r -d "" arg; do
            process_args+=("$arg")
          done < "/proc/$main_pid/cmdline"
          [ "''${#process_args[@]}" -eq 2 ] \
            && [ "''${process_args[1]}" = --service ] || return 1
          process_start_after=$(proc_start_identity "$main_pid") || return 1
          [ "$process_start_after" = "$process_start" ] || return 1
          validated_main_pid=$main_pid
          validated_main_start=$process_start
          validated_main_exe=$process_exe
          validated_main_uid=$process_uid
        }

        validate_user_server() {
          uid=$(${pkgs.coreutils}/bin/id -u "$rustdesk_user" 2>/dev/null) \
            || return 1
          gid=$(${pkgs.coreutils}/bin/id -g "$rustdesk_user" 2>/dev/null) \
            || return 1
          ipc_parent=/tmp/RustDesk-$uid
          ipc=$ipc_parent/ipc
          pid_file=$ipc.pid

          [ -d "$ipc_parent" ] && [ ! -L "$ipc_parent" ] || return 1
          metadata=$(${pkgs.coreutils}/bin/stat --format='%u:%g:%a' -- "$ipc_parent" 2>/dev/null) \
            || return 1
          [ "$metadata" = "$uid:$gid:700" ] || return 1

          [ -S "$ipc" ] && [ ! -L "$ipc" ] || return 1
          metadata=$(${pkgs.coreutils}/bin/stat --format='%u:%g:%a' -- "$ipc" 2>/dev/null) \
            || return 1
          [ "$metadata" = "$uid:$gid:600" ] || return 1

          [ -f "$pid_file" ] && [ ! -L "$pid_file" ] || return 1
          metadata=$(${pkgs.coreutils}/bin/stat --format='%u:%g:%a' -- "$pid_file" 2>/dev/null) \
            || return 1
          [ "$metadata" = "$uid:$gid:600" ] || return 1
          pid_bytes=$(${pkgs.coreutils}/bin/wc -c < "$pid_file") || return 1
          server_pid=
          IFS= read -r server_pid < "$pid_file" \
            || [ -n "$server_pid" ] || return 1
          [ "$pid_bytes" -eq "''${#server_pid}" ] || return 1
          case "$server_pid" in ""|0|1|*[!0-9]*) return 1 ;; esac

          [ -d "/proc/$server_pid" ] && [ ! -L "/proc/$server_pid" ] \
            || return 1
          process_start=$(proc_start_identity "$server_pid") || return 1
          process_uid=$(${pkgs.coreutils}/bin/stat --format='%u' -- "/proc/$server_pid" 2>/dev/null) \
            || return 1
          [ "$process_uid" = "$uid" ] || return 1
          process_exe=$(${pkgs.coreutils}/bin/readlink -e -- "/proc/$server_pid/exe" 2>/dev/null) \
            || return 1
          [ "$process_exe" = "$rustdesk_server_exe" ] || return 1

          process_args=()
          while IFS= read -r -d "" arg; do
            process_args+=("$arg")
          done < "/proc/$server_pid/cmdline"
          [ "''${#process_args[@]}" -eq 2 ] \
            && [ "''${process_args[1]}" = --server ] || return 1

          socket_pid=$(${pkgs.lsof}/bin/lsof -nP -t -a \
            -p "$server_pid" -U -- "$ipc" 2>/dev/null) || return 1
          [ "$socket_pid" = "$server_pid" ] || return 1
          process_start_after=$(proc_start_identity "$server_pid") || return 1
          [ "$process_start_after" = "$process_start" ] || return 1
          validated_server_pid=$server_pid
          validated_server_start=$process_start
          validated_server_exe=$process_exe
          validated_server_uid=$process_uid
        }

        validate_runtime_pids() {
          expected_main_pid=$1
          expected_server_pid=$2
          validate_main_service || return 1
          [ "$validated_main_pid" = "$expected_main_pid" ] || return 1
          validate_user_server || return 1
          [ "$validated_server_pid" = "$expected_server_pid" ]
        }

        validate_ready_runtime() {
          validate_main_service || return 1
          [ "$validated_main_pid" = "$ready_main_pid" ] \
            && [ "$validated_main_start" = "$ready_main_start" ] \
            && [ "$validated_main_exe" = "$ready_main_exe" ] \
            && [ "$validated_main_uid" = "$ready_main_uid" ] \
            || return 1
          validate_user_server || return 1
          [ "$validated_server_pid" = "$ready_server_pid" ] \
            && [ "$validated_server_start" = "$ready_server_start" ] \
            && [ "$validated_server_exe" = "$ready_server_exe" ] \
            && [ "$validated_server_uid" = "$ready_server_uid" ]
        }

        runtime_ready() {
          validate_main_service || return 1
          ready_main_pid=$validated_main_pid
          ready_main_start=$validated_main_start
          validate_user_server || return 1
          ready_server_pid=$validated_server_pid
          ready_server_start=$validated_server_start
        }

        wait_runtime() {
          attempt=0
          while [ "$attempt" -lt 60 ]; do
            if runtime_ready; then
              candidate_main_pid=$ready_main_pid
              candidate_main_start=$ready_main_start
              candidate_server_pid=$ready_server_pid
              candidate_server_start=$ready_server_start
              ${pkgs.coreutils}/bin/sleep ${toString rustdeskRuntimeStabilitySeconds}
              if validate_runtime_pids \
                "$candidate_main_pid" "$candidate_server_pid" \
                && [ "$validated_main_start" = "$candidate_main_start" ] \
                && [ "$validated_server_start" = "$candidate_server_start" ]; then
                ready_main_pid=$candidate_main_pid
                ready_main_start=$candidate_main_start
                ready_server_pid=$candidate_server_pid
                ready_server_start=$candidate_server_start
                return 0
              fi
            fi
            attempt=$((attempt + 1))
            ${pkgs.coreutils}/bin/sleep 2
          done
          return 1
        }

        run_public_step() {
          expected_main_pid=$1
          expected_server_pid=$2
          public_mode=$3
          validate_runtime_pids \
            "$expected_main_pid" "$expected_server_pid" || return 1
          public_value=
          public_status=0
          public_value=$(${rustdeskPublicConfig} "$public_mode") \
            || public_status=$?
          validate_runtime_pids \
            "$expected_main_pid" "$expected_server_pid" || return 1
          [ "$public_status" -eq 0 ]
        }

        prove_public_config() {
          expected_main_pid=$1
          expected_server_pid=$2

          run_public_step "$expected_main_pid" "$expected_server_pid" \
            query-host || return 1
          [ "$public_value" = ${escapeShellArg rustdeskHost} ] || return 1
          run_public_step "$expected_main_pid" "$expected_server_pid" \
            query-key || return 1
          [ "$public_value" = ${escapeShellArg rustdeskPublicKey} ] || return 1
          run_public_step "$expected_main_pid" "$expected_server_pid" \
            query-relay || return 1
          [ "$public_value" = ${escapeShellArg rustdeskHost} ] || return 1
          run_public_step "$expected_main_pid" "$expected_server_pid" \
            query-verification-method || return 1
          [ "$public_value" = use-permanent-password ] || return 1
          run_public_step "$expected_main_pid" "$expected_server_pid" \
            query-approve-mode || return 1
          [ "$public_value" = password ] || return 1
          run_public_step "$expected_main_pid" "$expected_server_pid" \
            query-auto-update || return 1
          [ "$public_value" = N ]
        }

        apply_and_prove_public_config() {
          expected_main_pid=$1
          expected_server_pid=$2
          for public_mode in \
            apply-server \
            apply-verification-method \
            apply-approve-mode \
            apply-auto-update; do
            run_public_step "$expected_main_pid" "$expected_server_pid" \
              "$public_mode" || return 1
          done
          prove_public_config "$expected_main_pid" "$expected_server_pid"
        }

        acquire_operation_lock || fail operation-lock
        inspect_revision_object "$stamp" || fail stamp
        case "$object_state" in
          current) exit 0 ;;
          absent|stale) ;;
          *) fail stamp ;;
        esac

        inspect_revision_object "$reservation" || fail reservation
        reservation_state=$object_state
        inspect_ready_object "$ready" || fail ready
        initial_ready_state=$ready_state
        if [ "$reservation_state" = current ]; then
          case "$initial_ready_state" in
            absent|current) fail attempt-used ;;
            *) fail ready-revision ;;
          esac
        fi
        case "$object_state" in
          absent|stale) ;;
          *) fail reservation ;;
        esac
        case "$initial_ready_state" in
          absent|stale) ;;
          current) fail ready-without-current-attempt ;;
          *) fail ready ;;
        esac

        wait_runtime || fail readiness
        provision_main_pid=$ready_main_pid
        provision_server_pid=$ready_server_pid
        apply_and_prove_public_config \
          "$provision_main_pid" "$provision_server_pid" \
          || fail public-config

        inspect_revision_object "$reservation" || fail reservation
        case "$object_state" in
          absent|stale) ;;
          *) fail reservation-changed ;;
        esac
        inspect_ready_object "$ready" || fail ready
        case "$ready_state" in
          absent|stale) ;;
          *) fail ready-changed ;;
        esac
        publish_revision_object "$reservation" attempt \
          || fail reservation-publish
        inspect_revision_object "$reservation" || fail reservation
        [ "$object_state" = current ] || fail reservation
        inspect_ready_object "$ready" || fail ready
        case "$ready_state" in
          absent) ;;
          stale) remove_ready_object stale || fail ready-remove ;;
          *) fail ready-changed ;;
        esac
        inspect_ready_object "$ready" || fail ready
        [ "$ready_state" = absent ] || fail ready
        validate_runtime_pids \
          "$provision_main_pid" "$provision_server_pid" \
          || fail runtime-changed-before-secret

        secret=$(resolve_secret) || fail secret
        bytes=$(${pkgs.coreutils}/bin/wc -c < "$secret")
        password=
        IFS= read -r password < "$secret" || [ -n "$password" ] || fail secret
        [ "$bytes" -eq "''${#password}" ] \
          && [ "''${#password}" -ge 32 ] && [ "''${#password}" -le 64 ] \
          || fail secret-format
        case "$password" in *[!A-Za-z0-9_-]*) fail secret-format ;; esac

        prepare_password_context || {
          unset password
          fail password-context
        }
        inspect_revision_object "$reservation" || {
          unset password
          fail reservation
        }
        [ "$object_state" = current ] || {
          unset password
          fail reservation
        }
        inspect_ready_object "$ready" || {
          unset password
          fail ready
        }
        [ "$ready_state" = absent ] || {
          unset password
          fail ready
        }
        validate_runtime_pids \
          "$provision_main_pid" "$provision_server_pid" || {
          unset password
          fail runtime-changed-before-password
        }
        result=$(${pkgs.coreutils}/bin/mktemp "$state/result.XXXXXX")
        status=0
        HOME="$password_home" XDG_CONFIG_HOME="$password_config_home" \
          ${pkgs.coreutils}/bin/env \
          ${pkgs.coreutils}/bin/timeout --signal=TERM --kill-after=5s 15s \
          "$rustdesk" --password "$password" > "$result" 2>&1 \
          || status=$?
        unset password
        [ "$status" -eq 0 ] || fail password-command
        result_bytes=$(${pkgs.coreutils}/bin/wc -c < "$result") \
          || fail password-result
        [ "$result_bytes" -eq 6 ] || fail password-result
        exec 3< "$result"
        IFS= read -r line <&3 || fail password-result
        if IFS= read -r _ <&3; then fail password-result; fi
        exec 3<&-
        [ "$line" = "Done!" ] || fail password-result
        unset line
        unset result_bytes
        ${pkgs.coreutils}/bin/rm -f "$result"
        result=

        validate_runtime_pids \
          "$provision_main_pid" "$provision_server_pid" \
          || fail runtime-changed-during-password
        ${pkgs.systemd}/bin/systemctl restart rustdesk.service
        wait_runtime || fail restart
        [ "$ready_main_pid" != "$provision_main_pid" ] \
          || fail service-not-restarted
        [ "$ready_server_pid" != "$provision_server_pid" ] \
          || fail server-not-restarted
        prove_public_config "$ready_main_pid" "$ready_server_pid" \
          || fail public-config-after-restart
        validate_runtime_pids "$ready_main_pid" "$ready_server_pid" \
          || fail runtime-changed-after-restart
        post_main_pid=$validated_main_pid
        post_main_start=$validated_main_start
        post_main_exe=$validated_main_exe
        post_main_uid=$validated_main_uid
        post_server_pid=$validated_server_pid
        post_server_start=$validated_server_start
        post_server_exe=$validated_server_exe
        post_server_uid=$validated_server_uid
        inspect_revision_object "$reservation" || fail reservation
        [ "$object_state" = current ] || fail reservation
        inspect_ready_object "$ready" || fail ready
        [ "$ready_state" = absent ] || fail ready
        publish_ready_object \
          "$post_main_pid" "$post_main_start" \
          "$post_main_exe" "$post_main_uid" \
          "$post_server_pid" "$post_server_start" \
          "$post_server_exe" "$post_server_uid" \
          || fail ready-publish
        inspect_ready_object "$ready" || fail ready
        [ "$ready_state" = current ] || fail ready
        validate_ready_runtime || fail runtime-changed-after-ready
        ready_cleanup_required=0
        trap - EXIT HUP INT TERM
      '';
      rustdeskFinalizeScript = ''
        set -eu
        umask 077

        rustdesk_server_exe=${rustdeskPackage}/lib/rustdesk/rustdesk
        rustdesk_user=${escapeShellArg userName}
        state=/var/lib/rustdesk-provision
        stamp=$state/stamp
        reservation=$state/attempt
        ready=$state/ready-to-finalize
        operation_lock=$state/operation.lock
        revision_prefix=axiom-rustdesk-provision-v4:
        current_revision=${escapeShellArg rustdeskRevisionValue}
        object_tmp=
        cleanup() {
          [ -z "$object_tmp" ] || ${pkgs.coreutils}/bin/rm -f "$object_tmp"
        }
        trap cleanup EXIT
        trap 'exit 1' HUP INT TERM
        fail() { echo "RustDesk finalization failed: $1" >&2; exit 1; }

        [ "$#" -eq 1 ] && [ "$1" = --confirm-remote-auth ] \
          || fail confirmation-required
        [ "$(${pkgs.coreutils}/bin/id -u)" = 0 ] || fail root-required

        validate_state_directory() {
          [ -d "$state" ] && [ ! -L "$state" ] || return 1
          metadata=$(${pkgs.coreutils}/bin/stat --format='%u:%g:%a' \
            -- "$state" 2>/dev/null) || return 1
          [ "$metadata" = 0:0:700 ]
        }

        validate_operation_lock() {
          [ -f "$operation_lock" ] && [ ! -L "$operation_lock" ] \
            || return 1
          metadata=$(${pkgs.coreutils}/bin/stat \
            --format='%u:%g:%a:%s:%h' -- "$operation_lock" 2>/dev/null) \
            || return 1
          [ "$metadata" = 0:0:600:0:1 ]
        }

        acquire_operation_lock() {
          validate_state_directory || return 1
          if [ ! -e "$operation_lock" ] && [ ! -L "$operation_lock" ]; then
            ( set -C; : > "$operation_lock" ) 2>/dev/null || true
          fi
          validate_operation_lock || return 1
          exec 9<> "$operation_lock" || return 1
          ${pkgs.util-linux}/bin/flock --nonblock 9 || {
            exec 9>&-
            return 1
          }
          path_identity=$(${pkgs.coreutils}/bin/stat \
            --format='%d:%i:%u:%g:%a:%s:%h' \
            -- "$operation_lock" 2>/dev/null) || return 1
          fd_identity=$(${pkgs.coreutils}/bin/stat --dereference \
            --format='%d:%i:%u:%g:%a:%s:%h' \
            -- /proc/self/fd/9 2>/dev/null) || return 1
          [ "$path_identity" = "$fd_identity" ] \
            && validate_operation_lock
        }

        inspect_revision_object() {
          object_path=$1
          object_state=
          if [ ! -e "$object_path" ] && [ ! -L "$object_path" ]; then
            object_state=absent
            return 0
          fi
          [ -f "$object_path" ] && [ ! -L "$object_path" ] || return 1
          metadata=$(${pkgs.coreutils}/bin/stat --format='%u:%g:%a' \
            -- "$object_path" 2>/dev/null) || return 1
          [ "$metadata" = 0:0:600 ] || return 1
          bytes=$(${pkgs.coreutils}/bin/wc -c < "$object_path") || return 1
          object_value=
          IFS= read -r object_value < "$object_path" || return 1
          [ "$bytes" -eq $(( ''${#object_value} + 1 )) ] || return 1
          case "$object_value" in
            "$revision_prefix"*)
              object_digest=''${object_value#"$revision_prefix"}
              ;;
            *) return 1 ;;
          esac
          [ "''${#object_digest}" -eq 64 ] || return 1
          case "$object_digest" in *[!0-9a-f]*) return 1 ;; esac
          if ${pkgs.diffutils}/bin/cmp -s \
            "$object_path" ${rustdeskRevision}; then
            object_state=current
          else
            object_state=stale
          fi
        }

        publish_revision_object() {
          publish_object_path=$1
          object_name=$2
          object_tmp=$(${pkgs.coreutils}/bin/mktemp \
            "$state/$object_name.tmp.XXXXXX") || return 1
          ${pkgs.coreutils}/bin/install -m 0600 -o root -g root \
            ${rustdeskRevision} "$object_tmp" || return 1
          inspect_revision_object "$object_tmp" || return 1
          [ "$object_state" = current ] || return 1
          ${pkgs.coreutils}/bin/timeout --signal=TERM --kill-after=5s 15s \
            ${pkgs.coreutils}/bin/sync -f "$object_tmp" || return 1
          ${pkgs.coreutils}/bin/mv -fT -- "$object_tmp" "$publish_object_path" \
            || return 1
          object_tmp=
          ${pkgs.coreutils}/bin/timeout --signal=TERM --kill-after=5s 15s \
            ${pkgs.coreutils}/bin/sync -f "$state" || return 1
          inspect_revision_object "$publish_object_path" || return 1
          [ "$object_state" = current ]
        }

        inspect_ready_object() {
          ready_path=$1
          ready_state=
          if [ ! -e "$ready_path" ] && [ ! -L "$ready_path" ]; then
            ready_state=absent
            return 0
          fi
          [ -f "$ready_path" ] && [ ! -L "$ready_path" ] || return 1
          metadata=$(${pkgs.coreutils}/bin/stat --format='%u:%g:%a:%h' \
            -- "$ready_path" 2>/dev/null) || return 1
          [ "$metadata" = 0:0:600:1 ] || return 1
          ready_line_count=$(${pkgs.coreutils}/bin/wc -l < "$ready_path") \
            || return 1
          [ "$ready_line_count" -eq 11 ] || return 1
          exec 4< "$ready_path" || return 1
          IFS= read -r ready_line1 <&4 || { exec 4<&-; return 1; }
          IFS= read -r ready_line2 <&4 || { exec 4<&-; return 1; }
          IFS= read -r ready_line3 <&4 || { exec 4<&-; return 1; }
          IFS= read -r ready_line4 <&4 || { exec 4<&-; return 1; }
          IFS= read -r ready_line5 <&4 || { exec 4<&-; return 1; }
          IFS= read -r ready_line6 <&4 || { exec 4<&-; return 1; }
          IFS= read -r ready_line7 <&4 || { exec 4<&-; return 1; }
          IFS= read -r ready_line8 <&4 || { exec 4<&-; return 1; }
          IFS= read -r ready_line9 <&4 || { exec 4<&-; return 1; }
          IFS= read -r ready_line10 <&4 || { exec 4<&-; return 1; }
          IFS= read -r ready_line11 <&4 || { exec 4<&-; return 1; }
          if IFS= read -r _ <&4; then
            exec 4<&-
            return 1
          fi
          exec 4<&-
          ready_bytes=$(${pkgs.coreutils}/bin/wc -c < "$ready_path") \
            || return 1
          ready_expected_bytes=$((
            ''${#ready_line1} + ''${#ready_line2} + ''${#ready_line3} \
            + ''${#ready_line4} + ''${#ready_line5} + ''${#ready_line6} \
            + ''${#ready_line7} + ''${#ready_line8} + ''${#ready_line9} \
            + ''${#ready_line10} + ''${#ready_line11} + 11
          ))
          [ "$ready_bytes" -eq "$ready_expected_bytes" ] || return 1
          [ "$ready_line1" = format=rustdesk-ready-v1 ] || return 1
          [ "$ready_line2" = host=axiom ] || return 1
          case "$ready_line3" in revision=*) ;; *) return 1 ;; esac
          ready_revision=''${ready_line3#revision=}
          case "$ready_revision" in
            "$revision_prefix"*)
              ready_digest=''${ready_revision#"$revision_prefix"}
              ;;
            *) return 1 ;;
          esac
          [ "''${#ready_digest}" -eq 64 ] || return 1
          case "$ready_digest" in *[!0-9a-f]*) return 1 ;; esac
          case "$ready_line4" in main.pid=*) ;; *) return 1 ;; esac
          ready_main_pid=''${ready_line4#main.pid=}
          case "$ready_main_pid" in ""|*[!0-9]*) return 1 ;; esac
          [ "$ready_main_pid" -gt 1 ] || return 1
          case "$ready_line5" in main.start=*) ;; *) return 1 ;; esac
          ready_main_start=''${ready_line5#main.start=}
          case "$ready_main_start" in ""|*[!0-9]*) return 1 ;; esac
          [ "$ready_main_start" -gt 0 ] || return 1
          case "$ready_line6" in main.executable=*) ;; *) return 1 ;; esac
          ready_main_exe=''${ready_line6#main.executable=}
          case "$ready_main_exe" in
            /nix/store/*/lib/rustdesk/rustdesk) ;;
            *) return 1 ;;
          esac
          case "$ready_line7" in main.uid=*) ;; *) return 1 ;; esac
          ready_main_uid=''${ready_line7#main.uid=}
          [ "$ready_main_uid" = 0 ] || return 1
          case "$ready_line8" in server.pid=*) ;; *) return 1 ;; esac
          ready_server_pid=''${ready_line8#server.pid=}
          case "$ready_server_pid" in ""|*[!0-9]*) return 1 ;; esac
          [ "$ready_server_pid" -gt 1 ] || return 1
          case "$ready_line9" in server.start=*) ;; *) return 1 ;; esac
          ready_server_start=''${ready_line9#server.start=}
          case "$ready_server_start" in ""|*[!0-9]*) return 1 ;; esac
          [ "$ready_server_start" -gt 0 ] || return 1
          case "$ready_line10" in server.executable=*) ;; *) return 1 ;; esac
          ready_server_exe=''${ready_line10#server.executable=}
          case "$ready_server_exe" in
            /nix/store/*/lib/rustdesk/rustdesk) ;;
            *) return 1 ;;
          esac
          case "$ready_line11" in server.uid=*) ;; *) return 1 ;; esac
          ready_server_uid=''${ready_line11#server.uid=}
          case "$ready_server_uid" in ""|*[!0-9]*) return 1 ;; esac
          [ "$ready_server_uid" -gt 0 ] || return 1
          if [ "$ready_revision" = "$current_revision" ]; then
            expected_server_uid=$(${pkgs.coreutils}/bin/id -u \
              "$rustdesk_user" 2>/dev/null) || return 1
            [ "$ready_main_exe" = "$rustdesk_server_exe" ] \
              && [ "$ready_server_exe" = "$rustdesk_server_exe" ] \
              && [ "$ready_server_uid" = "$expected_server_uid" ] \
              || return 1
            ready_state=current
          else
            ready_state=stale
          fi
        }

        remove_ready_object() {
          inspect_ready_object "$ready" || return 1
          [ "$ready_state" = current ] || return 1
          ${pkgs.coreutils}/bin/rm -f -- "$ready" || return 1
          ${pkgs.coreutils}/bin/timeout --signal=TERM --kill-after=5s 15s \
            ${pkgs.coreutils}/bin/sync -f "$state" || return 1
          inspect_ready_object "$ready" || return 1
          [ "$ready_state" = absent ]
        }

        proc_start_identity() {
          identity_pid=$1
          identity_line=
          IFS= read -r identity_line < "/proc/$identity_pid/stat" \
            || [ -n "$identity_line" ] || return 1
          identity_stat_pid=''${identity_line%% *}
          [ "$identity_stat_pid" = "$identity_pid" ] || return 1
          identity_tail=''${identity_line##*) }
          [ "$identity_tail" != "$identity_line" ] || return 1
          identity_old_ifs=$IFS
          IFS=' '
          set -f
          # Word splitting is intentional for the fixed fields after comm.
          # shellcheck disable=SC2086
          set -- $identity_tail
          set +f
          IFS=$identity_old_ifs
          [ "$#" -ge 20 ] || return 1
          shift 19
          identity_start=$1
          case "$identity_start" in ""|*[!0-9]*) return 1 ;; esac
          [ "$identity_start" -gt 0 ] || return 1
          ${pkgs.coreutils}/bin/printf '%s\n' "$identity_start"
        }

        validate_main_service() {
          main_pid=$(${pkgs.systemd}/bin/systemctl show \
            -p MainPID --value rustdesk.service 2>/dev/null) || return 1
          case "$main_pid" in ""|0|1|*[!0-9]*) return 1 ;; esac
          ${pkgs.systemd}/bin/systemctl is-active --quiet rustdesk.service \
            || return 1
          [ -d "/proc/$main_pid" ] && [ ! -L "/proc/$main_pid" ] \
            || return 1
          process_start=$(proc_start_identity "$main_pid") || return 1
          process_uid=$(${pkgs.coreutils}/bin/stat --format='%u' \
            -- "/proc/$main_pid" 2>/dev/null) || return 1
          [ "$process_uid" = 0 ] || return 1
          process_exe=$(${pkgs.coreutils}/bin/readlink -e \
            -- "/proc/$main_pid/exe" 2>/dev/null) || return 1
          [ "$process_exe" = "$rustdesk_server_exe" ] || return 1
          process_args=()
          while IFS= read -r -d "" arg; do
            process_args+=("$arg")
          done < "/proc/$main_pid/cmdline"
          [ "''${#process_args[@]}" -eq 2 ] \
            && [ "''${process_args[1]}" = --service ] || return 1
          process_start_after=$(proc_start_identity "$main_pid") || return 1
          [ "$process_start_after" = "$process_start" ] || return 1
          validated_main_pid=$main_pid
          validated_main_start=$process_start
          validated_main_exe=$process_exe
          validated_main_uid=$process_uid
        }

        validate_user_server() {
          uid=$(${pkgs.coreutils}/bin/id -u "$rustdesk_user" 2>/dev/null) \
            || return 1
          gid=$(${pkgs.coreutils}/bin/id -g "$rustdesk_user" 2>/dev/null) \
            || return 1
          ipc_parent=/tmp/RustDesk-$uid
          ipc=$ipc_parent/ipc
          pid_file=$ipc.pid
          [ -d "$ipc_parent" ] && [ ! -L "$ipc_parent" ] || return 1
          metadata=$(${pkgs.coreutils}/bin/stat --format='%u:%g:%a' \
            -- "$ipc_parent" 2>/dev/null) || return 1
          [ "$metadata" = "$uid:$gid:700" ] || return 1
          [ -S "$ipc" ] && [ ! -L "$ipc" ] || return 1
          metadata=$(${pkgs.coreutils}/bin/stat --format='%u:%g:%a' \
            -- "$ipc" 2>/dev/null) || return 1
          [ "$metadata" = "$uid:$gid:600" ] || return 1
          [ -f "$pid_file" ] && [ ! -L "$pid_file" ] || return 1
          metadata=$(${pkgs.coreutils}/bin/stat --format='%u:%g:%a' \
            -- "$pid_file" 2>/dev/null) || return 1
          [ "$metadata" = "$uid:$gid:600" ] || return 1
          pid_bytes=$(${pkgs.coreutils}/bin/wc -c < "$pid_file") || return 1
          server_pid=
          IFS= read -r server_pid < "$pid_file" \
            || [ -n "$server_pid" ] || return 1
          [ "$pid_bytes" -eq "''${#server_pid}" ] || return 1
          case "$server_pid" in ""|0|1|*[!0-9]*) return 1 ;; esac
          [ -d "/proc/$server_pid" ] && [ ! -L "/proc/$server_pid" ] \
            || return 1
          process_start=$(proc_start_identity "$server_pid") || return 1
          process_uid=$(${pkgs.coreutils}/bin/stat --format='%u' \
            -- "/proc/$server_pid" 2>/dev/null) || return 1
          [ "$process_uid" = "$uid" ] || return 1
          process_exe=$(${pkgs.coreutils}/bin/readlink -e \
            -- "/proc/$server_pid/exe" 2>/dev/null) || return 1
          [ "$process_exe" = "$rustdesk_server_exe" ] || return 1
          process_args=()
          while IFS= read -r -d "" arg; do
            process_args+=("$arg")
          done < "/proc/$server_pid/cmdline"
          [ "''${#process_args[@]}" -eq 2 ] \
            && [ "''${process_args[1]}" = --server ] || return 1
          socket_pid=$(${pkgs.lsof}/bin/lsof -nP -t -a \
            -p "$server_pid" -U -- "$ipc" 2>/dev/null) || return 1
          [ "$socket_pid" = "$server_pid" ] || return 1
          process_start_after=$(proc_start_identity "$server_pid") || return 1
          [ "$process_start_after" = "$process_start" ] || return 1
          validated_server_pid=$server_pid
          validated_server_start=$process_start
          validated_server_exe=$process_exe
          validated_server_uid=$process_uid
        }

        finalize_server_pid=
        finalize_server_start=
        finalize_server_exe=
        finalize_server_uid=

        validate_finalization_runtime() {
          validate_main_service || return 1
          [ "$validated_main_pid" = "$ready_main_pid" ] \
            && [ "$validated_main_start" = "$ready_main_start" ] \
            && [ "$validated_main_exe" = "$ready_main_exe" ] \
            && [ "$validated_main_uid" = "$ready_main_uid" ] \
            || return 1
          validate_user_server || return 1
          if [ -z "$finalize_server_pid" ]; then
            finalize_server_pid=$validated_server_pid
            finalize_server_start=$validated_server_start
            finalize_server_exe=$validated_server_exe
            finalize_server_uid=$validated_server_uid
          else
            [ "$validated_server_pid" = "$finalize_server_pid" ] \
              && [ "$validated_server_start" = "$finalize_server_start" ] \
              && [ "$validated_server_exe" = "$finalize_server_exe" ] \
              && [ "$validated_server_uid" = "$finalize_server_uid" ]
          fi
        }

        acquire_operation_lock || fail operation-lock
        inspect_revision_object "$stamp" || fail stamp
        case "$object_state" in
          current)
            inspect_ready_object "$ready" || fail ready
            case "$ready_state" in
              absent) exit 0 ;;
              current)
                remove_ready_object || fail ready-remove
                exit 0
                ;;
              *) fail ready ;;
            esac
            ;;
          absent|stale) ;;
          *) fail stamp ;;
        esac
        inspect_revision_object "$reservation" || fail reservation
        [ "$object_state" = current ] || fail reservation-not-current
        inspect_ready_object "$ready" || fail ready
        [ "$ready_state" = current ] || fail ready-not-current
        validate_finalization_runtime || fail process-identity
        ${pkgs.coreutils}/bin/sleep 2
        inspect_revision_object "$reservation" || fail reservation
        [ "$object_state" = current ] || fail reservation-not-current
        inspect_ready_object "$ready" || fail ready
        [ "$ready_state" = current ] || fail ready-not-current
        validate_finalization_runtime || fail process-identity
        publish_revision_object "$stamp" stamp || fail stamp-publish
        remove_ready_object || fail ready-remove
        trap - EXIT HUP INT TERM
      '';
      rustdeskFinalize = pkgs.writeShellScriptBin
        "rustdesk-provision-finalize" rustdeskFinalizeScript;
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

    environment.systemPackages = [ c1ctl rustdeskFinalize ];

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

    networking.hosts.${acornPublicIp} = [ rustdeskHost ];

    assertions = [
      {
        assertion = rustdeskPackage.version == "1.4.9";
        message = "axiom RustDesk client must remain pinned to 1.4.9";
      }
      {
        assertion = rustdeskPackage.src.drvPath == rustdeskSource.drvPath;
        message = "axiom RustDesk must use the bound 1.4.9 source";
      }
      {
        assertion = rustdeskPackage.cargoDeps.drvPath == rustdeskCargoDeps.drvPath;
        message = "axiom RustDesk cargoDeps must be rebuilt from the bound 1.4.9 source";
      }
      {
        assertion = rustdeskUser.home == "/home/c1";
        message = "axiom RustDesk session user home must remain /home/c1";
      }
      {
        assertion = rustdeskUserUid == 1000;
        message = "axiom RustDesk session user UID must remain 1000";
      }
      {
        assertion = all (needle: !(hasInfix needle rustdeskFinalizeScript)) [
          (toString rustdeskSecret.path)
          "--password"
          "resolve_secret"
          "agenix"
        ];
        message = "axiom RustDesk finalizer must not contain a secret path, password invocation, or secret resolver";
      }
    ];

    age.secrets.rustdesk-password = {
      owner = "root";
      group = "root";
      mode = "0400";
    };

    systemd.services.rustdesk = {
      description = "RustDesk system service";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      requires = [ frpcDirectRouteUnit ];
      after = [
        "network-online.target"
        "systemd-user-sessions.service"
        frpcDirectRouteUnit
      ];
      path = with pkgs; [ bash coreutils gawk gnugrep gnused procps sudo systemd util-linux ];
      environment = rustdeskRuntimeEnvironment;
      serviceConfig = {
        Type = "simple";
        ExecStart = "${rustdeskPackage}/bin/rustdesk --service";
        ExecStop = "${pkgs.procps}/bin/pkill -f \"rustdesk --\"";
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
        TimeoutStartSec = "8min";
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

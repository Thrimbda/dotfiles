{ hey, lib, ... }:

with lib;
{
  os = "darwin";
  system = "aarch64-darwin";

  ## Modules
  user = {
    name = "c1";
    home = "/Users/c1";
  };

  modules = {
    theme.active = "autumnal-cli";

    shell = {
      direnv.enable = true;
      zsh.enable = true;
      zsh.envInit = ''
        path=(
          "$XDG_CONFIG_HOME/emacs/bin"
          "/Applications/Emacs.app/Contents/MacOS/bin"
          "''${path[@]}"
        )
        typeset -U path PATH
      '';
      git.enable = true;
      gnupg.enable = true;
      tmux.enable = true;
    };

    dev = {
      node.enable = true;
      node.xdg.enable = true;
      deno.enable = true;
      rust.enable = true;
      python.enable = true;
      playwright.enable = true;
    };

    editors = {
      default = "nvim";
      vim.enable = true;
      # emacs.enable = true;
    };

    # services = {
    #   cloudflared.enable = true;
    # };
  };

  ## Local configuration
  config = { config, pkgs, ... }:
    let
      rustdeskVersion = "1.4.8";
      rustdeskHost = "rustdesk.0xc1.wang";
      rustdeskDmgHash = "sha256-f4rPsNyrIdTI/lcJAr5woC7Q2wB9ql6/4eARlIel/Bc=";
      rustdeskServiceLauncher = "/bin/sh";
      rustdeskServiceLauncherArgument = "-c";
      rustdeskServiceProgram = "/Applications/RustDesk.app/Contents/MacOS/service";
      rustdeskSecret = config.age.secrets.rustdesk-password;
      rustdeskSecretMetadata =
        "${rustdeskSecret.owner}:${rustdeskSecret.group}:${removePrefix "0" rustdeskSecret.mode}";
      rustdeskPublicKey = removeSuffix "\n" (
        builtins.readFile ../acorn/secrets/rustdesk-server-key.pub
      );
      rustdeskApp = pkgs.stdenvNoCC.mkDerivation {
        pname = "rustdesk-macos";
        version = rustdeskVersion;
        src = pkgs.fetchurl {
          url = "https://github.com/rustdesk/rustdesk/releases/download/${rustdeskVersion}/rustdesk-${rustdeskVersion}-aarch64.dmg";
          hash = rustdeskDmgHash;
        };
        nativeBuildInputs = [ pkgs.undmg ];
        sourceRoot = ".";
        installPhase = ''
          mkdir -p "$out/Applications"
          cp -R RustDesk.app "$out/Applications/RustDesk.app"
        '';
        dontFixup = true;
        dontStrip = true;
      };
      rustdeskAppVerify = pkgs.writeShellScript "charlie-rustdesk-app-verify" ''
        set -eu

        app=/Applications/RustDesk.app
        [ -d "$app" ] && [ ! -L "$app" ] || exit 1
        /usr/bin/codesign --verify --deep --strict "$app" >/dev/null 2>&1
        /usr/sbin/spctl -a -t exec "$app" >/dev/null 2>&1
      '';
      rustdeskPublicConfig = pkgs.writeShellScript "charlie-rustdesk-public-config" ''
        set -eu
        rustdesk=/Applications/RustDesk.app/Contents/MacOS/RustDesk
        timeout=${pkgs.coreutils}/bin/timeout

        ${rustdeskAppVerify}

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
      rustdeskRevision = pkgs.writeText "charlie-rustdesk-revision" ''
        package=${rustdeskVersion}
        source=${rustdeskDmgHash}
        public-config=${rustdeskPublicConfig}
        provision=charlie-rustdesk-provision-v3
        ciphertext=${./secrets/rustdesk-password.age}
      '';
      rustdeskAgenixGate = pkgs.writeShellScript "charlie-rustdesk-agenix-gate" ''
        set -eu
        umask 077

        state=/var/db/rustdesk-provision
        marker=$state/agenix-complete
        revision=${escapeShellArg (toString rustdeskRevision)}

        prepare_state() {
          if [ -e "$state" ] || [ -L "$state" ]; then
            [ -d "$state" ] && [ ! -L "$state" ] || return 1
          else
            /usr/bin/install -d -m 0700 -o root -g wheel "$state" \
              || return 1
          fi
          metadata=$(/usr/bin/stat -f '%Su:%Sg:%Lp' "$state" 2>/dev/null) \
            || return 1
          [ "$metadata" = root:wheel:700 ]
        }

        current_boot() {
          boot=$(/usr/sbin/sysctl -n kern.bootsessionuuid 2>/dev/null) \
            || return 1
          [ -n "$boot" ] || return 1
          case "$boot" in *[!A-Fa-f0-9-]*) return 1 ;; esac
          printf '%s\n' "$boot"
        }

        check_marker() {
          prepare_state || return 1
          [ -f "$marker" ] && [ ! -L "$marker" ] || return 1
          metadata=$(/usr/bin/stat -f '%Su:%Sg:%Lp' "$marker" 2>/dev/null) \
            || return 1
          [ "$metadata" = root:wheel:600 ] || return 1

          marker_revision=
          marker_boot=
          exec 3< "$marker" || return 1
          IFS= read -r marker_revision <&3 || {
            exec 3<&-
            return 1
          }
          IFS= read -r marker_boot <&3 || {
            exec 3<&-
            return 1
          }
          if IFS= read -r _ <&3; then
            exec 3<&-
            return 1
          fi
          exec 3<&-

          boot=$(current_boot) || return 1
          [ "$marker_revision" = "revision=$revision" ] \
            && [ "$marker_boot" = "boot=$boot" ]
        }

        case "''${1:-}" in
          prepare)
            prepare_state
            ;;
          invalidate)
            prepare_state
            if [ -e "$marker" ] || [ -L "$marker" ]; then
              /bin/rm -f -- "$marker"
            fi
            [ ! -e "$marker" ] && [ ! -L "$marker" ]
            ;;
          publish)
            prepare_state
            boot=$(current_boot)
            tmp=$(/usr/bin/mktemp "$state/agenix-complete.tmp.XXXXXX")
            cleanup() { [ -z "$tmp" ] || /bin/rm -f -- "$tmp"; }
            trap cleanup EXIT
            trap 'exit 1' HUP INT TERM
            /usr/bin/printf 'revision=%s\nboot=%s\n' \
              "$revision" "$boot" > "$tmp"
            /bin/chmod 0600 "$tmp"
            /usr/sbin/chown root:wheel "$tmp"
            metadata=$(/usr/bin/stat -f '%Su:%Sg:%Lp' "$tmp" 2>/dev/null)
            [ -f "$tmp" ] && [ ! -L "$tmp" ] \
              && [ "$metadata" = root:wheel:600 ]
            /bin/mv -f "$tmp" "$marker"
            tmp=
            check_marker
            trap - EXIT HUP INT TERM
            ;;
          check)
            check_marker
            ;;
          *)
            exit 2
            ;;
        esac
      '';
      rustdeskProvision = pkgs.writeShellScript "charlie-rustdesk-provision" ''
        set -eu
        umask 077

        rustdesk_app=/Applications/RustDesk.app
        rustdesk=$rustdesk_app/Contents/MacOS/RustDesk
        rustdesk_user=c1
        state=/var/db/rustdesk-provision
        stamp=$state/stamp
        reservation=$state/attempt
        stamp_tmp=$state/stamp.tmp.$$
        attempt_tmp=$state/attempt.tmp.$$
        result=
        cleanup() {
          [ -z "$result" ] || /bin/rm -f "$result"
          /bin/rm -f "$stamp_tmp" "$attempt_tmp"
        }
        trap cleanup EXIT
        trap 'exit 1' HUP INT TERM
        fail() { echo "RustDesk provisioning failed: $1" >&2; exit 1; }

        verify_app() {
          ${rustdeskAppVerify}
        }

        stamp_is_current() {
          [ -f "$stamp" ] && [ ! -L "$stamp" ] || return 1
          metadata=$(/usr/bin/stat -f '%Su:%Sg:%Lp' "$stamp" 2>/dev/null) \
            || return 1
          [ "$metadata" = root:wheel:600 ] \
            && ${pkgs.diffutils}/bin/cmp -s "$stamp" ${rustdeskRevision}
        }

        resolve_secret() {
          configured=${escapeShellArg rustdeskSecret.path}
          target=$(${pkgs.coreutils}/bin/readlink -e -- "$configured" 2>/dev/null) \
            || return 1
          [ -n "$target" ] && [ -f "$target" ] && [ ! -L "$target" ] \
            || return 1
          metadata=$(/usr/bin/stat -f '%Su:%Sg:%Lp' "$target" 2>/dev/null) \
            || return 1
          [ "$metadata" = ${escapeShellArg rustdeskSecretMetadata} ] \
            || return 1
          [ -r "$target" ] || return 1
          printf '%s\n' "$target"
        }

        validate_user_server() {
          uid=$(/usr/bin/id -u "$rustdesk_user" 2>/dev/null) || return 1
          gid=$(/usr/bin/id -g "$rustdesk_user" 2>/dev/null) || return 1
          ipc_parent=/tmp/RustDesk-$uid
          ipc=$ipc_parent/ipc
          pid_file=$ipc.pid

          [ -d "$ipc_parent" ] && [ ! -L "$ipc_parent" ] || return 1
          metadata=$(/usr/bin/stat -f '%u:%g:%Lp' "$ipc_parent" 2>/dev/null) \
            || return 1
          [ "$metadata" = "$uid:$gid:700" ] || return 1

          [ -S "$ipc" ] && [ ! -L "$ipc" ] || return 1
          metadata=$(/usr/bin/stat -f '%u:%g:%Lp' "$ipc" 2>/dev/null) \
            || return 1
          [ "$metadata" = "$uid:$gid:600" ] || return 1

          [ -f "$pid_file" ] && [ ! -L "$pid_file" ] || return 1
          metadata=$(/usr/bin/stat -f '%u:%g:%Lp' "$pid_file" 2>/dev/null) \
            || return 1
          [ "$metadata" = "$uid:$gid:600" ] || return 1
          pid_bytes=$(/usr/bin/wc -c < "$pid_file") || return 1
          server_pid=
          IFS= read -r server_pid < "$pid_file" \
            || [ -n "$server_pid" ] || return 1
          [ "$pid_bytes" -eq "''${#server_pid}" ] || return 1
          case "$server_pid" in ""|0|1|*[!0-9]*) return 1 ;; esac

          launch_pid=$(/bin/launchctl print \
            "gui/$uid/com.carriez.RustDesk_server" 2>/dev/null \
            | /usr/bin/awk '
                $1 == "pid" && $2 == "=" && $3 ~ /^[0-9]+$/ {
                  count += 1
                  pid = $3
                }
                END {
                  if (count == 1) print pid
                  else exit 1
                }
              ') || return 1
          [ "$launch_pid" = "$server_pid" ] || return 1

          process_uid=$(/bin/ps -p "$server_pid" -o uid= 2>/dev/null \
            | /usr/bin/tr -d '[:space:]') || return 1
          [ "$process_uid" = "$uid" ] || return 1
          process_exe=$(/bin/ps -ww -p "$server_pid" -o comm= 2>/dev/null) \
            || return 1
          process_command=$(/bin/ps -ww -p "$server_pid" -o command= 2>/dev/null) \
            || return 1
          [ "$process_exe" = "$rustdesk" ] \
            && [ "$process_command" = "$rustdesk --server" ] || return 1

          socket_pid=$(/usr/sbin/lsof -nP -t -a -p "$server_pid" \
            -U -- "$ipc" 2>/dev/null) || return 1
          [ "$socket_pid" = "$server_pid" ] || return 1
          validated_server_pid=$server_pid
        }

        validate_privileged_service() {
          service_pid=$(/bin/launchctl print \
            system/com.carriez.RustDesk_service 2>/dev/null \
            | /usr/bin/awk \
              -v expected_program=${escapeShellArg rustdeskServiceLauncher} \
              -v expected_arg0=${escapeShellArg rustdeskServiceLauncher} \
              -v expected_arg1=${escapeShellArg rustdeskServiceLauncherArgument} \
              -v expected_arg2=${escapeShellArg rustdeskServiceProgram} '
                $1 == "state" && $2 == "=" {
                  state_count += 1
                  state = $3
                }
                $1 == "pid" && $2 == "=" && $3 ~ /^[0-9]+$/ {
                  pid_count += 1
                  pid = $3
                }
                $1 == "program" && $2 == "=" {
                  program_count += 1
                  program = $3
                }
                $1 == "arguments" && $2 == "=" && $3 == "{" {
                  arguments_count += 1
                  in_arguments = 1
                  next
                }
                in_arguments && $1 == "}" {
                  in_arguments = 0
                  next
                }
                in_arguments {
                  argument_count += 1
                  argument[argument_count] = $1
                }
                END {
                  if (state_count == 1 && state == "running"
                      && pid_count == 1 && pid > 1
                      && program_count == 1 && program == expected_program
                      && arguments_count == 1 && !in_arguments
                      && argument_count == 3
                      && argument[1] == expected_arg0
                      && argument[2] == expected_arg1
                      && argument[3] == expected_arg2) print pid
                  else exit 1
                }
              ') || return 1

          process_uid=$(/bin/ps -p "$service_pid" -o uid= 2>/dev/null \
            | /usr/bin/tr -d '[:space:]') || return 1
          process_ruid=$(/bin/ps -p "$service_pid" -o ruid= 2>/dev/null \
            | /usr/bin/tr -d '[:space:]') || return 1
          [ "$process_uid" = 0 ] && [ "$process_ruid" = 0 ] || return 1
          executable_pid=$(/usr/sbin/lsof -nP -t -a -p "$service_pid" \
            -d txt -- ${escapeShellArg rustdeskServiceProgram} 2>/dev/null) \
            || return 1
          [ "$executable_pid" = "$service_pid" ] || return 1
          process_command=$(/bin/ps -ww -p "$service_pid" -o command= 2>/dev/null) \
            || return 1
          [ "$process_command" = ${escapeShellArg rustdeskServiceProgram} ] \
            || return 1
          validated_service_pid=$service_pid
        }

        validate_runtime_pids() {
          expected_service_pid=$1
          expected_server_pid=$2
          validate_privileged_service || return 1
          [ "$validated_service_pid" = "$expected_service_pid" ] || return 1
          validate_user_server || return 1
          [ "$validated_server_pid" = "$expected_server_pid" ]
        }

        rustdesk_ready() {
          verify_app || return 1
          validate_privileged_service || return 1
          ready_service_pid=$validated_service_pid
          validate_user_server || return 1
          ready_server_pid=$validated_server_pid
          ${rustdeskPublicConfig} --check || return 1
          validate_privileged_service || return 1
          [ "$validated_service_pid" = "$ready_service_pid" ] || return 1
          validate_user_server || return 1
          [ "$validated_server_pid" = "$ready_server_pid" ]
        }

        wait_ready() {
          attempt=0
          while [ "$attempt" -lt 60 ]; do
            if rustdesk_ready; then
              candidate_service_pid=$ready_service_pid
              candidate_server_pid=$ready_server_pid
              ${pkgs.coreutils}/bin/sleep 2
              if validate_runtime_pids \
                "$candidate_service_pid" "$candidate_server_pid"; then
                ready_service_pid=$candidate_service_pid
                ready_server_pid=$candidate_server_pid
                return 0
              fi
            fi
            attempt=$((attempt + 1))
            ${pkgs.coreutils}/bin/sleep 2
          done
          return 1
        }

        ${rustdeskAgenixGate} prepare || fail state
        verify_app || fail app-trust
        if stamp_is_current; then
          exit 0
        fi

        wait_ready || fail readiness
        provision_service_pid=$ready_service_pid
        provision_server_pid=$ready_server_pid

        ${rustdeskAgenixGate} check || fail agenix-revision
        if [ -f "$reservation" ] \
          && ${pkgs.diffutils}/bin/cmp -s "$reservation" ${rustdeskRevision}; then
          fail password-attempt-used-reset-required
        fi
        validate_runtime_pids \
          "$provision_service_pid" "$provision_server_pid" \
          || fail runtime-changed-before-secret
        secret=$(resolve_secret) || fail secret
        ${rustdeskAgenixGate} check || fail agenix-revision
        bytes=$(/usr/bin/wc -c < "$secret")
        password=
        IFS= read -r password < "$secret" || [ -n "$password" ] || fail secret
        [ "$bytes" -eq "''${#password}" ] \
          && [ "''${#password}" -ge 32 ] && [ "''${#password}" -le 64 ] \
          || fail secret-format
        case "$password" in *[!A-Za-z0-9_-]*) fail secret-format ;; esac

        /usr/bin/install -m 0600 -o root -g wheel \
          ${rustdeskRevision} "$attempt_tmp"
        /bin/mv -f "$attempt_tmp" "$reservation"

        verify_app || {
          unset password
          fail app-trust
        }
        ${rustdeskAgenixGate} check || {
          unset password
          fail agenix-revision
        }
        validate_runtime_pids \
          "$provision_service_pid" "$provision_server_pid" || {
          unset password
          fail runtime-changed-before-password
        }
        result=$(/usr/bin/mktemp "$state/result.XXXXXX")
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
        /bin/rm -f "$result"
        result=

        validate_runtime_pids \
          "$provision_service_pid" "$provision_server_pid" \
          || fail runtime-changed-during-password

        /bin/launchctl kickstart -k system/com.carriez.RustDesk_service
        uid=$(/usr/bin/id -u "$rustdesk_user")
        /bin/launchctl kickstart -k "gui/$uid/com.carriez.RustDesk_server"
        wait_ready || fail restart
        [ "$ready_service_pid" != "$provision_service_pid" ] \
          || fail service-not-restarted
        [ "$ready_server_pid" != "$provision_server_pid" ] \
          || fail server-not-restarted
        validate_runtime_pids "$ready_service_pid" "$ready_server_pid" \
          || fail runtime-changed-after-restart
        /usr/bin/install -m 0600 -o root -g wheel \
          ${rustdeskRevision} "$stamp_tmp"
        /bin/mv -f "$stamp_tmp" "$stamp"
        trap - EXIT HUP INT TERM
      '';
    in {
    users.users.c1 = {
      name = "c1";
      home = "/Users/c1";
      shell = pkgs.zsh;
    };

    networking.hostName = "charlie";

    security.pam.services.sudo_local.touchIdAuth = true;

    system.defaults = {
      NSGlobalDomain = {
        ApplePressAndHoldEnabled = false;
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
      };
      dock = {
        autohide = false;
        tilesize = 48;
        largesize = 64;
        orientation = "left";
      };
      finder.AppleShowAllFiles = true;
    };

    environment.variables = {
      PATH = "$HOME/.opencode/bin:$PATH";
      OPENCODE_ENABLE_EXA = "1";
      OPENCODE_EXPERIMENTAL = "true";
    };

    launchd.user.agents.autossh-reverse-ssh = {
      serviceConfig = {
        ProgramArguments = [
          "${pkgs.autossh}/bin/autossh"
          "-M"
          "0"
          "-N"
          "-o"
          "ServerAliveInterval=30"
          "-o"
          "ServerAliveCountMax=3"
          "-o"
          "ExitOnForwardFailure=yes"
          "-R"
          "127.0.0.1:2222:127.0.0.1:22"
          "c1@8.159.128.125"
        ];
        EnvironmentVariables = {
          AUTOSSH_GATETIME = "0";
        };
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/tmp/autossh-reverse-ssh.out.log";
        StandardErrorPath = "/tmp/autossh-reverse-ssh.err.log";
      };
    };

    launchd.user.agents.opencode-server = {
      serviceConfig = {
        ProgramArguments = [
          "/Users/c1/.opencode/bin/opencode"
          "serve"
          "--hostname"
          "127.0.0.1"
          "--port"
          "4096"
        ];
        EnvironmentVariables = {
          HOME = "/Users/c1";
          OPENCODE_ENABLE_EXA = "1";
          OPENCODE_EXPERIMENTAL = "true";
        };
        WorkingDirectory = "/Users/c1";
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "/Users/c1/Library/Logs/opencode-server.out.log";
        StandardErrorPath = "/Users/c1/Library/Logs/opencode-server.err.log";
      };
    };

    user.packages = with pkgs; [
      htop
      coreutils
      curl
      git
      vim
      k9s
      kubectl
      cloudflared
      autossh
      lazygit
    ];

    modules.services.cloudflared = {
      enable = true;
      tunnelId = "9f33127c-3a10-47dc-9383-e27115780db8";
      credentialsFile = ./secrets/cloudflared-credentials.age;
      warpRouting.enabled = false;
      extraConfig = {
        tunnelName = "home-charlie";
        ingress = [
          {
            hostname = "opencode-charlie.0xc1.space";
            service = "http://127.0.0.1:4096";
          }
          { service = "http_status:404"; }
        ];
      };
    };

    modules.agenix.sshKey = "/Users/c1/.ssh/id_ed25519";

    assertions = [{
      assertion = rustdeskApp.version == "1.4.8";
      message = "charlie RustDesk client must remain pinned to 1.4.8";
    }];

    age.secrets.rustdesk-password = {
      owner = "root";
      group = "wheel";
      mode = "0400";
    };

    # The pinned nix-darwin activation runs preActivation before launchd and
    # postActivation after launchd. Keep the gate closed across that interval.
    system.activationScripts.preActivation.text = mkAfter ''
      ${rustdeskAgenixGate} invalidate
    '';

    # Agenix ends its generated script with "exit 0", so an EXIT trap is the
    # only merge-safe hook that runs after decrypt, link, and chown complete.
    launchd.daemons.activate-agenix.script = mkBefore ''
      ${rustdeskAgenixGate} invalidate || exit 1
      # Invoked indirectly by the EXIT trap.
      # shellcheck disable=SC2329
      rustdesk_agenix_gate_exit() {
        status=$?
        trap - EXIT
        if [ "$status" -eq 0 ]; then
          ${rustdeskAgenixGate} publish || status=$?
        fi
        exit "$status"
      }
      trap rustdesk_agenix_gate_exit EXIT
    '';

    system.activationScripts.postActivation.text = mkAfter ''
      if ! ${rustdeskAgenixGate} check; then
        /bin/launchctl kickstart system/org.nixos.activate-agenix \
          >/dev/null 2>&1 || true
      fi
      rustdesk_gate_attempt=0
      until ${rustdeskAgenixGate} check; do
        if [ "$rustdesk_gate_attempt" -ge 120 ]; then
          echo "RustDesk agenix revision gate did not complete" >&2
          exit 1
        fi
        rustdesk_gate_attempt=$((rustdesk_gate_attempt + 1))
        ${pkgs.coreutils}/bin/sleep 1
      done
      unset rustdesk_gate_attempt
    '';

    system.activationScripts.extraActivation.text = mkAfter ''
      (
      set -eu
      umask 077
      echo "installing managed RustDesk app..." >&2
      store_app=${rustdeskApp}/Applications/RustDesk.app
      destination=/Applications/RustDesk.app
      marker=/Applications/.RustDesk.app.nix-owner
      lock=/Applications/.RustDesk.app.nix-lock
      transaction=
      staging=
      old_app=
      old_marker=
      new_marker=
      lock_acquired=0
      commit_done=0

      verify_app() {
        [ -d "$1" ] && [ ! -L "$1" ] \
          && /usr/bin/codesign --verify --deep --strict "$1" >/dev/null 2>&1 \
          && /usr/sbin/spctl -a -t exec "$1" >/dev/null 2>&1
      }
      valid_marker() {
        [ -f "$1" ] && [ ! -L "$1" ] \
          && [ "$(/usr/bin/stat -f %Su:%Sg "$1")" = root:wheel ] \
          && [ "$(/usr/bin/stat -f %Lp "$1")" = 600 ] \
          && ${pkgs.gnugrep}/bin/grep -Fqx \
            "owner=rustdesk-self-hosted-remote-access" "$1"
      }

      verify_app "$store_app" || {
        echo "RustDesk store bundle signature verification failed" >&2
        exit 1
      }

      # Invoked indirectly by the EXIT trap.
      # shellcheck disable=SC2329
      cleanup_transaction() {
        status=$?
        failed=0
        trap - EXIT
        trap : HUP INT TERM

        if [ -n "$transaction" ] && [ -d "$transaction" ] \
          && [ "$commit_done" -eq 0 ] \
          && [ ! -d "$transaction/committed" ] \
          && [ -e "$transaction/prepared" ]; then
          if [ -e "$transaction/had-old" ]; then
            if [ -d "$old_app" ]; then
              if [ -e "$destination" ] || [ -L "$destination" ]; then
                /bin/rm -rf "$destination" || failed=1
              fi
              if [ ! -e "$destination" ] && [ ! -L "$destination" ]; then
                /bin/mv "$old_app" "$destination" || failed=1
              fi
            fi
            if [ "$failed" -eq 0 ] && [ -f "$old_marker" ]; then
              /bin/mv -f "$old_marker" "$marker" || failed=1
            fi
          else
            if [ ! -e "$staging" ] && { [ -e "$destination" ] || [ -L "$destination" ]; }; then
              /bin/rm -rf "$destination" || failed=1
            fi
            if [ "$failed" -eq 0 ] && [ ! -e "$new_marker" ] \
              && { [ -e "$marker" ] || [ -L "$marker" ]; }; then
              /bin/rm -f "$marker" || failed=1
            fi
          fi
        fi

        if [ "$failed" -eq 0 ] && [ -n "$transaction" ]; then
          /bin/rm -rf "$transaction" || failed=1
        fi
        if [ "$failed" -eq 0 ] && [ "$lock_acquired" -eq 1 ]; then
          /bin/rmdir "$lock" || failed=1
        fi
        if [ "$failed" -ne 0 ]; then
          echo "RustDesk rollback failed; transaction and lock preserved" >&2
          status=1
        fi
        exit "$status"
      }

      /bin/mkdir -m 0700 "$lock" 2>/dev/null || {
        echo "another or stale RustDesk app transaction holds the lock" >&2
        exit 1
      }
      lock_acquired=1
      trap cleanup_transaction EXIT
      trap 'exit 1' HUP INT TERM
      /usr/sbin/chown root:wheel "$lock"
      [ "$(/usr/bin/stat -f %Su:%Sg "$lock")" = root:wheel ] \
        && [ "$(/usr/bin/stat -f %Lp "$lock")" = 700 ]

      transaction=$(/usr/bin/mktemp -d /Applications/.RustDesk.app.transaction.XXXXXX)
      /bin/chmod 0700 "$transaction"
      /usr/sbin/chown root:wheel "$transaction"
      [ "$(/usr/bin/stat -f %Su:%Sg "$transaction")" = root:wheel ] \
        && [ "$(/usr/bin/stat -f %Lp "$transaction")" = 700 ]
      staging=$transaction/staging.app
      old_app=$transaction/old.app
      old_marker=$transaction/old-marker
      new_marker=$transaction/new-marker

      if [ -e "$destination" ] || [ -L "$destination" ]; then
        if [ ! -d "$destination" ] || [ -L "$destination" ] \
          || ! valid_marker "$marker"; then
          echo "refusing to replace an unmanaged RustDesk app" >&2
          exit 1
        fi
        /usr/bin/touch "$transaction/had-old"
      elif [ -e "$marker" ] || [ -L "$marker" ]; then
        echo "refusing a RustDesk marker without its managed app" >&2
        exit 1
      fi

      /usr/bin/ditto "$store_app" "$staging"
      verify_app "$staging" || {
        echo "RustDesk staging bundle signature verification failed" >&2
        exit 1
      }
      {
        echo "owner=rustdesk-self-hosted-remote-access"
        echo "version=${rustdeskVersion}"
        echo "source=${rustdeskDmgHash}"
      } > "$new_marker"
      /bin/chmod 0600 "$new_marker"
      /usr/sbin/chown root:wheel "$new_marker"
      /usr/bin/touch "$transaction/prepared"

      if [ -e "$transaction/had-old" ]; then
        /bin/mv "$destination" "$old_app"
        /bin/mv "$marker" "$old_marker"
      fi
      /bin/mv "$staging" "$destination"
      verify_app "$destination" || {
        echo "RustDesk destination bundle signature verification failed" >&2
        exit 1
      }
      /bin/mv "$new_marker" "$marker"

      ${rustdeskPublicConfig} apply || {
        echo "RustDesk public configuration failed" >&2
        exit 1
      }
      /bin/mkdir -m 0700 "$transaction/committed"
      commit_done=1
      )
    '';

    environment.launchDaemons."com.carriez.RustDesk_service.plist".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0"><dict>
        <key>Label</key><string>com.carriez.RustDesk_service</string>
        <key>AssociatedBundleIdentifiers</key><string>com.carriez.rustdesk</string>
        <key>ProgramArguments</key><array>
          <string>${rustdeskServiceLauncher}</string>
          <string>${rustdeskServiceLauncherArgument}</string>
          <string>${rustdeskServiceProgram}</string>
        </array>
        <key>RunAtLoad</key><true/><key>KeepAlive</key><true/>
        <key>ThrottleInterval</key><integer>1</integer>
        <key>WorkingDirectory</key><string>/Applications/RustDesk.app/Contents/MacOS/</string>
        <key>SoftResourceLimits</key><dict><key>Core</key><integer>0</integer></dict>
        <key>HardResourceLimits</key><dict><key>Core</key><integer>0</integer></dict>
        <key>StandardOutPath</key><string>/dev/null</string>
        <key>StandardErrorPath</key><string>/dev/null</string>
      </dict></plist>
    '';

    environment.launchAgents."com.carriez.RustDesk_server.plist".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0"><dict>
        <key>Label</key><string>com.carriez.RustDesk_server</string>
        <key>AssociatedBundleIdentifiers</key><string>com.carriez.rustdesk</string>
        <key>LimitLoadToSessionType</key><array>
          <string>LoginWindow</string><string>Aqua</string>
        </array>
        <key>ProgramArguments</key><array>
          <string>/Applications/RustDesk.app/Contents/MacOS/RustDesk</string>
          <string>--server</string>
        </array>
        <key>RunAtLoad</key><true/>
        <key>KeepAlive</key><dict>
          <key>SuccessfulExit</key><false/>
          <key>AfterInitialDemand</key><false/>
        </dict>
        <key>ThrottleInterval</key><integer>1</integer>
        <key>ProcessType</key><string>Interactive</string>
        <key>WorkingDirectory</key><string>/Applications/RustDesk.app/Contents/MacOS/</string>
        <key>SoftResourceLimits</key><dict><key>Core</key><integer>0</integer></dict>
        <key>HardResourceLimits</key><dict><key>Core</key><integer>0</integer></dict>
        <key>StandardOutPath</key><string>/dev/null</string>
        <key>StandardErrorPath</key><string>/dev/null</string>
      </dict></plist>
    '';

    environment.launchDaemons."com.carriez.RustDesk_provision.plist".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0"><dict>
        <key>Label</key><string>com.carriez.RustDesk_provision</string>
        <key>ProgramArguments</key><array>
          <string>${pkgs.coreutils}/bin/timeout</string>
          <string>--signal=TERM</string><string>--kill-after=10s</string>
          <string>5m</string><string>${rustdeskProvision}</string>
        </array>
        <key>RunAtLoad</key><true/>
        <key>StartInterval</key><integer>300</integer>
        <key>ProcessType</key><string>Background</string>
        <key>SoftResourceLimits</key><dict><key>Core</key><integer>0</integer></dict>
        <key>HardResourceLimits</key><dict><key>Core</key><integer>0</integer></dict>
        <key>StandardOutPath</key><string>/dev/null</string>
        <key>StandardErrorPath</key><string>/dev/null</string>
      </dict></plist>
    '';

    system.primaryUser = "c1";
    system.stateVersion = 6;
  };
}

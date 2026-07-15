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
      rustdeskVersion = "1.4.9";
      rustdeskHost = "rustdesk.0xc1.wang";
      rustdeskDmgHash = "sha256-95NVl7JH1CyPKi7XEXap9YaAGM2eGjO4CWQYpmjIyvA=";
      rustdeskBundleId = "com.carriez.rustdesk";
      rustdeskTeamId = "HZF9JMC8YN";
      rustdeskGatekeeperOrigin = "Developer ID Application: zhou huabing (HZF9JMC8YN)";
      rustdeskServiceLauncher = "/bin/sh";
      rustdeskServiceLauncherArgument = "-c";
      rustdeskServiceProgram = "/Applications/RustDesk.app/Contents/MacOS/service";
      rustdeskServerProgram = "/Applications/RustDesk.app/Contents/MacOS/RustDesk";
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

        [ "$#" -le 1 ] || exit 2
        app=''${1:-/Applications/RustDesk.app}
        timeout=${pkgs.coreutils}/bin/timeout
        [ -d "$app" ] && [ ! -L "$app" ] || exit 1
        "$timeout" --signal=TERM --kill-after=5s 30s \
          /usr/bin/codesign --verify --deep --strict "$app" \
          >/dev/null 2>&1
        identity=$("$timeout" --signal=TERM --kill-after=5s 30s \
          /usr/bin/codesign -d --verbose=4 "$app" 2>&1) \
          || exit 1
        # The following single-quoted programs are awk, not shell expressions.
        # shellcheck disable=SC2016
        /usr/bin/printf '%s\n' "$identity" | /usr/bin/awk \
          -v expected_identifier=${escapeShellArg rustdeskBundleId} \
          -v expected_team=${escapeShellArg rustdeskTeamId} '
            $0 == "Identifier=" expected_identifier { identifier_count += 1 }
            $0 == "TeamIdentifier=" expected_team { team_count += 1 }
            END {
              if (identifier_count != 1 || team_count != 1) exit 1
            }
          ' || exit 1
        gatekeeper=$("$timeout" --signal=TERM --kill-after=5s 30s \
          /usr/sbin/spctl -a -vv -t exec "$app" 2>&1) \
          || exit 1
        # shellcheck disable=SC2016
        /usr/bin/printf '%s\n' "$gatekeeper" | /usr/bin/awk \
          -v expected_origin=${escapeShellArg rustdeskGatekeeperOrigin} '
            $0 == "origin=" expected_origin { origin_count += 1 }
            END { if (origin_count != 1) exit 1 }
          '
      '';
      rustdeskPublicConfig = pkgs.writeShellScript "charlie-rustdesk-public-config" ''
        set -eu
        umask 077

        rustdesk=${escapeShellArg rustdeskServerProgram}
        timeout=${pkgs.coreutils}/bin/timeout

        ${rustdeskAppVerify}

        context=$(/usr/bin/mktemp -d \
          /tmp/charlie-rustdesk-public-config.XXXXXX)
        home=$context/home
        config_home=$context/config
        # Invoked indirectly by the EXIT trap.
        # shellcheck disable=SC2329
        cleanup() {
          /bin/rm -rf -- "$context"
        }
        trap cleanup EXIT
        trap 'exit 1' HUP INT TERM

        /bin/chmod 0700 "$context"
        /usr/bin/install -d -m 0700 -o root -g wheel \
          "$home" "$config_home"
        for directory in "$context" "$home" "$config_home"; do
          metadata=$(/usr/bin/stat -f '%u:%g:%Lp' "$directory" 2>/dev/null) \
            || exit 1
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
          HOME="$home" XDG_CONFIG_HOME="$config_home" /usr/bin/env \
            "$timeout" --signal=TERM --kill-after=5s 15s \
            "$rustdesk" "$@" >/dev/null 2>&1 || status=$?
        else
          HOME="$home" XDG_CONFIG_HOME="$config_home" /usr/bin/env \
            "$timeout" --signal=TERM --kill-after=5s 15s \
            "$rustdesk" "$@" 2>/dev/null || status=$?
        fi
        exit "$status"
      '';
      rustdeskLaunchctlParser = pkgs.writeShellScript "charlie-rustdesk-launchctl-parser" ''
        set -eu

        [ "$#" -ge 3 ] && [ "$#" -le 4 ] || exit 2
        expected_program=$1
        shift
        expected_arg_count=$#
        expected_arg1=$1
        expected_arg2=$2
        expected_arg3=''${3:-}

        if [ -x /usr/bin/awk ]; then
          awk=/usr/bin/awk
        elif command -v awk >/dev/null 2>&1; then
          awk=$(command -v awk)
        elif command -v nawk >/dev/null 2>&1; then
          awk=$(command -v nawk)
        else
          exit 1
        fi

        # The following single-quoted program is awk, not a shell expression.
        # shellcheck disable=SC2016
        "$awk" \
          -v expected_program="$expected_program" \
          -v expected_arg_count="$expected_arg_count" \
          -v expected_arg1="$expected_arg1" \
          -v expected_arg2="$expected_arg2" \
          -v expected_arg3="$expected_arg3" '
            function trimmed(line, value) {
              value = line
              sub(/^[[:space:]]*/, "", value)
              sub(/[[:space:]]*$/, "", value)
              return value
            }
            {
              line = $0
              open_text = line
              close_text = line
              opens = gsub(/\{/, "", open_text)
              closes = gsub(/\}/, "", close_text)
              text = trimmed(line)

              if (!started) {
                if (text == "") next
                if (opens != 1 || closes != 0 ||
                    line !~ /=[[:space:]]*\{[[:space:]]*$/) invalid = 1
                started = 1
              } else if (ended) {
                if (text != "") invalid = 1
                next
              } else if (depth == 1) {
                if ($1 == "state" && $2 == "=") {
                  state_count += 1
                  if (NF != 3 || opens != 0 || closes != 0) invalid = 1
                  state = $3
                } else if ($1 == "pid" && $2 == "=") {
                  pid_count += 1
                  if (NF != 3 || $3 !~ /^[0-9]+$/ ||
                      opens != 0 || closes != 0) invalid = 1
                  pid = $3
                } else if ($1 == "program" && $2 == "=") {
                  program_count += 1
                  if (NF != 3 || opens != 0 || closes != 0) invalid = 1
                  program = $3
                } else if ($1 == "arguments" && $2 == "=") {
                  arguments_count += 1
                  if (NF != 3 || $3 != "{" || opens != 1 || closes != 0) {
                    invalid = 1
                  } else {
                    in_arguments = 1
                  }
                }
              } else if (in_arguments && depth == 2) {
                if (text == "}" && opens == 0 && closes == 1) {
                  in_arguments = 0
                } else {
                  if (text == "" || opens != 0 || closes != 0) invalid = 1
                  argument_count += 1
                  argument[argument_count] = text
                }
              }

              depth += opens - closes
              if (depth < 0) invalid = 1
              if (started && depth == 0) ended = 1
            }
            END {
              if (invalid || !started || !ended || depth != 0 || in_arguments ||
                  state_count != 1 || state != "running" ||
                  pid_count != 1 || pid <= 1 ||
                  program_count != 1 || program != expected_program ||
                  arguments_count != 1 ||
                  argument_count != expected_arg_count ||
                  argument[1] != expected_arg1 ||
                  argument[2] != expected_arg2 ||
                  (expected_arg_count == 3 && argument[3] != expected_arg3)) {
                exit 1
              }
              print pid
            }
          '
      '';
      rustdeskRevisionValue = "charlie-rustdesk-provision-v4:${builtins.hashString "sha256" ''
        version=${rustdeskVersion}
        source=${rustdeskDmgHash}
        public-config=${rustdeskPublicConfig}
        launchctl-parser=${rustdeskLaunchctlParser}
        provision=charlie-rustdesk-provision-v10
        ready-to-finalize=charlie-rustdesk-ready-v1
        manual-finalize=charlie-rustdesk-finalize-v1
        ciphertext=${./secrets/rustdesk-password.age}
      ''}";
      rustdeskRevision = pkgs.writeText "charlie-rustdesk-revision" ''
        ${rustdeskRevisionValue}
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

        rustdesk=${escapeShellArg rustdeskServerProgram}
        rustdesk_user=c1
        password_home=/var/root
        password_config_home=/var/root/.config
        state=/var/db/rustdesk-provision
        stamp=$state/stamp
        reservation=$state/attempt
        ready=$state/ready-to-finalize
        operation_lock=$state/operation.lock
        revision_prefix=charlie-rustdesk-provision-v4:
        current_revision=${escapeShellArg rustdeskRevisionValue}
        object_tmp=
        ready_tmp=
        ready_cleanup_required=0
        lock_acquired=0
        result=
        cleanup() {
          [ -z "$result" ] || /bin/rm -f "$result"
          [ -z "$object_tmp" ] || /bin/rm -f "$object_tmp"
          [ -z "$ready_tmp" ] || /bin/rm -f "$ready_tmp"
          if [ "$ready_cleanup_required" -eq 1 ]; then
            remove_current_ready >/dev/null 2>&1 || true
          fi
          if [ "$lock_acquired" -eq 1 ]; then
            /bin/rmdir "$operation_lock" >/dev/null 2>&1 || true
          fi
        }
        trap cleanup EXIT
        trap 'exit 1' HUP INT TERM
        fail() { echo "RustDesk provisioning failed: $1" >&2; exit 1; }

        verify_app() {
          ${rustdeskAppVerify}
        }

        validate_state_directory() {
          [ -d "$state" ] && [ ! -L "$state" ] || return 1
          metadata=$(/usr/bin/stat -f '%u:%g:%Lp' "$state" 2>/dev/null) \
            || return 1
          [ "$metadata" = 0:0:700 ]
        }

        validate_operation_lock() {
          [ -d "$operation_lock" ] && [ ! -L "$operation_lock" ] \
            || return 1
          metadata=$(/usr/bin/stat -f '%u:%g:%Lp' \
            "$operation_lock" 2>/dev/null) || return 1
          [ "$metadata" = 0:0:700 ] || return 1
          lock_entry=$(/bin/ls -A "$operation_lock" 2>/dev/null) || return 1
          [ -z "$lock_entry" ]
        }

        acquire_operation_lock() {
          [ "$(/usr/bin/id -u)" = 0 ] || return 1
          validate_state_directory || return 1
          if ! /bin/mkdir -m 0700 "$operation_lock" 2>/dev/null; then
            validate_operation_lock || return 1
            return 1
          fi
          lock_acquired=1
          /usr/sbin/chown root:wheel "$operation_lock" || return 1
          validate_operation_lock
        }

        release_operation_lock() {
          [ "$lock_acquired" -eq 1 ] || return 1
          validate_operation_lock || return 1
          /bin/rmdir "$operation_lock" || return 1
          lock_acquired=0
          [ ! -e "$operation_lock" ] && [ ! -L "$operation_lock" ]
        }

        inspect_revision_object() {
          object_path=$1
          object_state=
          if [ ! -e "$object_path" ] && [ ! -L "$object_path" ]; then
            object_state=absent
            return 0
          fi

          [ -f "$object_path" ] && [ ! -L "$object_path" ] || return 1
          metadata=$(/usr/bin/stat -f '%u:%g:%Lp' "$object_path" 2>/dev/null) \
            || return 1
          [ "$metadata" = 0:0:600 ] || return 1

          bytes=$(/usr/bin/wc -c < "$object_path") || return 1
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
          object_tmp=$(/usr/bin/mktemp "$state/$object_name.tmp.XXXXXX") \
            || return 1
          /usr/bin/install -m 0600 -o root -g wheel \
            ${rustdeskRevision} "$object_tmp" || return 1
          inspect_revision_object "$object_tmp" || return 1
          [ "$object_state" = current ] || return 1
          ${pkgs.coreutils}/bin/timeout --signal=TERM --kill-after=5s 15s \
            ${pkgs.coreutils}/bin/sync -f "$object_tmp" || return 1
          /bin/mv -f "$object_tmp" "$publish_object_path" || return 1
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
          metadata=$(/usr/bin/stat -f '%u:%g:%Lp' "$ready_path" 2>/dev/null) \
            || return 1
          [ "$metadata" = 0:0:600 ] || return 1
          ready_line_count=$(/usr/bin/wc -l < "$ready_path") || return 1
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

          ready_bytes=$(/usr/bin/wc -c < "$ready_path") || return 1
          ready_expected_bytes=$((
            ''${#ready_line1} + ''${#ready_line2} + ''${#ready_line3} \
            + ''${#ready_line4} + ''${#ready_line5} + ''${#ready_line6} \
            + ''${#ready_line7} + ''${#ready_line8} + ''${#ready_line9} \
            + ''${#ready_line10} + ''${#ready_line11} + 11
          ))
          [ "$ready_bytes" -eq "$ready_expected_bytes" ] || return 1
          [ "$ready_line1" = format=rustdesk-ready-v1 ] || return 1
          [ "$ready_line2" = host=charlie ] || return 1

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

          case "$ready_line4" in service.pid=*) ;; *) return 1 ;; esac
          ready_service_pid=''${ready_line4#service.pid=}
          case "$ready_service_pid" in ""|*[!0-9]*) return 1 ;; esac
          [ "$ready_service_pid" -gt 1 ] || return 1
          case "$ready_line5" in service.start_sha256=*) ;; *) return 1 ;; esac
          ready_service_start=''${ready_line5#service.start_sha256=}
          [ "''${#ready_service_start}" -eq 64 ] || return 1
          case "$ready_service_start" in *[!0-9a-f]*) return 1 ;; esac
          case "$ready_line6" in service.executable=*) ;; *) return 1 ;; esac
          ready_service_exe=''${ready_line6#service.executable=}
          [ "$ready_service_exe" = ${escapeShellArg rustdeskServiceProgram} ] \
            || return 1
          case "$ready_line7" in service.uid=*) ;; *) return 1 ;; esac
          ready_service_uid=''${ready_line7#service.uid=}
          [ "$ready_service_uid" = 0 ] || return 1

          case "$ready_line8" in server.pid=*) ;; *) return 1 ;; esac
          ready_server_pid=''${ready_line8#server.pid=}
          case "$ready_server_pid" in ""|*[!0-9]*) return 1 ;; esac
          [ "$ready_server_pid" -gt 1 ] || return 1
          case "$ready_line9" in server.start_sha256=*) ;; *) return 1 ;; esac
          ready_server_start=''${ready_line9#server.start_sha256=}
          [ "''${#ready_server_start}" -eq 64 ] || return 1
          case "$ready_server_start" in *[!0-9a-f]*) return 1 ;; esac
          case "$ready_line10" in server.executable=*) ;; *) return 1 ;; esac
          ready_server_exe=''${ready_line10#server.executable=}
          [ "$ready_server_exe" = ${escapeShellArg rustdeskServerProgram} ] \
            || return 1
          case "$ready_line11" in server.uid=*) ;; *) return 1 ;; esac
          ready_server_uid=''${ready_line11#server.uid=}
          case "$ready_server_uid" in ""|*[!0-9]*) return 1 ;; esac
          [ "$ready_server_uid" -gt 0 ] || return 1

          if [ "$ready_revision" = "$current_revision" ]; then
            expected_server_uid=$(/usr/bin/id -u "$rustdesk_user" 2>/dev/null) \
              || return 1
            [ "$ready_server_uid" = "$expected_server_uid" ] || return 1
            ready_state=current
          else
            ready_state=stale
          fi
        }

        remove_ready_object() {
          expected_ready_state=$1
          inspect_ready_object "$ready" || return 1
          [ "$ready_state" = "$expected_ready_state" ] || return 1
          /bin/rm -f -- "$ready" || return 1
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
          publish_service_pid=$1
          publish_service_start=$2
          publish_service_exe=$3
          publish_service_uid=$4
          publish_server_pid=$5
          publish_server_start=$6
          publish_server_exe=$7
          publish_server_uid=$8

          inspect_ready_object "$ready" || return 1
          [ "$ready_state" = absent ] || return 1
          ready_tmp=$(/usr/bin/mktemp \
            "$state/ready-to-finalize.tmp.XXXXXX") || return 1
          /usr/bin/printf '%s\n' \
            format=rustdesk-ready-v1 \
            host=charlie \
            "revision=$current_revision" \
            "service.pid=$publish_service_pid" \
            "service.start_sha256=$publish_service_start" \
            "service.executable=$publish_service_exe" \
            "service.uid=$publish_service_uid" \
            "server.pid=$publish_server_pid" \
            "server.start_sha256=$publish_server_start" \
            "server.executable=$publish_server_exe" \
            "server.uid=$publish_server_uid" > "$ready_tmp" || return 1
          /bin/chmod 0600 "$ready_tmp" || return 1
          /usr/sbin/chown root:wheel "$ready_tmp" || return 1
          inspect_ready_object "$ready_tmp" || return 1
          [ "$ready_state" = current ] || return 1
          ${pkgs.coreutils}/bin/timeout --signal=TERM --kill-after=5s 15s \
            ${pkgs.coreutils}/bin/sync -f "$ready_tmp" || return 1
          ready_cleanup_required=1
          /bin/mv -f "$ready_tmp" "$ready" || return 1
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
          metadata=$(/usr/bin/stat -f '%Su:%Sg:%Lp' "$target" 2>/dev/null) \
            || return 1
          [ "$metadata" = ${escapeShellArg rustdeskSecretMetadata} ] \
            || return 1
          [ -r "$target" ] || return 1
          printf '%s\n' "$target"
        }

        prepare_password_context() {
          [ -d "$password_home" ] && [ ! -L "$password_home" ] \
            || return 1
          metadata=$(/usr/bin/stat -f '%u:%g' "$password_home" 2>/dev/null) \
            || return 1
          [ "$metadata" = 0:0 ] || return 1

          if [ -e "$password_config_home" ] \
            || [ -L "$password_config_home" ]; then
            [ -d "$password_config_home" ] \
              && [ ! -L "$password_config_home" ] || return 1
          else
            /usr/bin/install -d -m 0700 -o root -g wheel \
              "$password_config_home" || return 1
          fi
          metadata=$(/usr/bin/stat -f '%u:%g' \
            "$password_config_home" 2>/dev/null) || return 1
          [ "$metadata" = 0:0 ]
        }

        ps_start_identity() {
          identity_pid=$1
          identity_fields=$(LC_ALL=C TZ=UTC /bin/ps -ww -p "$identity_pid" \
            -o pid= -o uid= -o ruid= -o lstart= -o comm= -o command= \
            2>/dev/null) || return 1
          [ -n "$identity_fields" ] || return 1
          identity_lines=$(/usr/bin/printf '%s\n' "$identity_fields" \
            | /usr/bin/wc -l) || return 1
          [ "$identity_lines" -eq 1 ] || return 1
          identity_hash=$(/usr/bin/printf '%s\n' "$identity_fields" \
            | ${pkgs.coreutils}/bin/sha256sum) || return 1
          identity_hash=''${identity_hash%% *}
          [ "''${#identity_hash}" -eq 64 ] || return 1
          case "$identity_hash" in *[!0-9a-f]*) return 1 ;; esac
          /usr/bin/printf '%s\n' "$identity_hash"
        }

        validate_user_server() {
          uid=$(/usr/bin/id -u "$rustdesk_user" 2>/dev/null) || return 1
          wheel_gid=0
          ipc_parent=/tmp/RustDesk-$uid
          ipc=$ipc_parent/ipc
          pid_file=$ipc.pid

          [ -d "$ipc_parent" ] && [ ! -L "$ipc_parent" ] || return 1
          metadata=$(/usr/bin/stat -f '%u:%g:%Lp' "$ipc_parent" 2>/dev/null) \
            || return 1
          [ "$metadata" = "$uid:$wheel_gid:700" ] || return 1

          [ -S "$ipc" ] && [ ! -L "$ipc" ] || return 1
          metadata=$(/usr/bin/stat -f '%u:%g:%Lp' "$ipc" 2>/dev/null) \
            || return 1
          [ "$metadata" = "$uid:$wheel_gid:600" ] || return 1

          [ -f "$pid_file" ] && [ ! -L "$pid_file" ] || return 1
          metadata=$(/usr/bin/stat -f '%u:%g:%Lp' "$pid_file" 2>/dev/null) \
            || return 1
          [ "$metadata" = "$uid:$wheel_gid:600" ] || return 1
          pid_bytes=$(/usr/bin/wc -c < "$pid_file") || return 1
          server_pid=
          IFS= read -r server_pid < "$pid_file" \
            || [ -n "$server_pid" ] || return 1
          [ "$pid_bytes" -eq "''${#server_pid}" ] || return 1
          case "$server_pid" in ""|0|1|*[!0-9]*) return 1 ;; esac

          launch_output=$(/bin/launchctl print \
            "gui/$uid/com.carriez.RustDesk_server" 2>/dev/null) \
            || return 1
          launch_pid=$(/usr/bin/printf '%s\n' "$launch_output" \
            | ${rustdeskLaunchctlParser} \
              ${escapeShellArg rustdeskServerProgram} \
              ${escapeShellArg rustdeskServerProgram} --server) \
            || return 1
          [ "$launch_pid" = "$server_pid" ] || return 1

          process_start=$(ps_start_identity "$server_pid") || return 1
          process_uid=$(/bin/ps -p "$server_pid" -o uid= 2>/dev/null \
            | /usr/bin/tr -d '[:space:]') || return 1
          [ "$process_uid" = "$uid" ] || return 1
          process_exe=$(/bin/ps -ww -p "$server_pid" -o comm= 2>/dev/null) \
            || return 1
          process_command=$(/bin/ps -ww -p "$server_pid" -o command= 2>/dev/null) \
            || return 1
          [ "$process_exe" = "$rustdesk" ] \
            && [ "$process_command" = "$rustdesk --server" ] || return 1
          executable_pid=$(/usr/sbin/lsof -nP -t -a -p "$server_pid" \
            -d txt -- "$rustdesk" 2>/dev/null) || return 1
          [ "$executable_pid" = "$server_pid" ] || return 1

          socket_pid=$(/usr/sbin/lsof -nP -t -a -p "$server_pid" \
            -U -- "$ipc" 2>/dev/null) || return 1
          [ "$socket_pid" = "$server_pid" ] || return 1
          process_start_after=$(ps_start_identity "$server_pid") || return 1
          [ "$process_start_after" = "$process_start" ] || return 1
          validated_server_pid=$server_pid
          validated_server_start=$process_start
          validated_server_exe=$process_exe
          validated_server_uid=$process_uid
        }

        validate_privileged_service() {
          launch_output=$(/bin/launchctl print \
            system/com.carriez.RustDesk_service 2>/dev/null) \
            || return 1
          service_pid=$(/usr/bin/printf '%s\n' "$launch_output" \
            | ${rustdeskLaunchctlParser} \
              ${escapeShellArg rustdeskServiceLauncher} \
              ${escapeShellArg rustdeskServiceLauncher} \
              ${escapeShellArg rustdeskServiceLauncherArgument} \
              ${escapeShellArg rustdeskServiceProgram}) || return 1

          process_start=$(ps_start_identity "$service_pid") || return 1
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
          process_start_after=$(ps_start_identity "$service_pid") || return 1
          [ "$process_start_after" = "$process_start" ] || return 1
          validated_service_pid=$service_pid
          validated_service_start=$process_start
          validated_service_exe=${escapeShellArg rustdeskServiceProgram}
          validated_service_uid=$process_uid
        }

        validate_runtime_pids() {
          expected_service_pid=$1
          expected_server_pid=$2
          validate_privileged_service || return 1
          [ "$validated_service_pid" = "$expected_service_pid" ] || return 1
          validate_user_server || return 1
          [ "$validated_server_pid" = "$expected_server_pid" ]
        }

        validate_ready_runtime() {
          validate_privileged_service || return 1
          [ "$validated_service_pid" = "$ready_service_pid" ] \
            && [ "$validated_service_start" = "$ready_service_start" ] \
            && [ "$validated_service_exe" = "$ready_service_exe" ] \
            && [ "$validated_service_uid" = "$ready_service_uid" ] \
            || return 1
          validate_user_server || return 1
          [ "$validated_server_pid" = "$ready_server_pid" ] \
            && [ "$validated_server_start" = "$ready_server_start" ] \
            && [ "$validated_server_exe" = "$ready_server_exe" ] \
            && [ "$validated_server_uid" = "$ready_server_uid" ]
        }

        runtime_ready() {
          verify_app || return 1
          validate_privileged_service || return 1
          ready_service_pid=$validated_service_pid
          ready_service_start=$validated_service_start
          validate_user_server || return 1
          ready_server_pid=$validated_server_pid
          ready_server_start=$validated_server_start
        }

        wait_runtime() {
          attempt=0
          while [ "$attempt" -lt 60 ]; do
            if runtime_ready; then
              candidate_service_pid=$ready_service_pid
              candidate_service_start=$ready_service_start
              candidate_server_pid=$ready_server_pid
              candidate_server_start=$ready_server_start
              ${pkgs.coreutils}/bin/sleep 2
              if validate_runtime_pids \
                "$candidate_service_pid" "$candidate_server_pid" \
                && [ "$validated_service_start" = "$candidate_service_start" ] \
                && [ "$validated_server_start" = "$candidate_server_start" ]; then
                ready_service_pid=$candidate_service_pid
                ready_service_start=$candidate_service_start
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
          expected_service_pid=$1
          expected_server_pid=$2
          public_mode=$3
          validate_runtime_pids \
            "$expected_service_pid" "$expected_server_pid" || return 1
          public_value=
          public_status=0
          public_value=$(${rustdeskPublicConfig} "$public_mode") \
            || public_status=$?
          validate_runtime_pids \
            "$expected_service_pid" "$expected_server_pid" || return 1
          [ "$public_status" -eq 0 ]
        }

        prove_public_config() {
          expected_service_pid=$1
          expected_server_pid=$2

          run_public_step "$expected_service_pid" "$expected_server_pid" \
            query-host || return 1
          [ "$public_value" = ${escapeShellArg rustdeskHost} ] || return 1
          run_public_step "$expected_service_pid" "$expected_server_pid" \
            query-key || return 1
          [ "$public_value" = ${escapeShellArg rustdeskPublicKey} ] || return 1
          run_public_step "$expected_service_pid" "$expected_server_pid" \
            query-relay || return 1
          [ "$public_value" = ${escapeShellArg rustdeskHost} ] || return 1
          run_public_step "$expected_service_pid" "$expected_server_pid" \
            query-verification-method || return 1
          [ "$public_value" = use-permanent-password ] || return 1
          run_public_step "$expected_service_pid" "$expected_server_pid" \
            query-approve-mode || return 1
          [ "$public_value" = password ] || return 1
          run_public_step "$expected_service_pid" "$expected_server_pid" \
            query-auto-update || return 1
          [ "$public_value" = N ]
        }

        apply_and_prove_public_config() {
          expected_service_pid=$1
          expected_server_pid=$2
          for public_mode in \
            apply-server \
            apply-verification-method \
            apply-approve-mode \
            apply-auto-update; do
            run_public_step "$expected_service_pid" "$expected_server_pid" \
              "$public_mode" || return 1
          done
          prove_public_config "$expected_service_pid" "$expected_server_pid"
        }

        ${rustdeskAgenixGate} prepare || fail state
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

        verify_app || fail app-trust
        wait_runtime || fail readiness
        provision_service_pid=$ready_service_pid
        provision_server_pid=$ready_server_pid
        apply_and_prove_public_config \
          "$provision_service_pid" "$provision_server_pid" \
          || fail public-config
        ${rustdeskAgenixGate} check || fail agenix-revision
        validate_runtime_pids \
          "$provision_service_pid" "$provision_server_pid" \
          || fail runtime-changed-before-reservation
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
        ${rustdeskAgenixGate} check || fail agenix-revision
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

        prepare_password_context || {
          unset password
          fail password-context
        }
        verify_app || {
          unset password
          fail app-trust
        }
        ${rustdeskAgenixGate} check || {
          unset password
          fail agenix-revision
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
          "$provision_service_pid" "$provision_server_pid" || {
          unset password
          fail runtime-changed-before-password
        }
        result=$(/usr/bin/mktemp "$state/result.XXXXXX")
        status=0
        HOME="$password_home" XDG_CONFIG_HOME="$password_config_home" \
          /usr/bin/env \
          ${pkgs.coreutils}/bin/timeout --signal=TERM --kill-after=5s 15s \
          "$rustdesk" --password "$password" > "$result" 2>&1 \
          || status=$?
        unset password
        [ "$status" -eq 0 ] || fail password-command
        result_bytes=$(/usr/bin/wc -c < "$result") || fail password-result
        [ "$result_bytes" -eq 6 ] || fail password-result
        exec 3< "$result"
        IFS= read -r line <&3 || fail password-result
        if IFS= read -r _ <&3; then fail password-result; fi
        exec 3<&-
        [ "$line" = "Done!" ] || fail password-result
        unset line
        unset result_bytes
        /bin/rm -f "$result"
        result=

        validate_runtime_pids \
          "$provision_service_pid" "$provision_server_pid" \
          || fail runtime-changed-during-password

        /bin/launchctl kickstart -k system/com.carriez.RustDesk_service
        uid=$(/usr/bin/id -u "$rustdesk_user")
        /bin/launchctl asuser "$uid" /bin/launchctl kickstart -k \
          "gui/$uid/com.carriez.RustDesk_server"
        wait_runtime || fail restart
        [ "$ready_service_pid" != "$provision_service_pid" ] \
          || fail service-not-restarted
        [ "$ready_server_pid" != "$provision_server_pid" ] \
          || fail server-not-restarted
        prove_public_config "$ready_service_pid" "$ready_server_pid" \
          || fail public-config-after-restart
        validate_runtime_pids "$ready_service_pid" "$ready_server_pid" \
          || fail runtime-changed-after-restart
        post_service_pid=$validated_service_pid
        post_service_start=$validated_service_start
        post_service_exe=$validated_service_exe
        post_service_uid=$validated_service_uid
        post_server_pid=$validated_server_pid
        post_server_start=$validated_server_start
        post_server_exe=$validated_server_exe
        post_server_uid=$validated_server_uid
        inspect_revision_object "$reservation" || fail reservation
        [ "$object_state" = current ] || fail reservation
        inspect_ready_object "$ready" || fail ready
        [ "$ready_state" = absent ] || fail ready
        publish_ready_object \
          "$post_service_pid" "$post_service_start" \
          "$post_service_exe" "$post_service_uid" \
          "$post_server_pid" "$post_server_start" \
          "$post_server_exe" "$post_server_uid" \
          || fail ready-publish
        inspect_ready_object "$ready" || fail ready
        [ "$ready_state" = current ] || fail ready
        validate_ready_runtime || fail runtime-changed-after-ready
        ready_cleanup_required=0
        release_operation_lock || fail operation-unlock
        trap - EXIT HUP INT TERM
      '';
      rustdeskFinalizeScript = ''
        set -eu
        umask 077

        rustdesk=${escapeShellArg rustdeskServerProgram}
        rustdesk_user=c1
        state=/var/db/rustdesk-provision
        stamp=$state/stamp
        reservation=$state/attempt
        ready=$state/ready-to-finalize
        operation_lock=$state/operation.lock
        revision_prefix=charlie-rustdesk-provision-v4:
        current_revision=${escapeShellArg rustdeskRevisionValue}
        object_tmp=
        lock_acquired=0
        cleanup() {
          [ -z "$object_tmp" ] || /bin/rm -f "$object_tmp"
          if [ "$lock_acquired" -eq 1 ]; then
            /bin/rmdir "$operation_lock" >/dev/null 2>&1 || true
          fi
        }
        trap cleanup EXIT
        trap 'exit 1' HUP INT TERM
        fail() { echo "RustDesk finalization failed: $1" >&2; exit 1; }

        [ "$#" -eq 1 ] && [ "$1" = --confirm-remote-auth ] \
          || fail confirmation-required
        [ "$(/usr/bin/id -u)" = 0 ] || fail root-required

        verify_app() {
          ${rustdeskAppVerify}
        }

        validate_state_directory() {
          [ -d "$state" ] && [ ! -L "$state" ] || return 1
          metadata=$(/usr/bin/stat -f '%u:%g:%Lp' "$state" 2>/dev/null) \
            || return 1
          [ "$metadata" = 0:0:700 ]
        }

        validate_operation_lock() {
          [ -d "$operation_lock" ] && [ ! -L "$operation_lock" ] \
            || return 1
          metadata=$(/usr/bin/stat -f '%u:%g:%Lp' \
            "$operation_lock" 2>/dev/null) || return 1
          [ "$metadata" = 0:0:700 ] || return 1
          lock_entry=$(/bin/ls -A "$operation_lock" 2>/dev/null) || return 1
          [ -z "$lock_entry" ]
        }

        acquire_operation_lock() {
          validate_state_directory || return 1
          if ! /bin/mkdir -m 0700 "$operation_lock" 2>/dev/null; then
            validate_operation_lock || return 1
            return 1
          fi
          lock_acquired=1
          /usr/sbin/chown root:wheel "$operation_lock" || return 1
          validate_operation_lock
        }

        release_operation_lock() {
          [ "$lock_acquired" -eq 1 ] || return 1
          validate_operation_lock || return 1
          /bin/rmdir "$operation_lock" || return 1
          lock_acquired=0
          [ ! -e "$operation_lock" ] && [ ! -L "$operation_lock" ]
        }

        inspect_revision_object() {
          object_path=$1
          object_state=
          if [ ! -e "$object_path" ] && [ ! -L "$object_path" ]; then
            object_state=absent
            return 0
          fi
          [ -f "$object_path" ] && [ ! -L "$object_path" ] || return 1
          metadata=$(/usr/bin/stat -f '%u:%g:%Lp' "$object_path" 2>/dev/null) \
            || return 1
          [ "$metadata" = 0:0:600 ] || return 1
          bytes=$(/usr/bin/wc -c < "$object_path") || return 1
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
          object_tmp=$(/usr/bin/mktemp "$state/$object_name.tmp.XXXXXX") \
            || return 1
          /usr/bin/install -m 0600 -o root -g wheel \
            ${rustdeskRevision} "$object_tmp" || return 1
          inspect_revision_object "$object_tmp" || return 1
          [ "$object_state" = current ] || return 1
          ${pkgs.coreutils}/bin/timeout --signal=TERM --kill-after=5s 15s \
            ${pkgs.coreutils}/bin/sync -f "$object_tmp" || return 1
          /bin/mv -f "$object_tmp" "$publish_object_path" || return 1
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
          metadata=$(/usr/bin/stat -f '%u:%g:%Lp' "$ready_path" 2>/dev/null) \
            || return 1
          [ "$metadata" = 0:0:600 ] || return 1
          ready_line_count=$(/usr/bin/wc -l < "$ready_path") || return 1
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
          ready_bytes=$(/usr/bin/wc -c < "$ready_path") || return 1
          ready_expected_bytes=$((
            ''${#ready_line1} + ''${#ready_line2} + ''${#ready_line3} \
            + ''${#ready_line4} + ''${#ready_line5} + ''${#ready_line6} \
            + ''${#ready_line7} + ''${#ready_line8} + ''${#ready_line9} \
            + ''${#ready_line10} + ''${#ready_line11} + 11
          ))
          [ "$ready_bytes" -eq "$ready_expected_bytes" ] || return 1
          [ "$ready_line1" = format=rustdesk-ready-v1 ] || return 1
          [ "$ready_line2" = host=charlie ] || return 1
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
          case "$ready_line4" in service.pid=*) ;; *) return 1 ;; esac
          ready_service_pid=''${ready_line4#service.pid=}
          case "$ready_service_pid" in ""|*[!0-9]*) return 1 ;; esac
          [ "$ready_service_pid" -gt 1 ] || return 1
          case "$ready_line5" in service.start_sha256=*) ;; *) return 1 ;; esac
          ready_service_start=''${ready_line5#service.start_sha256=}
          [ "''${#ready_service_start}" -eq 64 ] || return 1
          case "$ready_service_start" in *[!0-9a-f]*) return 1 ;; esac
          case "$ready_line6" in service.executable=*) ;; *) return 1 ;; esac
          ready_service_exe=''${ready_line6#service.executable=}
          [ "$ready_service_exe" = ${escapeShellArg rustdeskServiceProgram} ] \
            || return 1
          case "$ready_line7" in service.uid=*) ;; *) return 1 ;; esac
          ready_service_uid=''${ready_line7#service.uid=}
          [ "$ready_service_uid" = 0 ] || return 1
          case "$ready_line8" in server.pid=*) ;; *) return 1 ;; esac
          ready_server_pid=''${ready_line8#server.pid=}
          case "$ready_server_pid" in ""|*[!0-9]*) return 1 ;; esac
          [ "$ready_server_pid" -gt 1 ] || return 1
          case "$ready_line9" in server.start_sha256=*) ;; *) return 1 ;; esac
          ready_server_start=''${ready_line9#server.start_sha256=}
          [ "''${#ready_server_start}" -eq 64 ] || return 1
          case "$ready_server_start" in *[!0-9a-f]*) return 1 ;; esac
          case "$ready_line10" in server.executable=*) ;; *) return 1 ;; esac
          ready_server_exe=''${ready_line10#server.executable=}
          [ "$ready_server_exe" = ${escapeShellArg rustdeskServerProgram} ] \
            || return 1
          case "$ready_line11" in server.uid=*) ;; *) return 1 ;; esac
          ready_server_uid=''${ready_line11#server.uid=}
          case "$ready_server_uid" in ""|*[!0-9]*) return 1 ;; esac
          [ "$ready_server_uid" -gt 0 ] || return 1
          if [ "$ready_revision" = "$current_revision" ]; then
            expected_server_uid=$(/usr/bin/id -u "$rustdesk_user" 2>/dev/null) \
              || return 1
            [ "$ready_server_uid" = "$expected_server_uid" ] || return 1
            ready_state=current
          else
            ready_state=stale
          fi
        }

        remove_ready_object() {
          inspect_ready_object "$ready" || return 1
          [ "$ready_state" = current ] || return 1
          /bin/rm -f -- "$ready" || return 1
          ${pkgs.coreutils}/bin/timeout --signal=TERM --kill-after=5s 15s \
            ${pkgs.coreutils}/bin/sync -f "$state" || return 1
          inspect_ready_object "$ready" || return 1
          [ "$ready_state" = absent ]
        }

        ps_start_identity() {
          identity_pid=$1
          identity_fields=$(LC_ALL=C TZ=UTC /bin/ps -ww -p "$identity_pid" \
            -o pid= -o uid= -o ruid= -o lstart= -o comm= -o command= \
            2>/dev/null) || return 1
          [ -n "$identity_fields" ] || return 1
          identity_lines=$(/usr/bin/printf '%s\n' "$identity_fields" \
            | /usr/bin/wc -l) || return 1
          [ "$identity_lines" -eq 1 ] || return 1
          identity_hash=$(/usr/bin/printf '%s\n' "$identity_fields" \
            | ${pkgs.coreutils}/bin/sha256sum) || return 1
          identity_hash=''${identity_hash%% *}
          [ "''${#identity_hash}" -eq 64 ] || return 1
          case "$identity_hash" in *[!0-9a-f]*) return 1 ;; esac
          /usr/bin/printf '%s\n' "$identity_hash"
        }

        validate_user_server() {
          uid=$(/usr/bin/id -u "$rustdesk_user" 2>/dev/null) || return 1
          wheel_gid=0
          ipc_parent=/tmp/RustDesk-$uid
          ipc=$ipc_parent/ipc
          pid_file=$ipc.pid
          [ -d "$ipc_parent" ] && [ ! -L "$ipc_parent" ] || return 1
          metadata=$(/usr/bin/stat -f '%u:%g:%Lp' "$ipc_parent" 2>/dev/null) \
            || return 1
          [ "$metadata" = "$uid:$wheel_gid:700" ] || return 1
          [ -S "$ipc" ] && [ ! -L "$ipc" ] || return 1
          metadata=$(/usr/bin/stat -f '%u:%g:%Lp' "$ipc" 2>/dev/null) \
            || return 1
          [ "$metadata" = "$uid:$wheel_gid:600" ] || return 1
          [ -f "$pid_file" ] && [ ! -L "$pid_file" ] || return 1
          metadata=$(/usr/bin/stat -f '%u:%g:%Lp' "$pid_file" 2>/dev/null) \
            || return 1
          [ "$metadata" = "$uid:$wheel_gid:600" ] || return 1
          pid_bytes=$(/usr/bin/wc -c < "$pid_file") || return 1
          server_pid=
          IFS= read -r server_pid < "$pid_file" \
            || [ -n "$server_pid" ] || return 1
          [ "$pid_bytes" -eq "''${#server_pid}" ] || return 1
          case "$server_pid" in ""|0|1|*[!0-9]*) return 1 ;; esac
          launch_output=$(/bin/launchctl print \
            "gui/$uid/com.carriez.RustDesk_server" 2>/dev/null) \
            || return 1
          launch_pid=$(/usr/bin/printf '%s\n' "$launch_output" \
            | ${rustdeskLaunchctlParser} \
              ${escapeShellArg rustdeskServerProgram} \
              ${escapeShellArg rustdeskServerProgram} --server) \
            || return 1
          [ "$launch_pid" = "$server_pid" ] || return 1
          process_start=$(ps_start_identity "$server_pid") || return 1
          process_uid=$(/bin/ps -p "$server_pid" -o uid= 2>/dev/null \
            | /usr/bin/tr -d '[:space:]') || return 1
          [ "$process_uid" = "$uid" ] || return 1
          process_exe=$(/bin/ps -ww -p "$server_pid" -o comm= 2>/dev/null) \
            || return 1
          process_command=$(/bin/ps -ww -p "$server_pid" -o command= 2>/dev/null) \
            || return 1
          [ "$process_exe" = "$rustdesk" ] \
            && [ "$process_command" = "$rustdesk --server" ] || return 1
          executable_pid=$(/usr/sbin/lsof -nP -t -a -p "$server_pid" \
            -d txt -- "$rustdesk" 2>/dev/null) || return 1
          [ "$executable_pid" = "$server_pid" ] || return 1
          socket_pid=$(/usr/sbin/lsof -nP -t -a -p "$server_pid" \
            -U -- "$ipc" 2>/dev/null) || return 1
          [ "$socket_pid" = "$server_pid" ] || return 1
          process_start_after=$(ps_start_identity "$server_pid") || return 1
          [ "$process_start_after" = "$process_start" ] || return 1
          validated_server_pid=$server_pid
          validated_server_start=$process_start
          validated_server_exe=$process_exe
          validated_server_uid=$process_uid
        }

        validate_privileged_service() {
          launch_output=$(/bin/launchctl print \
            system/com.carriez.RustDesk_service 2>/dev/null) || return 1
          service_pid=$(/usr/bin/printf '%s\n' "$launch_output" \
            | ${rustdeskLaunchctlParser} \
              ${escapeShellArg rustdeskServiceLauncher} \
              ${escapeShellArg rustdeskServiceLauncher} \
              ${escapeShellArg rustdeskServiceLauncherArgument} \
              ${escapeShellArg rustdeskServiceProgram}) || return 1
          process_start=$(ps_start_identity "$service_pid") || return 1
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
          process_start_after=$(ps_start_identity "$service_pid") || return 1
          [ "$process_start_after" = "$process_start" ] || return 1
          validated_service_pid=$service_pid
          validated_service_start=$process_start
          validated_service_exe=${escapeShellArg rustdeskServiceProgram}
          validated_service_uid=$process_uid
        }

        validate_ready_runtime() {
          verify_app || return 1
          validate_privileged_service || return 1
          [ "$validated_service_pid" = "$ready_service_pid" ] \
            && [ "$validated_service_start" = "$ready_service_start" ] \
            && [ "$validated_service_exe" = "$ready_service_exe" ] \
            && [ "$validated_service_uid" = "$ready_service_uid" ] \
            || return 1
          validate_user_server || return 1
          [ "$validated_server_pid" = "$ready_server_pid" ] \
            && [ "$validated_server_start" = "$ready_server_start" ] \
            && [ "$validated_server_exe" = "$ready_server_exe" ] \
            && [ "$validated_server_uid" = "$ready_server_uid" ]
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
        validate_ready_runtime || fail process-identity
        ${pkgs.coreutils}/bin/sleep 2
        inspect_revision_object "$reservation" || fail reservation
        [ "$object_state" = current ] || fail reservation-not-current
        inspect_ready_object "$ready" || fail ready
        [ "$ready_state" = current ] || fail ready-not-current
        validate_ready_runtime || fail process-identity
        publish_revision_object "$stamp" stamp || fail stamp-publish
        remove_ready_object || fail ready-remove
        release_operation_lock || fail operation-unlock
        trap - EXIT HUP INT TERM
      '';
      rustdeskFinalize = pkgs.writeShellScriptBin
        "rustdesk-provision-finalize" rustdeskFinalizeScript;
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

    environment.systemPackages = [ rustdeskFinalize ];

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

    assertions = [
      {
        assertion = rustdeskApp.version == "1.4.9";
        message = "charlie RustDesk client must remain pinned to 1.4.9";
      }
      {
        assertion = rustdeskBundleId == "com.carriez.rustdesk";
        message = "charlie RustDesk bundle id must remain lowercase com.carriez.rustdesk";
      }
      {
        assertion = rustdeskDmgHash == "sha256-95NVl7JH1CyPKi7XEXap9YaAGM2eGjO4CWQYpmjIyvA=";
        message = "charlie RustDesk 1.4.9 DMG hash must remain pinned";
      }
      {
        assertion = all (needle: !(hasInfix needle rustdeskFinalizeScript)) [
          (toString rustdeskSecret.path)
          "--password"
          "resolve_secret"
          "agenix"
        ];
        message = "charlie RustDesk finalizer must not contain a secret path, password invocation, or secret resolver";
      }
    ];

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

      rustdesk_uid=$(/usr/bin/id -u c1) || {
        echo "RustDesk user c1 is unavailable" >&2
        exit 1
      }
      rustdesk_gui_domain="gui/$rustdesk_uid"
      rustdesk_server_job="$rustdesk_gui_domain/com.carriez.RustDesk_server"
      if /bin/launchctl print "$rustdesk_gui_domain" >/dev/null 2>&1; then
        if ! /bin/launchctl print "$rustdesk_server_job" >/dev/null 2>&1; then
          /bin/launchctl bootstrap "$rustdesk_gui_domain" \
            /Library/LaunchAgents/com.carriez.RustDesk_server.plist || {
            echo "RustDesk user agent bootstrap failed" >&2
            exit 1
          }
        fi
        /bin/launchctl kickstart "$rustdesk_server_job" || {
          echo "RustDesk user agent kickstart failed" >&2
          exit 1
        }
      fi
      unset rustdesk_uid rustdesk_gui_domain rustdesk_server_job
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
      app_replacement=1

      verify_app() {
        ${rustdeskAppVerify} "$1"
      }
      bundle_cdhash() {
        cdhash_output=$(${pkgs.coreutils}/bin/timeout \
          --signal=TERM --kill-after=5s 30s \
          /usr/bin/codesign -d --verbose=4 "$1" 2>&1) || return 1
        /usr/bin/printf '%s\n' "$cdhash_output" | /usr/bin/awk '
          /^CDHash=/ {
            count += 1
            value = substr($0, 8)
            if (length(value) < 40 || length(value) > 64 ||
                value !~ /^[[:xdigit:]]+$/) invalid = 1
            cdhash = tolower(value)
          }
          END {
            if (invalid || count != 1) exit 1
            print cdhash
          }
        '
      }
      same_verified_bundle() {
        verify_app "$1" && verify_app "$2" || return 1
        first_cdhash=$(bundle_cdhash "$1") || return 1
        second_cdhash=$(bundle_cdhash "$2") || return 1
        [ "$first_cdhash" = "$second_cdhash" ] || return 1
        /usr/bin/diff -r -q "$1" "$2" >/dev/null 2>&1
      }
      valid_marker() {
        [ -f "$1" ] && [ ! -L "$1" ] \
          && [ "$(/usr/bin/stat -f %Su:%Sg "$1")" = root:wheel ] \
          && [ "$(/usr/bin/stat -f %Lp "$1")" = 600 ] \
          && ${pkgs.gnugrep}/bin/grep -Fqx \
            "owner=rustdesk-self-hosted-remote-access" "$1"
      }
      stop_old_provision() {
        /bin/launchctl bootout \
          system/com.carriez.RustDesk_provision >/dev/null 2>&1 || true
        ! /bin/launchctl print \
          system/com.carriez.RustDesk_provision >/dev/null 2>&1
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
        if same_verified_bundle "$store_app" "$destination"; then
          app_replacement=0
        fi
      elif [ -e "$marker" ] || [ -L "$marker" ]; then
        echo "refusing a RustDesk marker without its managed app" >&2
        exit 1
      fi

      {
        echo "owner=rustdesk-self-hosted-remote-access"
        echo "version=${rustdeskVersion}"
        echo "source=${rustdeskDmgHash}"
        echo "revision=${rustdeskRevisionValue}"
      } > "$new_marker"
      /bin/chmod 0600 "$new_marker"
      /usr/sbin/chown root:wheel "$new_marker"

      if [ "$app_replacement" -eq 0 ] \
        && /usr/bin/cmp -s "$marker" "$new_marker"; then
        exit 0
      fi

      stop_old_provision || {
        echo "failed to unload the old RustDesk provision job" >&2
        exit 1
      }

      if [ "$app_replacement" -eq 1 ]; then
        /usr/bin/ditto "$store_app" "$staging"
        verify_app "$staging" || {
          echo "RustDesk staging bundle signature verification failed" >&2
          exit 1
        }
      fi
      /usr/bin/touch "$transaction/prepared"

      if [ -e "$transaction/had-old" ]; then
        if [ "$app_replacement" -eq 1 ]; then
          /bin/mv "$destination" "$old_app"
        fi
        /bin/mv "$marker" "$old_marker"
      fi
      if [ "$app_replacement" -eq 1 ]; then
        /bin/mv "$staging" "$destination"
        verify_app "$destination" || {
          echo "RustDesk destination bundle signature verification failed" >&2
          exit 1
        }
      else
        same_verified_bundle "$store_app" "$destination" || {
          echo "RustDesk destination bundle changed during activation" >&2
          exit 1
        }
      fi
      /bin/mv "$new_marker" "$marker"
      /bin/mkdir -m 0700 "$transaction/committed"
      commit_done=1
      )
    '';

    environment.launchDaemons."com.carriez.RustDesk_service.plist".text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0"><dict>
        <key>Label</key><string>com.carriez.RustDesk_service</string>
        <key>AssociatedBundleIdentifiers</key><string>${rustdeskBundleId}</string>
        <key>EnvironmentVariables</key><dict>
          <key>RUSTDESK_NIX_REVISION</key><string>${rustdeskRevisionValue}</string>
        </dict>
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
        <key>AssociatedBundleIdentifiers</key><string>${rustdeskBundleId}</string>
        <key>EnvironmentVariables</key><dict>
          <key>RUSTDESK_NIX_REVISION</key><string>${rustdeskRevisionValue}</string>
        </dict>
        <key>LimitLoadToSessionType</key><array>
          <string>LoginWindow</string><string>Aqua</string>
        </array>
        <key>ProgramArguments</key><array>
          <string>${rustdeskServerProgram}</string>
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
          <string>8m</string><string>${rustdeskProvision}</string>
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

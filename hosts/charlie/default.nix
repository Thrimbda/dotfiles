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
      rustdeskPublicConfig = pkgs.writeShellScript "charlie-rustdesk-public-config" ''
        set -eu
        rustdesk=/Applications/RustDesk.app/Contents/MacOS/RustDesk
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
      rustdeskRevision = pkgs.writeText "charlie-rustdesk-revision" ''
        package=${rustdeskVersion}
        source=${rustdeskDmgHash}
        public-config=${rustdeskPublicConfig}
        provision=charlie-rustdesk-provision-v1
        ciphertext=${./secrets/rustdesk-password.age}
      '';
      rustdeskProvision = pkgs.writeShellScript "charlie-rustdesk-provision" ''
        set -eu
        umask 077

        rustdesk=/Applications/RustDesk.app/Contents/MacOS/RustDesk
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

        /usr/bin/install -d -m 0700 -o root -g wheel "$state"
        if [ -f "$stamp" ] \
          && ${pkgs.diffutils}/bin/cmp -s "$stamp" ${rustdeskRevision}; then
          ${rustdeskPublicConfig} --check || fail public-config
          exit 0
        fi

        uid=$(/usr/bin/id -u c1)
        ready=0
        attempt=0
        while [ "$attempt" -lt 60 ]; do
          if [ -x "$rustdesk" ] \
            && /bin/launchctl print system/com.carriez.RustDesk_service >/dev/null 2>&1 \
            && /bin/launchctl print "gui/$uid/com.carriez.RustDesk_server" >/dev/null 2>&1 \
            && [ -S /tmp/RustDesk/ipc ] \
            && ${rustdeskPublicConfig} --check; then
            ready=1
            break
          fi
          attempt=$((attempt + 1))
          ${pkgs.coreutils}/bin/sleep 2
        done
        [ "$ready" -eq 1 ] || fail readiness
        /usr/bin/codesign --verify --deep --strict /Applications/RustDesk.app \
          >/dev/null 2>&1 || fail codesign
        /usr/sbin/spctl -a -t exec /Applications/RustDesk.app \
          >/dev/null 2>&1 || fail spctl

        if [ -f "$reservation" ] \
          && ${pkgs.diffutils}/bin/cmp -s "$reservation" ${rustdeskRevision}; then
          fail password-attempt-used-reset-required
        fi
        secret=${config.age.secrets.rustdesk-password.path}
        [ -r "$secret" ] && [ -f "$secret" ] || fail secret
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

        /bin/launchctl kickstart -k system/com.carriez.RustDesk_service
        /bin/launchctl kickstart -k "gui/$uid/com.carriez.RustDesk_server"
        attempt=0
        until [ -S /tmp/RustDesk/ipc ] && ${rustdeskPublicConfig} --check; do
          [ "$attempt" -lt 60 ] || fail restart
          attempt=$((attempt + 1))
          ${pkgs.coreutils}/bin/sleep 1
        done
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
          <string>/bin/sh</string><string>-c</string>
          <string>/Applications/RustDesk.app/Contents/MacOS/service</string>
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

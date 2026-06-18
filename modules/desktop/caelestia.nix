{ hey, lib, config, pkgs, hostSystem ? null, ... }:

with lib;
with hey.lib;
let cfg = config.modules.desktop.caelestia;
    system = if hostSystem != null then hostSystem else pkgs.stdenv.hostPlatform.system;
    isLinux = hasSuffix "-linux" system;
    themeWallpaper = config.modules.theme.wallpapers."*" or {};
    defaultWallpaperPath = themeWallpaper.path or null;
    qtPlatform = "wayland;xcb";
    qtPlatformTheme = "qtengine";
    defaultLogin1PolkitActions = [
      "org.freedesktop.login1.hibernate"
      "org.freedesktop.login1.hibernate-multiple-sessions"
      "org.freedesktop.login1.power-off"
      "org.freedesktop.login1.power-off-multiple-sessions"
      "org.freedesktop.login1.reboot"
      "org.freedesktop.login1.reboot-multiple-sessions"
      "org.freedesktop.login1.suspend"
      "org.freedesktop.login1.suspend-multiple-sessions"
    ];
    defaultNetworkManagerPolkitActions = [
      "org.freedesktop.NetworkManager.enable-disable-network"
      "org.freedesktop.NetworkManager.enable-disable-wifi"
      "org.freedesktop.NetworkManager.network-control"
      "org.freedesktop.NetworkManager.settings.modify.own"
      "org.freedesktop.NetworkManager.settings.modify.system"
      "org.freedesktop.NetworkManager.wifi.scan"
    ];
    caelestiaFontFamilies = {
      clock = "Rubik";
      material = "Material Symbols Rounded";
      mono = "CaskaydiaCove NF";
      sans = "Rubik";
    };
    defaultShellPackage =
      if isLinux
      then hey.inputs.caelestia-shell.packages.${system}.with-cli
      else pkgs.runCommand "caelestia-shell-unavailable" {} "mkdir -p $out";
    defaultCliPackage =
      if isLinux
      then hey.inputs.caelestia-shell.inputs.caelestia-cli.packages.${system}.default
      else pkgs.runCommand "caelestia-cli-unavailable" {} "mkdir -p $out";
    terminalCommand = config.modules.desktop.term.default or "foot";
    wallpaperStateDir = "${config.home.stateDir}/caelestia/wallpaper";
    wallpaperStatePath = "${wallpaperStateDir}/path.txt";
    wallpaperGeneratedPath = "${wallpaperStateDir}/generated.jpg";
    seedWallpaperScript =
      if cfg.wallpaper.path == null then null else pkgs.writeShellScript "caelestia-seed-wallpaper" ''
        set -eu
        source=${escapeShellArg cfg.wallpaper.path}
        state_dir=${escapeShellArg wallpaperStateDir}
        state_path=${escapeShellArg wallpaperStatePath}
        generated=${escapeShellArg wallpaperGeneratedPath}
        desired=

        ${pkgs.coreutils}/bin/install -d -m 0755 "$state_dir"

        if [ -f "$source" ]; then
          desired="$source"

          if [ ! -s "$generated" ] || [ "$source" -nt "$generated" ]; then
            tmp="$(${pkgs.coreutils}/bin/mktemp "$generated.XXXXXX.jpg")"
            trap '${pkgs.coreutils}/bin/rm -f "$tmp"' EXIT
            if ${pkgs.imagemagick}/bin/magick "$source" -auto-orient -resize '3840x2160>' -strip -quality 92 "$tmp"; then
              ${pkgs.coreutils}/bin/mv -f "$tmp" "$generated"
              trap - EXIT
            else
              ${pkgs.coreutils}/bin/rm -f "$tmp"
              trap - EXIT
              printf 'caelestia-seed-wallpaper: failed to generate decode-safe wallpaper from %s\n' "$source" >&2
            fi
          fi

          if [ -s "$generated" ]; then
            desired="$generated"
          fi
        fi

        current=
        if [ -s "$state_path" ]; then
          current="$(${pkgs.coreutils}/bin/cat "$state_path")"
        fi

        if [ -n "$desired" ] && { [ -z "$current" ] || [ "$current" = "$source" ]; }; then
          printf '%s\n' "$desired" > "$state_path"
        fi
      '';
    shellSettings = recursiveUpdate {
      appearance.font.family = caelestiaFontFamilies;
      background.wallpaperEnabled = cfg.wallpaper.enable;
      general.apps = {
        terminal = [ terminalCommand ];
        audio = [ "pavucontrol" ];
        playback = [ "mpv" ];
        explorer = [ "thunar" ];
      };
      launcher.enableDangerousActions = false;
      utilities.toasts.kbLayoutChanged = false;
    } cfg.settings;
    shellSettingsFile = pkgs.writeText "caelestia-shell.json" (builtins.toJSON shellSettings);
    shellConfigDir = "${config.home.configDir}/caelestia";
    shellConfigPath = "${shellConfigDir}/shell.json";
    seedShellConfigScript = pkgs.writeShellScript "caelestia-seed-shell-config" ''
      set -eu
      config_dir=${escapeShellArg shellConfigDir}
      config_path=${escapeShellArg shellConfigPath}
      seed=${escapeShellArg "${shellSettingsFile}"}

      ${pkgs.coreutils}/bin/install -d -m 0755 "$config_dir"

      replace_shell_config=false
      if [ ! -e "$config_path" ] && [ ! -L "$config_path" ]; then
        replace_shell_config=true
      elif [ -L "$config_path" ]; then
        target="$(${pkgs.coreutils}/bin/readlink "$config_path")"
        case "$target" in
          /nix/store/*) replace_shell_config=true ;;
        esac
      fi

      if [ "$replace_shell_config" = true ]; then
        tmp="$(${pkgs.coreutils}/bin/mktemp "$config_path.XXXXXX")"
        trap '${pkgs.coreutils}/bin/rm -f "$tmp"' EXIT
        ${pkgs.coreutils}/bin/install -m 0644 "$seed" "$tmp"
        ${pkgs.coreutils}/bin/mv -f "$tmp" "$config_path"
        trap - EXIT
      fi
    '';
    packageDataDirs = makeSearchPath "share" (
      unique (config.users.users.${config.user.name}.packages
        ++ config.environment.systemPackages)
    );
    sessionXdgDataDirs = if cfg.session.includePackageDataDirs then packageDataDirs else cfg.session.xdgDataDirs;
    mutableSettingsFile = pkgs.writeText "caelestia-mutable-settings.json" (builtins.toJSON cfg.mutableConfig.settings);
    mutableFavouriteAppsFile = pkgs.writeText "caelestia-mutable-favourite-apps.json" (builtins.toJSON cfg.mutableConfig.launcher.favouriteApps);
    mutableRemoveFavouriteAppsFile = pkgs.writeText "caelestia-mutable-remove-favourite-apps.json" (builtins.toJSON cfg.mutableConfig.launcher.removeFavouriteApps);
    localControlPolkitUser = if cfg.localControls.polkit.user != "" then cfg.localControls.polkit.user else config.user.name;
    localControlPolkitActions = unique (cfg.localControls.polkit.login1Actions ++ cfg.localControls.polkit.networkManagerActions);
    patchMutableConfigScript = pkgs.writeShellScript "caelestia-patch-mutable-config" ''
      set -eu

      config_dir=${escapeShellArg shellConfigDir}
      config_path=${escapeShellArg shellConfigPath}
      settings_file=${escapeShellArg "${mutableSettingsFile}"}
      favourites_file=${escapeShellArg "${mutableFavouriteAppsFile}"}
      remove_file=${escapeShellArg "${mutableRemoveFavouriteAppsFile}"}

      ${pkgs.coreutils}/bin/install -d -m 0755 "$config_dir"
      if [ ! -s "$config_path" ]; then
        printf '{}\n' > "$config_path"
      fi

      settings_json="$(${pkgs.coreutils}/bin/cat "$settings_file")"
      favourites_json="$(${pkgs.coreutils}/bin/cat "$favourites_file")"
      remove_json="$(${pkgs.coreutils}/bin/cat "$remove_file")"

      tmp="$(${pkgs.coreutils}/bin/mktemp "$config_path.XXXXXX")"
      trap '${pkgs.coreutils}/bin/rm -f "$tmp"' EXIT

      if ! ${pkgs.jq}/bin/jq \
          --argjson settings "$settings_json" \
          --argjson favourites "$favourites_json" \
          --argjson remove "$remove_json" '
        def deepmerge($a; $b):
          reduce ($b | keys_unsorted[]) as $key ($a;
            .[$key] = if (($a[$key] | type) == "object" and ($b[$key] | type) == "object")
              then deepmerge($a[$key]; $b[$key])
              else $b[$key]
              end);

        deepmerge(. // {}; $settings)
        | .launcher = (.launcher // {})
        | .launcher.favouriteApps = ((.launcher.favouriteApps // []) as $apps
            | ($apps | map(select(. as $candidate | ($remove | index($candidate) | not)))) as $normalized
            | reduce $favourites[] as $app ($normalized; if index($app) then . else . + [$app] end))
      ' "$config_path" > "$tmp"; then
        printf 'caelestia-patch-mutable-config: unable to update %s\n' "$config_path" >&2
        exit 0
      fi

      if ! ${pkgs.diffutils}/bin/cmp -s "$tmp" "$config_path"; then
        ${pkgs.coreutils}/bin/install -m 0644 "$tmp" "$config_path"
      fi
    '';
    caelestiaSessionPath = makeBinPath ([
      cfg.cliPackage
      pkgs.unstable.app2unit
      pkgs.util-linux
    ] ++ cfg.session.extraPath
      ++ config.users.users.${config.user.name}.packages
      ++ config.environment.systemPackages);
    caelestiaPreStartCommands = concatStringsSep "\n" ([
      "${seedShellConfigScript}"
    ] ++ optional cfg.mutableConfig.enable "${patchMutableConfigScript}"
      ++ optional (cfg.wallpaper.enable && cfg.wallpaper.path != null) "${seedWallpaperScript}"
      ++ cfg.session.preStart);
    caelestiaSessionControl = pkgs.writeShellScriptBin "caelestia-session" ''
      set -euo pipefail

      runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
      runner_pid_file="$runtime_dir/caelestia-session-runner.pid"
      stop_file="$runtime_dir/caelestia-session.stop"
      shell_config=${escapeShellArg "${cfg.package}/share/caelestia-shell/shell.qml"}

      require_session() {
        if [ -z "''${WAYLAND_DISPLAY:-}" ] || [ -z "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
          printf 'caelestia-session: refusing to start outside the Hyprland session\n' >&2
          exit 1
        fi
      }

      session_env() {
        while IFS= read -r entry; do
          case "$entry" in
            DISPLAY=*|WAYLAND_DISPLAY=*|XAUTHORITY=*|XDG_CURRENT_DESKTOP=*|XDG_SESSION_DESKTOP=*|XDG_SESSION_TYPE=*|HYPRLAND_INSTANCE_SIGNATURE=*)
              name="''${entry%%=*}"
              if [ -z "''${!name:-}" ]; then
                export "$entry"
              fi
              ;;
          esac
        done < <(${pkgs.systemd}/bin/systemctl --user show-environment 2>/dev/null || true)

        if [ -n "''${PATH:-}" ]; then
          export PATH=${escapeShellArg caelestiaSessionPath}:$PATH
        else
          export PATH=${escapeShellArg caelestiaSessionPath}
        fi

        ${optionalString (sessionXdgDataDirs != "") ''
          if [ -n "''${XDG_DATA_DIRS:-}" ]; then
            export XDG_DATA_DIRS=${escapeShellArg sessionXdgDataDirs}:$XDG_DATA_DIRS
          else
            export XDG_DATA_DIRS=${escapeShellArg sessionXdgDataDirs}
          fi
        ''}

        export QT_QPA_PLATFORM=${escapeShellArg qtPlatform}
        export QT_QPA_PLATFORMTHEME=${escapeShellArg qtPlatformTheme}
        export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
        export QT_AUTO_SCREEN_SCALE_FACTOR=1
      }

      instance_pid() {
        (${cfg.package}/bin/caelestia-shell list --all 2>/dev/null || true) \
          | ${pkgs.gawk}/bin/awk -v config="$shell_config" '
              /^Instance / { pid = "" }
              /Process ID:/ { pid = $3 }
              $0 == "  Config path: " config { print pid; exit }
            '
      }

      pid_alive() {
        [ -n "''${1:-}" ] && ${pkgs.procps}/bin/kill -0 "$1" 2>/dev/null
      }

      runner_pid() {
        if [ -s "$runner_pid_file" ]; then
          ${pkgs.coreutils}/bin/cat "$runner_pid_file"
        fi
        return 0
      }

      runner_alive() {
        pid_alive "$(runner_pid)"
      }

      session_owned() {
        pid="$1"
        [ -r "/proc/$pid/cgroup" ] || return 1
        case "$(${pkgs.coreutils}/bin/cat "/proc/$pid/cgroup")" in
          *'/session-'*'.scope'*) return 0 ;;
          *) return 1 ;;
        esac
      }

      run_prestart() {
        ${caelestiaPreStartCommands}
      }

      run() {
        require_session
        session_env
        ${pkgs.coreutils}/bin/install -d -m 0700 "$runtime_dir"
        printf '%s\n' "$$" > "$runner_pid_file"
        trap '${pkgs.coreutils}/bin/rm -f "$runner_pid_file" "$stop_file"' EXIT

        while [ ! -e "$stop_file" ]; do
          set +e
          ${cfg.package}/bin/caelestia-shell --no-duplicate
          status=$?
          set -e
          [ -e "$stop_file" ] && break
          [ "$status" -eq 0 ] && break
          ${pkgs.coreutils}/bin/sleep 5
        done
      }

      start() {
        require_session
        session_env
        ${pkgs.coreutils}/bin/install -d -m 0700 "$runtime_dir"
        ${pkgs.coreutils}/bin/rm -f "$stop_file"

        if runner_alive; then
          exit 0
        fi

        pid="$(instance_pid)"
        if [ -n "$pid" ]; then
          if session_owned "$pid"; then
            printf 'caelestia-session: restarting unmanaged session shell pid %s\n' "$pid" >&2
          else
            printf 'caelestia-session: migrating non-session-owned shell pid %s\n' "$pid" >&2
          fi
          stop
        fi

        run_prestart
        ${pkgs.coreutils}/bin/nohup "$0" run >/dev/null 2>&1 &
      }

      stop() {
        ${pkgs.coreutils}/bin/install -d -m 0700 "$runtime_dir"
        : > "$stop_file"
        ${cfg.package}/bin/caelestia-shell kill --any-display >/dev/null 2>&1 || true

        pid="$(runner_pid)"
        if pid_alive "$pid"; then
          for _ in $(${pkgs.coreutils}/bin/seq 1 50); do
            pid_alive "$pid" || break
            ${pkgs.coreutils}/bin/sleep 0.1
          done
          pid_alive "$pid" && ${pkgs.procps}/bin/kill "$pid" 2>/dev/null || true
        fi

        ${pkgs.coreutils}/bin/rm -f "$runner_pid_file" "$stop_file"
      }

      case "''${1:-start}" in
        start) start ;;
        stop) stop ;;
        restart) stop; start ;;
        status) ${cfg.package}/bin/caelestia-shell list --all ;;
        run) run ;;
        *)
          printf 'usage: caelestia-session {start|stop|restart|status}\n' >&2
          exit 64
          ;;
      esac
    '';
in {
  imports = optional isLinux hey.inputs.qtengine.nixosModules.default;

  options.modules.desktop.caelestia = with types; {
    enable = mkBoolOpt false;
    package = mkOpt package defaultShellPackage;
    cliPackage = mkOpt package defaultCliPackage;
    settings = mkOpt attrs {};
    cli.settings = mkOpt attrs {};
    session = {
      extraPath = mkOpt (listOf (oneOf [ package str ])) [];
      preStart = mkOpt (listOf str) [];
      xdgDataDirs = mkOpt str "";
      includePackageDataDirs = mkBoolOpt false;
      controlCommand = mkOpt str "";
    };
    mutableConfig = {
      enable = mkBoolOpt false;
      settings = mkOpt attrs {};
      launcher = {
        favouriteApps = mkOpt (listOf str) [];
        removeFavouriteApps = mkOpt (listOf str) [];
      };
    };
    localControls.polkit = {
      enable = mkBoolOpt false;
      user = mkOpt str "";
      login1Actions = mkOpt (listOf str) defaultLogin1PolkitActions;
      networkManagerActions = mkOpt (listOf str) defaultNetworkManagerPolkitActions;
    };
    wallpaper = {
      enable = mkBoolOpt false;
      path = mkOpt (nullOr str) defaultWallpaperPath;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [{
        assertion = isLinux;
        message = "Caelestia shell is Linux-only and must not be enabled on Darwin.";
      }];
    }

    (mkIf isLinux {
      programs.qtengine = {
        enable = true;
        config = {
          theme = {
            colorScheme = "${pkgs.kdePackages.breeze}/share/color-schemes/BreezeDark.colors";
            iconTheme = config.modules.theme.gtk.iconTheme.name;
            style = "breeze";
            font = {
              family = config.modules.theme.fonts.sans.name;
              size = 12;
              weight = -1;
            };
            fontFixed = {
              family = config.modules.theme.fonts.mono.name;
              size = 12;
              weight = -1;
            };
          };
          misc = {
            menusHaveIcons = true;
            singleClickActivate = false;
            shortcutsForContextMenus = true;
          };
        };
      };

      environment.systemPackages = with pkgs.kdePackages; [
        breeze
        breeze.qt5
        breeze-icons
      ];

      user.packages = with pkgs; [
        cfg.package
        cfg.cliPackage

        hicolor-icon-theme
        adwaita-icon-theme
        papirus-icon-theme
        shared-mime-info
        xdg-utils
      ];

      fonts.packages = with pkgs; [
        material-symbols
        rubik
        nerd-fonts.caskaydia-cove
      ];

      modules.desktop.caelestia.session.controlCommand = "${caelestiaSessionControl}/bin/caelestia-session";

      security.polkit.extraConfig = mkIf cfg.localControls.polkit.enable ''
        polkit.addRule(function(action, subject) {
          var actions = ${builtins.toJSON localControlPolkitActions};
          if (subject.local == true && subject.user == "${localControlPolkitUser}"
              && actions.indexOf(action.id) >= 0) {
            return polkit.Result.YES;
          }
        });
      '';

      hey.hooks.startup."06-caelestia-shell" = ''
        hey.do ${caelestiaSessionControl}/bin/caelestia-session start
      '';

      home.configFile = optionalAttrs (cfg.cli.settings != {}) {
        "caelestia/cli.json".text = builtins.toJSON cfg.cli.settings;
      };

      hey.hooks.reload."94-caelestia-shell" = ''
        hey.do ${caelestiaSessionControl}/bin/caelestia-session restart
      '';
    })
  ]);
}

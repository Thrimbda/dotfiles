## modules/desktop/hyprland.nix
#
# Sets up a hyprland-based desktop environment.
#
# TODO: Investigate bluetuith for bluetooth TUI

{ hey, heyBin, lib, options, config, pkgs, ... }:

with lib;
with hey.lib;
let inherit (hey.lib.pkgs.for pkgs) mkLauncherEntry;
    cfg = config.modules.desktop.hyprland;
    caelestiaCfg = config.modules.desktop.caelestia;
    terminalCommand = config.modules.desktop.term.default;
    tmuxTerminalCommand = "${terminalCommand} -e tmux new-session -A -s main";
    browserCommand =
      if config.modules.desktop.browsers.default != null
      then config.modules.desktop.browsers.default
      else "xdg-open";
    editorCommand = config.modules.editors.default;
    zenWmClass = config.modules.desktop.browsers.zen.wmClass;
    primaryMonitor = findFirst (x: x.primary) {} cfg.monitors;
    primaryMonitorName = primaryMonitor.output or "";
    secondaryMonitor =
      if cfg.workspaces.secondary.enable && primaryMonitorName != ""
      then findFirst (x: !(x.primary or false) && !(x.disable or false) && (x.output or "") != "") {} cfg.monitors
      else {};
    secondaryMonitorName = secondaryMonitor.output or "";
    xkbLayout = config.services.xserver.xkb.layout;
    xkbVariant = config.services.xserver.xkb.variant;
    xkbOptions = config.services.xserver.xkb.options;
    caelestiaCli = "${caelestiaCfg.cliPackage}/bin/caelestia";
    caelestiaLockCommand = "${caelestiaCli} shell lock lock";
    caelestiaSession =
      if caelestiaCfg.enable && caelestiaCfg.session.controlCommand != ""
      then caelestiaCfg.session.controlCommand
      else "${pkgs.coreutils}/bin/true";
    caelestiaOwnsWallpaper = caelestiaCfg.enable && caelestiaCfg.wallpaper.enable;
    hasScaledMonitor = any (monitor: (monitor.scale or 1) != 1) cfg.monitors;
    hasAdvancedMonitorFields = monitor:
      monitor.bitdepth != null
      || monitor.cm != null
      || monitor.sdrbrightness != null
      || monitor.sdrsaturation != null;
    monitorEffectiveMode = monitor:
      if monitor.modePolicy == "native-max-refresh" && monitor.fallbackMode != null
      then monitor.fallbackMode
      else monitor.mode;
    monitorFields = monitor: [
      "    output = \"${monitor.output}\""
      "    mode = \"${monitorEffectiveMode monitor}\""
      "    position = \"${monitor.position}\""
      "    scale = ${toString monitor.scale}"
    ]
      ++ optional (monitor.bitdepth != null) "    bitdepth = ${toString monitor.bitdepth}"
      ++ optional (monitor.cm != null) "    cm = \"${monitor.cm}\""
      ++ optional (monitor.sdrbrightness != null) "    sdrbrightness = ${toString monitor.sdrbrightness}"
      ++ optional (monitor.sdrsaturation != null) "    sdrsaturation = ${toString monitor.sdrsaturation}";
    monitorLine = monitor:
      if monitor.disable
      then "  hl.monitor({ output = \"${monitor.output}\", disabled = true })"
      else if hasAdvancedMonitorFields monitor
      then concatStringsSep "\n" ([ "  hl.monitor({" ] ++ monitorFields monitor ++ [ "  })" ])
      else "  hl.monitor({ output = \"${monitor.output}\", mode = \"${monitorEffectiveMode monitor}\", position = \"${monitor.position}\", scale = ${toString monitor.scale} })";
    monitorInventory = {
      known = map (monitor: {
        inherit (monitor) output position scale disable modePolicy;
        mode = monitorEffectiveMode monitor;
        fallbackMode = if monitor.fallbackMode != null then monitor.fallbackMode else monitor.mode;
        match = filterAttrs (_: value: value != null && value != "") monitor.match;
      }) cfg.monitors;
      unknown = cfg.monitorHotplug.unknown;
    };
    monitorInventoryFile = pkgs.writeText "hypr-monitor-inventory.json" (builtins.toJSON monitorInventory);
    monitorReconcilePackage = pkgs.writeShellScriptBin "hyprland-reconcile-monitors" ''
      set -eu

      inventory=${escapeShellArg "${monitorInventoryFile}"}
      hyprctl=${escapeShellArg "${config.programs.hyprland.package}/bin/hyprctl"}
      jq=${escapeShellArg "${pkgs.jq}/bin/jq"}

      live="$($hyprctl monitors all -j)"
      commands="$($jq -r --slurpfile inventory "$inventory" '
        def abs: if . < 0 then -. else . end;
        def parseMode($mode):
          (($mode // "") | capture("^(?<w>[0-9]+)x(?<h>[0-9]+)@(?<r>[0-9.]+)(Hz)?$")?) as $parsed
          | if $parsed == null then null else {
              w: ($parsed.w | tonumber),
              h: ($parsed.h | tonumber),
              r: ($parsed.r | tonumber)
            } end;
        def modeText($mode): "\($mode.w)x\($mode.h)@\($mode.r)";
        def modes($output): [ $output.availableModes[]? | parseMode(.) | select(. != null) ];
        def dynamicMode($output):
          (modes($output)) as $modes
          | if ($modes | length) == 0 then null else
              ($modes[0]) as $native
              | ($modes | map(select(.w == $native.w and .h == $native.h)) | max_by(.r) | modeText(.))
            end;
        def identityFieldMatches($monitor; $output; $field):
          (($monitor.match[$field] // "") == "") or (($output[$field] // "") == $monitor.match[$field]);
        def hasIdentity($monitor):
          ["make", "model", "serial", "description"] | any(($monitor.match[.] // "") != "");
        def identityMatches($monitor; $output):
          hasIdentity($monitor)
          and (["make", "model", "serial", "description"] | all(identityFieldMatches($monitor; $output; .)));
        def outputMatches($monitor; $output):
          (($monitor.output // "") != "") and ($monitor.output == $output.name);
        def knownConfig($inventory; $output):
          ([ $inventory.known[] | select((.disable // false) | not) | select(identityMatches(.; $output)) ][0]
           // [ $inventory.known[] | select((.disable // false) | not) | select(outputMatches(.; $output)) ][0]);
        def unknownConfig($inventory; $output):
          if ($inventory.unknown.enable // false) then {
            output: $output.name,
            position: ($inventory.unknown.position // "auto"),
            scale: ($inventory.unknown.scale // 1),
            modePolicy: ($inventory.unknown.modePolicy // "native-max-refresh"),
            fallbackMode: ($inventory.unknown.fallbackMode // null)
          } else null end;
        def targetMode($output; $config):
          if ($config.modePolicy // "static") == "native-max-refresh" then
            dynamicMode($output) // $config.fallbackMode // $config.mode
          else
            $config.mode // $config.fallbackMode
          end;
        def needsApply($output; $mode; $position; $scale):
          (parseMode($mode)) as $target
          | if $target == null then true else
              ($output.width != $target.w)
              or ($output.height != $target.h)
              or ((($output.refreshRate // 0) - $target.r) | abs > 0.2)
              or (($position != "auto") and ((($output.x | tostring) + "x" + ($output.y | tostring)) != $position))
              or (((($output.scale // 1) - ($scale | tonumber)) | abs) > 0.001)
            end;

        ($inventory[0]) as $inventory
        | .[]
        | select((.disabled // false) | not)
        | select((.availableModes // []) | length > 0)
        | . as $output
        | (knownConfig($inventory; $output) // unknownConfig($inventory; $output)) as $config
        | select($config != null)
        | (targetMode($output; $config)) as $mode
        | select($mode != null)
        | select(needsApply($output; $mode; $config.position; $config.scale))
        | "hl.monitor({ output = \($output.name | @json), mode = \($mode | @json), position = \($config.position | @json), scale = \($config.scale | tonumber) })"
      ' <<EOF
      $live
      EOF
      )"

      [ -n "$commands" ] || exit 0

      status=0
      while IFS= read -r command; do
        [ -n "$command" ] || continue
        if ! "$hyprctl" eval "$command"; then
          status=1
        fi
      done <<EOF
      $commands
      EOF
      exit "$status"
    '';
    monitorHotplugWatcher = pkgs.writeShellScript "hyprland-monitor-hotplug" ''
      set -euo pipefail

      reconcile=${escapeShellArg "${monitorReconcilePackage}/bin/hyprland-reconcile-monitors"}
      hyprctl=${escapeShellArg "${config.programs.hyprland.package}/bin/hyprctl"}
      jq=${escapeShellArg "${pkgs.jq}/bin/jq"}
      runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
      debounce_file="$runtime_dir/hyprland-monitor-hotplug.debounce"

      current_socket() {
        instance="$("$hyprctl" instances -j 2>/dev/null | "$jq" -r --arg wayland_display "''${WAYLAND_DISPLAY:-}" '
          . as $instances
          | [ .[] | select($wayland_display == "" or .wl_socket == $wayland_display) ] as $matching
          | if ($matching | length) > 0 then $matching else $instances end
          | if length == 0 then empty else max_by(.time).instance end
        ' 2>/dev/null || true)"
        [ -n "$instance" ] || return 1

        socket="$runtime_dir/hypr/$instance/.socket2.sock"
        [ -S "$socket" ] || return 1
        printf '%s\n' "$socket"
      }

      schedule_reconcile() {
        [ ! -e "$debounce_file" ] || return 0
        : > "$debounce_file"
        (
          ${pkgs.coreutils}/bin/sleep ${toString cfg.monitorHotplug.debounceSeconds}
          ${pkgs.coreutils}/bin/rm -f "$debounce_file"
          "$reconcile" || true
        ) &
      }

      while true; do
        socket="$(current_socket || true)"
        if [ -z "$socket" ]; then
          ${pkgs.coreutils}/bin/sleep 2
          continue
        fi

        if ${pkgs.socat}/bin/socat -u UNIX-CONNECT:"$socket" - 2>/dev/null | while IFS= read -r event; do
          case "$event" in
            monitor*|configreloaded*) schedule_reconcile ;;
          esac
        done; then
          :
        fi
        # A compositor restart invalidates socket2; rediscover it after a bounded delay.
        ${pkgs.coreutils}/bin/sleep 2
      done
    '';
    caelestiaMonitorSeeds = filter (entry: entry.settings != {} && entry.output != "") (map (monitor: {
      inherit (monitor) output;
      settings = monitor.caelestia.settings;
    }) cfg.monitors);
    caelestiaMonitorSeedsFile = pkgs.writeText "caelestia-monitor-settings.json" (builtins.toJSON caelestiaMonitorSeeds);
    caelestiaMonitorSeedScript = pkgs.writeShellScript "caelestia-seed-monitor-settings" ''
      set -eu

      config_dir=${escapeShellArg "${config.home.configDir}/caelestia"}
      seed=${escapeShellArg "${caelestiaMonitorSeedsFile}"}
      jq=${escapeShellArg "${pkgs.jq}/bin/jq"}

      $jq -c '.[]' "$seed" | while IFS= read -r entry; do
        output="$(printf '%s\n' "$entry" | $jq -r '.output')"
        monitor_dir="$config_dir/monitors/$output"
        config_path="$monitor_dir/shell.json"

        ${pkgs.coreutils}/bin/install -d -m 0755 "$monitor_dir"

        replace_monitor_config=false
        if [ ! -e "$config_path" ] && [ ! -L "$config_path" ]; then
          replace_monitor_config=true
        elif [ -L "$config_path" ]; then
          target="$(${pkgs.coreutils}/bin/readlink "$config_path")"
          case "$target" in
            /nix/store/*) replace_monitor_config=true ;;
          esac
        fi

        if [ "$replace_monitor_config" = true ]; then
          tmp="$(${pkgs.coreutils}/bin/mktemp "$config_path.XXXXXX")"
          trap '${pkgs.coreutils}/bin/rm -f "$tmp"' EXIT
          printf '%s\n' "$entry" | $jq '.settings' > "$tmp"
          ${pkgs.coreutils}/bin/install -m 0644 "$tmp" "$config_path"
          ${pkgs.coreutils}/bin/rm -f "$tmp"
          trap - EXIT
        fi
      done
    '';
    qtPlatform = "wayland;xcb";
    qtPlatformTheme = "qtengine";
    desktopSessionPath = concatStringsSep ":" [
      config.home.binDir
      "${config.home.dir}/.opencode/bin"
      "/etc/profiles/per-user/${config.user.name}/bin"
      "/run/wrappers/bin"
      "/run/current-system/sw/bin"
      "/nix/var/nix/profiles/default/bin"
    ];
    swaybgWallpaperHook = ''
      ${pkgs.procps}/bin/pkill -x swaybg || true
      ${concatStringsSep "\n"
        (mapAttrsToList
          (output: w: ''
            local wallpaper="${w.path}"
            if [[ -f "$wallpaper" ]]; then
              hey.do swaybg \
                     -o "${output}" \
                     -i "$wallpaper" \
                     -m ${w.mode or "center"} &
            fi
          '')
          config.modules.theme.wallpapers)}
      pgrep -x swaybg >/dev/null && sleep 0.5
    '';
    workspaceKeys = [
      { key = "1"; primary = 1; secondary = 11; }
      { key = "2"; primary = 2; secondary = 12; }
      { key = "3"; primary = 3; secondary = 13; }
      { key = "4"; primary = 4; secondary = 14; }
      { key = "5"; primary = 5; secondary = 15; }
      { key = "6"; primary = 6; secondary = 16; }
      { key = "7"; primary = 7; secondary = 17; }
      { key = "8"; primary = 8; secondary = 18; }
      { key = "9"; primary = 9; secondary = 19; }
      { key = "0"; primary = 10; secondary = 20; }
    ];
    primaryWorkspaceLines = concatStringsSep "\n" (map
      (n:
        let suffix = optionalString (n == 1) ", default = true, persistent = true";
            monitorPart = optionalString (primaryMonitorName != "") ", monitor = \"${primaryMonitorName}\"";
        in "  hl.workspace_rule({ workspace = \"${toString n}\"${monitorPart}${suffix} })")
      (range 1 10));
    secondaryWorkspaceLines = optionalString (secondaryMonitorName != "") (concatStringsSep "\n" (map
      (n:
        let suffix = optionalString (n == 11) ", default = true, persistent = true";
        in "  hl.workspace_rule({ workspace = \"${toString n}\", monitor = \"${secondaryMonitorName}\"${suffix} })")
      (range 11 20)));
    workspaceLines = concatStringsSep "\n" (filter (line: line != "") [
      primaryWorkspaceLines
      secondaryWorkspaceLines
    ]);
    workspaceKeybindLines = concatStringsSep "\n" (
      (map (entry: "hl.bind(\"SUPER + ${entry.key}\", hl.dsp.focus({ workspace = ${toString entry.primary} }))") workspaceKeys)
      ++ (map (entry: "hl.bind(\"SUPER + SHIFT + ${entry.key}\", hl.dsp.window.move({ workspace = ${toString entry.primary} }))") workspaceKeys)
      ++ optionals (secondaryMonitorName != "") (
        (map (entry: "hl.bind(\"SUPER + ALT + ${entry.key}\", hl.dsp.focus({ workspace = ${toString entry.secondary} }))") workspaceKeys)
        ++ (map (entry: "hl.bind(\"SUPER + ALT + SHIFT + ${entry.key}\", hl.dsp.window.move({ workspace = ${toString entry.secondary} }))") workspaceKeys)
      )
    );
    keybindingHelpText = ''
      Axiom keyboard shortcuts

      Shell
        SUPER+/                 Show this shortcut reference
        SUPER+Space             Toggle launcher
        SUPER+A                 Toggle sidebar
        CTRL+ALT+Delete         Toggle session drawer
        SUPER+SHIFT+L           Lock with Caelestia WlSessionLock

      Caelestia shell
        CTRL+SUPER+SHIFT+R      Stop session shell
        CTRL+SUPER+ALT+R        Restart session shell

      Apps and windows
        SUPER+SHIFT+Return      Open tmux terminal
        SUPER+B                 Open browser
        SUPER+E                 Open file manager
        SUPER+Q                 Close active window
        SUPER+F                 Toggle fullscreen
        SUPER+Left mouse drag   Move window
        SUPER+Right mouse drag  Resize window
        SUPER+SHIFT+C           Pick color at cursor

      Capture and clipboard
        Print                   Screenshot
        SUPER+SHIFT+S           Screenshot freeze picker
        SUPER+SHIFT+ALT+S       Screenshot picker
        SUPER+ALT+R             Start region recording
        CTRL+ALT+R              Start recording
        SUPER+SHIFT+ALT+R       Stop recording
        SUPER+V                 Open clipboard
        SUPER+Period            Open emoji picker

      Workspaces
        SUPER+1..9,0            Switch to workspace 1..10
        SUPER+SHIFT+1..9,0      Move window to workspace 1..10
        ${optionalString (secondaryMonitorName != "") "SUPER+ALT+1..9,0        Switch to workspace 11..20\n  SUPER+ALT+SHIFT+1..9,0  Move window to workspace 11..20"}
        SUPER+SHIFT+Wheel down  Move window to next workspace
        SUPER+SHIFT+Wheel up    Move window to previous workspace

      Media and brightness
        XF86MonBrightnessUp     Increase brightness 10%
        XF86MonBrightnessDown   Decrease brightness 10%
        XF86AudioPlay/Pause     Play or pause media
        XF86AudioNext           Next media item
        XF86AudioPrev           Previous media item
        XF86AudioStop           Stop media

      System
        SUPER+SHIFT+R           Reload managed desktop config
    '';
    keybindingHelpFile = pkgs.writeText "axiom-keybindings.txt" keybindingHelpText;
    keybindingHelpScript = pkgs.writeShellScript "axiom-keybinding-help" ''
      ${pkgs.zenity}/bin/zenity \
        --text-info \
        --modal \
        --title "Axiom keyboard shortcuts" \
        --width 760 \
        --height 720 \
        --filename ${escapeShellArg "${keybindingHelpFile}"}
    '';
in {
  options.modules.desktop.hyprland = with types; {
    enable = mkBoolOpt false;
    # Extra Lua configuration appended to hypr/custom/general.lua.
    extraConfig = mkOpt lines "";
    monitors = mkOpt (listOf (submodule {
      options = {
        output = mkOpt str "";
        mode = mkOpt str "preferred";
        modePolicy = mkOpt (enum [ "static" "native-max-refresh" ]) "static";
        fallbackMode = mkOpt (nullOr str) null;
        position = mkOpt str "auto";
        scale = mkOpt (oneOf [ int float ]) 1;
        match = {
          make = mkOpt (nullOr str) null;
          model = mkOpt (nullOr str) null;
          serial = mkOpt (nullOr str) null;
          description = mkOpt (nullOr str) null;
        };
        caelestia.settings = mkOpt attrs {};
        bitdepth = mkOpt (nullOr int) null;
        cm = mkOpt (nullOr (enum [
          "auto"
          "srgb"
          "dcip3"
          "dp3"
          "adobe"
          "wide"
          "edid"
          "hdr"
          "hdredid"
        ])) null;
        sdrbrightness = mkOpt (nullOr (oneOf [ int float ])) null;
        sdrsaturation = mkOpt (nullOr (oneOf [ int float ])) null;
        disable = mkOpt bool false;
        primary = mkOpt bool false;
      };
    })) [{}];
    monitorHotplug = {
      enable = mkBoolOpt false;
      debounceSeconds = mkOpt (oneOf [ int float ]) 0.75;
      unknown = {
        enable = mkBoolOpt false;
        modePolicy = mkOpt (enum [ "static" "native-max-refresh" ]) "native-max-refresh";
        fallbackMode = mkOpt (nullOr str) null;
        position = mkOpt str "auto";
        scale = mkOpt (oneOf [ int float ]) 1;
      };
    };
    hypridle.enable = mkBoolOpt true;
    workspaces.secondary.enable = mkBoolOpt false;
    idle = {
      time = mkOpt int 600;       # 10 min
      autodpms = mkOpt int 1200;   # 20 min
      autolock = mkOpt int 2400;  # 40 min
      autosleep = mkOpt int 0;
    };
  };

  config = mkIf cfg.enable {
    modules.desktop.type = "wayland";

    environment.sessionVariables = {
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
    } // optionalAttrs caelestiaCfg.enable {
      QT_QPA_PLATFORM = qtPlatform;
      QT_QPA_PLATFORMTHEME = qtPlatformTheme;
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    };

    # Hyprland's aquamarine requires newer MESA drivers.
    hardware.graphics = {
      package = pkgs.unstable.mesa;
      package32 = pkgs.unstable.pkgsi686Linux.mesa;
    };

    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      withUWSM = true;
      systemd.setPath.enable = true;
      package = pkgs.unstable.hyprland;
      portalPackage = pkgs.unstable.xdg-desktop-portal-hyprland;

      # package = hey.inputs.hyprland.packages.${final.system}.hyprland;
      # portalPackage = hey.inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    };

    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      # Avoid duplicate portal user units from merged module defaults.
      extraPortals = mkForce (with pkgs.unstable; [
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
      ]);
      config.common.default = [ "hyprland" "gtk" ];
    };

    services.dbus.enable = true;

    modules.desktop.caelestia.enable = mkDefault true;

    modules.services = {
      # REVIEW: Get rid of this when wtype adds mouse support (atx/wtype#24).
      ydotool.enable = true;
    };

    environment.systemPackages = with pkgs.unstable; [
      hypridle       # idle management for the Hyprland session
      hyprsunset     # night light/gamma integration
      hyprpicker     # screen-space color picker
      hyprshade      # to apply shaders to the screen
      hyprshot       # instead of grim(shot) or maim/slurp

      ## For Hyprland
      swaybg         # feh (as a wallpaper manager)
      xrandr         # for XWayland windows
      grim
      slurp
      wf-recorder
      wl-clipboard
      swappy
      app2unit
      cliphist
      playerctl

      ## For CLIs
      gromit-mpx     # for drawing on the screen
      pamixer        # for volume control
      wlr-randr      # for monitors that hyprctl can't handle
      ## Waiting for NixOS/nixpkgs@7249e6c56141 to reach nixos-unstable
      # wf-recorder    # for screencasting
    ];

    systemd.user.targets.hyprland-session = {
      unitConfig = {
        Description = "Hyprland compositor session";
        Documentation = [ "man:systemd.special(7)" ];
        BindsTo = [ "graphical-session.target" ];
        Wants = [ "graphical-session-pre.target" ];
        After = [ "graphical-session-pre.target" ];
      };
    };

    systemd.user.services.hypridle = mkIf cfg.hypridle.enable {
      description = "Hyprland idle daemon";
      wantedBy = [ "hyprland-session.target" ];
      after = [ "hyprland-session.target" ];
      partOf = [ "hyprland-session.target" ];
      path = [
        config.programs.hyprland.package
        caelestiaCfg.cliPackage
        caelestiaCfg.package
      ];
      serviceConfig = {
        ExecStart = "${pkgs.unstable.hypridle}/bin/hypridle";
        Restart = "on-failure";
        RestartSec = 2;
      };
    };

    systemd.user.services.hyprland-monitor-hotplug = mkIf cfg.monitorHotplug.enable {
      description = "Hyprland monitor hotplug reconciler";
      wantedBy = [ "hyprland-session.target" ];
      after = [ "hyprland-session.target" ];
      partOf = [ "hyprland-session.target" ];
      serviceConfig = {
        ExecStart = "${monitorHotplugWatcher}";
        Restart = "on-failure";
        RestartSec = 2;
      };
    };

    ## Session entry.
    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "${config.programs.uwsm.package}/bin/uwsm start -eD Hyprland ${config.programs.hyprland.package}/bin/start-hyprland";
        user = config.user.name;
      };
    };
    environment.etc."greetd/environments".text = "Hyprland";

    hey = {
      info.hypr = {
        primaryMonitor = primaryMonitor.output or null;
        monitors = cfg.monitors;
      };
      hooks = {
        # UWSM starts Hyprland; this hook connects product shell services to the
        # live compositor session before visual shell/wallpaper hooks run.
        startup."05-session" = ''
          hey.do systemctl --user import-environment \
                 DISPLAY WAYLAND_DISPLAY \
                 PATH \
                 XDG_CURRENT_DESKTOP \
                 ${optionalString caelestiaCfg.enable "QT_QPA_PLATFORM \\"}
                 ${optionalString caelestiaCfg.enable "QT_QPA_PLATFORMTHEME \\"}
                 ${optionalString caelestiaCfg.enable "QT_WAYLAND_DISABLE_WINDOWDECORATION \\"}
                 ${optionalString caelestiaCfg.enable "QT_AUTO_SCREEN_SCALE_FACTOR \\"}
                 HYPRLAND_INSTANCE_SIGNATURE
          hey.do systemctl --user start hyprland-session.target
          hey .play-sound startup
        '';
        startup."07-monitor-reconcile" = optionalString cfg.monitorHotplug.enable ''
          hey.do ${monitorReconcilePackage}/bin/hyprland-reconcile-monitors
        '';

        # I'm using this instead of exec-once lines in hyprland.lua so I can ensure
        # these aren't run at startup and sequentially (i.e. predictable order,
        # since Hyprland's exec calls are parallelized).
        reload."95-hyprland" = ''
          for i in $(hyprctl instances -j | jq -r '.[].instance'); do
            echo "Hyprland: reloading instance $i"
            hey.do hyprctl -i ''${i//*\//} reload config-only
          done
        '';
        reload."96-monitor-reconcile" = optionalString cfg.monitorHotplug.enable ''
          hey.do ${monitorReconcilePackage}/bin/hyprland-reconcile-monitors
        '';
      } // optionalAttrs (!caelestiaOwnsWallpaper) {
        # Set wallpaper according to modules.theme.wallpapers when Caelestia is
        # not the wallpaper owner.
        startup."10-wallpaper" = swaybgWallpaperHook;
        reload."10-wallpaper" = swaybgWallpaperHook;
      };
    };

    modules.desktop.caelestia.session.preStart = optional (caelestiaCfg.enable && caelestiaMonitorSeeds != []) "${caelestiaMonitorSeedScript}";

    home.configFile = {
      "hypr" = {
        source = "${hey.configDir}/hypr";
        recursive = true;
      };

      "hypr/shaders/screen-dim.glsl".text = ''
        precision highp float;
        varying vec2 v_texcoord;
        uniform sampler2D tex;
        void main() {
          gl_FragColor = texture2D(tex, v_texcoord) * 0.3;
        }
      '';

      "hypr/monitors.lua".text = ''
        -- Generated by NixOS from modules.desktop.hyprland.monitors.
        ${concatStringsSep "\n" (map
          monitorLine
          cfg.monitors)}
      '';

      "hypr/workspaces.lua".text = ''
        -- Generated by NixOS from Axiom host workspace facts.
        ${optionalString (primaryMonitorName != "") ''
          hl.config({
            cursor = {
              default_monitor = "${primaryMonitorName}",
            },
          })

          -- Since Wayland does not have a global primary monitor concept,
          -- XWayland windows need an explicit hint when an output is known.
          hl.on("hyprland.start", function()
            hl.exec_cmd("xrandr --output ${primaryMonitorName} --primary")
          end)
        ''}
        ${workspaceLines}
      '';

      "hypr/custom/env.lua".text = ''
        -- Generated by NixOS for Axiom desktop integration.
        hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
        hl.env("XDG_SESSION_DESKTOP", "Hyprland")
        hl.env("XDG_SESSION_TYPE", "wayland")
        hl.env("NIXOS_OZONE_WL", "1")
        hl.env("MOZ_ENABLE_WAYLAND", "1")
        hl.env("GTK_USE_PORTAL", "1")
        ${optionalString caelestiaCfg.enable ''hl.env("QT_QPA_PLATFORM", "${qtPlatform}")''}
        ${optionalString caelestiaCfg.enable ''hl.env("QT_QPA_PLATFORMTHEME", "${qtPlatformTheme}")''}
        ${optionalString caelestiaCfg.enable ''hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")''}
        ${optionalString caelestiaCfg.enable ''hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")''}
        hl.env("TERMINAL", "${terminalCommand}")
        hl.env("BROWSER", "${browserCommand}")
        hl.env("EDITOR", "${editorCommand}")
      '';

      "hypr/custom/execs.lua".text = ''
        -- Generated by NixOS. UWSM/greetd start Hyprland; this starts Nix-owned user units.
        hl.on("hyprland.start", function()
          hl.exec_cmd("hey hook startup")
        end)
      '';

      "hypr/custom/rules.lua".text = ''
        -- Generated by NixOS for Axiom host application placement.
        hl.window_rule({ name = "zen-browser-workspace", match = { class = "^(${zenWmClass}|zen|zen-browser)$" }, workspace = "3 silent" })
        hl.window_rule({ name = "chat-workspace", match = { class = "^(vesktop|discord)$" }, workspace = "4 silent" })
        hl.window_rule({ name = "gaming-workspace", match = { class = "^(steam|gamescope)$" }, workspace = "5 silent" })
        hl.window_rule({ name = "gaming-titles-workspace", match = { title = "^(Friends List|Steam)$" }, workspace = "5 silent" })
        hl.window_rule({ name = "network-workspace", match = { class = "^(nm-connection-editor)$" }, workspace = "8 silent" })
        hl.window_rule({ name = "settings-float", match = { class = "^(nm-connection-editor|org.pulseaudio.pavucontrol)$" }, float = true })
        hl.window_rule({ name = "pip-float", match = { title = "^(Picture-in-Picture)$" }, float = true })
        hl.window_rule({ name = "pip-pin", match = { title = "^(Picture-in-Picture)$" }, pin = true })
        hl.window_rule({ name = "suppress-maximize", match = { class = ".*" }, suppress_event = "maximize" })
        hl.window_rule({ name = "gaming-immediate", match = { class = "^(gamescope|steam_app_.*)$" }, immediate = true })
        hl.window_rule({ name = "idle-inhibit-fullscreen", match = { class = ".*" }, idle_inhibit = "fullscreen" })
        hl.window_rule({ name = "idle-inhibit-focus", match = { class = "^(mpv|vesktop|discord|gamescope|steam_app_.*)$" }, idle_inhibit = "focus" })
        hl.layer_rule({ name = "caelestia-blur", match = { namespace = "caelestia.*" }, blur = true })
        hl.layer_rule({ name = "caelestia-alpha", match = { namespace = "caelestia.*" }, ignore_alpha = 0.79 })
        hl.layer_rule({ name = "selection-no-anim", match = { namespace = "selection" }, no_anim = true })
      '';

      "hypr/custom/keybinds.lua".text = ''
        -- Generated by NixOS for Axiom host policy and Caelestia entrypoints.
        hl.bind("SUPER + slash", hl.dsp.exec_cmd("${keybindingHelpScript}"))
        hl.bind("SUPER + Space", hl.dsp.exec_cmd("${caelestiaCli} shell drawers toggle launcher"))
        hl.bind("SUPER + A", hl.dsp.exec_cmd("${caelestiaCli} shell drawers toggle sidebar"))
        hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("${caelestiaCli} shell drawers toggle session"))
        hl.bind("SUPER + SHIFT + L", hl.dsp.exec_cmd("${caelestiaLockCommand}"))
        hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("${caelestiaCli} shell brightness set +10%"), { locked = true })
        hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("${caelestiaCli} shell brightness set 10%-"), { locked = true })
        hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("${caelestiaCli} shell mpris playPause"), { locked = true })
        hl.bind("XF86AudioPause", hl.dsp.exec_cmd("${caelestiaCli} shell mpris playPause"), { locked = true })
        hl.bind("XF86AudioNext", hl.dsp.exec_cmd("${caelestiaCli} shell mpris next"), { locked = true })
        hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("${caelestiaCli} shell mpris previous"), { locked = true })
        hl.bind("XF86AudioStop", hl.dsp.exec_cmd("${caelestiaCli} shell mpris stop"), { locked = true })

        hl.bind("CTRL + SUPER + SHIFT + R", hl.dsp.exec_cmd("${caelestiaSession} stop"), { release = true })
        hl.bind("CTRL + SUPER + ALT + R", hl.dsp.exec_cmd("${caelestiaSession} restart"), { release = true })

        hl.bind("SUPER + SHIFT + Return", hl.dsp.exec_cmd("${tmuxTerminalCommand}"))
        hl.bind("SUPER + B", hl.dsp.exec_cmd("app2unit -- ${browserCommand}"))
        hl.bind("SUPER + E", hl.dsp.exec_cmd("app2unit -- thunar"))
        hl.bind("SUPER + Q", hl.dsp.window.close())
        hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
        hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
        hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
        hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"))

        hl.bind("Print", hl.dsp.exec_cmd("${caelestiaCli} screenshot"), { locked = true })
        hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("${caelestiaCli} shell picker openFreeze"))
        hl.bind("SUPER + SHIFT + ALT + S", hl.dsp.exec_cmd("${caelestiaCli} shell picker open"))
        hl.bind("SUPER + ALT + R", hl.dsp.exec_cmd("${caelestiaCli} record -s"))
        hl.bind("CTRL + ALT + R", hl.dsp.exec_cmd("${caelestiaCli} record"))
        hl.bind("SUPER + SHIFT + ALT + R", hl.dsp.exec_cmd("${caelestiaCli} record -r"))
        hl.bind("SUPER + V", hl.dsp.exec_cmd("${caelestiaCli} clipboard"))
        hl.bind("SUPER + Period", hl.dsp.exec_cmd("${caelestiaCli} emoji -p"))

        ${workspaceKeybindLines}
        hl.bind("SUPER + SHIFT + mouse_down", hl.dsp.window.move({ workspace = "+1" }))
        hl.bind("SUPER + SHIFT + mouse_up", hl.dsp.window.move({ workspace = "-1" }))

        hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("hey reload"))
      '';

      "hypr/custom/general.lua".text = ''
        -- Generated by NixOS for host policy and module extraConfig (Lua).
        hl.config({
          ecosystem = {
            no_update_news = true,
          },
        })

        hl.config({
          input = {
            -- Host keyboard facts come from modules.desktop.input.* and must win
            -- over the imported upstream default `kb_layout = us`.
            kb_layout = "${xkbLayout}",
            ${optionalString (xkbVariant != "") ''kb_variant = "${xkbVariant}",''}
            ${optionalString (xkbOptions != "") ''kb_options = "${xkbOptions}",''}
          },
        })

        ${optionalString hasScaledMonitor ''
          hl.config({
            xwayland = {
              force_zero_scaling = true,
            },
          })
        ''}

        ${cfg.extraConfig}
      '';

      "uwsm/env".text = ''
        export PATH=${escapeShellArg desktopSessionPath}
        export XDG_CURRENT_DESKTOP=Hyprland
        export XDG_SESSION_DESKTOP=Hyprland
        export XDG_SESSION_TYPE=wayland
        export NIXOS_OZONE_WL=1
        export MOZ_ENABLE_WAYLAND=1
        export GTK_USE_PORTAL=1
        ${optionalString caelestiaCfg.enable "export QT_QPA_PLATFORM=${escapeShellArg qtPlatform}"}
        ${optionalString caelestiaCfg.enable "export QT_QPA_PLATFORMTHEME=${qtPlatformTheme}"}
        ${optionalString caelestiaCfg.enable "export QT_WAYLAND_DISABLE_WINDOWDECORATION=1"}
        ${optionalString caelestiaCfg.enable "export QT_AUTO_SCREEN_SCALE_FACTOR=1"}
      '';
    };

    user.packages = (with pkgs; [
      (mkLauncherEntry "Color picker: copy hex at point" {
        icon = "com.github.finefindus.eyedropper";
        exec = "hyprpicker -a";
      })
    ]) ++ optional cfg.monitorHotplug.enable monitorReconcilePackage;
  };
}

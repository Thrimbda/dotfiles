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
    monitorV2Fields = monitor: [
      "  output = ${monitor.output}"
      "  mode = ${monitorEffectiveMode monitor}"
      "  position = ${monitor.position}"
      "  scale = ${toString monitor.scale}"
    ]
      ++ optional (monitor.bitdepth != null) "  bitdepth = ${toString monitor.bitdepth}"
      ++ optional (monitor.cm != null) "  cm = ${monitor.cm}"
      ++ optional (monitor.sdrbrightness != null) "  sdrbrightness = ${toString monitor.sdrbrightness}"
      ++ optional (monitor.sdrsaturation != null) "  sdrsaturation = ${toString monitor.sdrsaturation}";
    monitorLine = monitor:
      if monitor.disable
      then "monitor = ${monitor.output},disable"
      else if hasAdvancedMonitorFields monitor
      then concatStringsSep "\n" ([ "monitorv2 {" ] ++ monitorV2Fields monitor ++ [ "}" ])
      else "monitor = ${monitor.output},${monitorEffectiveMode monitor},${monitor.position},${toString monitor.scale}";
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
        | "\($output.name),\($mode),\($config.position),\($config.scale)"
      ' <<EOF
      $live
      EOF
      )"

      [ -n "$commands" ] || exit 0

      status=0
      while IFS= read -r command; do
        [ -n "$command" ] || continue
        if ! "$hyprctl" keyword monitor "$command"; then
          status=1
        fi
      done <<EOF
      $commands
      EOF
      exit "$status"
    '';
    monitorHotplugWatcher = pkgs.writeShellScript "hyprland-monitor-hotplug" ''
      set -eu

      reconcile=${escapeShellArg "${monitorReconcilePackage}/bin/hyprland-reconcile-monitors"}
      runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"

      if [ -z "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        printf 'hyprland-monitor-hotplug: HYPRLAND_INSTANCE_SIGNATURE is not set\n' >&2
        exit 1
      fi

      socket="$runtime_dir/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
      debounce_file="$runtime_dir/hyprland-monitor-hotplug.debounce"

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
        if [ ! -S "$socket" ]; then
          ${pkgs.coreutils}/bin/sleep 1
          continue
        fi

        ${pkgs.socat}/bin/socat -u UNIX-CONNECT:"$socket" - | while IFS= read -r event; do
          case "$event" in
            monitor*|configreloaded*) schedule_reconcile ;;
          esac
        done

        ${pkgs.coreutils}/bin/sleep 1
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
        let suffix = optionalString (n == 1) ",default:true,persistent:true";
            monitorPart = optionalString (primaryMonitorName != "") ",monitor:$PRIMARY_MONITOR";
        in "workspace=${toString n}${monitorPart}${suffix}")
      (range 1 10));
    secondaryWorkspaceLines = optionalString (secondaryMonitorName != "") (concatStringsSep "\n" (map
      (n:
        let suffix = optionalString (n == 11) ",default:true,persistent:true";
        in "workspace=${toString n},monitor:$SECONDARY_MONITOR${suffix}")
      (range 11 20)));
    workspaceLines = concatStringsSep "\n" (filter (line: line != "") [
      primaryWorkspaceLines
      secondaryWorkspaceLines
    ]);
    workspaceKeybindLines = concatStringsSep "\n" (
      (map (entry: "bind = SUPER, ${entry.key}, workspace, ${toString entry.primary}") workspaceKeys)
      ++ (map (entry: "bind = SUPER+SHIFT, ${entry.key}, movetoworkspace, ${toString entry.primary}") workspaceKeys)
      ++ optionals (secondaryMonitorName != "") (
        (map (entry: "bind = SUPER+ALT, ${entry.key}, workspace, ${toString entry.secondary}") workspaceKeys)
        ++ (map (entry: "bind = SUPER+ALT+SHIFT, ${entry.key}, movetoworkspace, ${toString entry.secondary}") workspaceKeys)
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
      xorg.xrandr    # for XWayland windows
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

    systemd.user.services.hypridle = {
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

        # I'm using this instead of exec= lines in hyprland.conf so I can ensure
        # these aren't run at startup and sequentially (i.e. predictable order,
        # since Hyprland's exec= calls are parallelized).
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

      "hypr/monitors.conf".text = ''
        # Generated by NixOS from modules.desktop.hyprland.monitors.
        ${concatStringsSep "\n" (map
          monitorLine
          cfg.monitors)}
      '';

      "hypr/workspaces.conf".text = ''
        # Generated by NixOS from Axiom host workspace facts.
        $PRIMARY_MONITOR = ${primaryMonitorName}
        ${optionalString (secondaryMonitorName != "") "$SECONDARY_MONITOR = ${secondaryMonitorName}"}
        ${optionalString (primaryMonitorName != "") ''
          cursor {
            default_monitor = $PRIMARY_MONITOR
          }

          # Since Wayland does not have a global primary monitor concept,
          # XWayland windows need an explicit hint when an output is known.
          exec-once = xrandr --output $PRIMARY_MONITOR --primary
        ''}
        ${workspaceLines}
      '';

      "hypr/custom/env.conf".text = ''
        # Generated by NixOS for Axiom desktop integration.
        env = XDG_CURRENT_DESKTOP,Hyprland
        env = XDG_SESSION_DESKTOP,Hyprland
        env = XDG_SESSION_TYPE,wayland
        env = NIXOS_OZONE_WL,1
        env = MOZ_ENABLE_WAYLAND,1
        env = GTK_USE_PORTAL,1
        ${optionalString caelestiaCfg.enable "env = QT_QPA_PLATFORM,${qtPlatform}"}
        ${optionalString caelestiaCfg.enable "env = QT_QPA_PLATFORMTHEME,${qtPlatformTheme}"}
        ${optionalString caelestiaCfg.enable "env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1"}
        ${optionalString caelestiaCfg.enable "env = QT_AUTO_SCREEN_SCALE_FACTOR,1"}
        env = TERMINAL,${terminalCommand}
        env = BROWSER,${browserCommand}
        env = EDITOR,${editorCommand}
      '';

      "hypr/custom/variables.conf".text = ''
        # Generated by NixOS for host-owned defaults and service boundaries.
        $terminal = ${terminalCommand}
        $fileExplorer = thunar
        $fileManager = thunar
        $browser = ${browserCommand}
        $codeEditor = ${editorCommand}
        $textEditor = ${editorCommand}
        $volumeMixer = pavucontrol
        $settingsApp = pavucontrol
        $taskManager = ${terminalCommand} -e htop
        $caelestia = ${caelestiaCli}
      '';

      "hypr/custom/execs.conf".text = ''
        # Generated by NixOS. UWSM/greetd start Hyprland; this starts Nix-owned user units.
        exec-once = hey hook startup
      '';

      "hypr/custom/rules.conf".text = ''
        # Generated by NixOS for Axiom host application placement.
        windowrule = match:class ^(${zenWmClass}|zen|zen-browser)$, workspace 3 silent
        windowrule = match:class ^(vesktop|discord)$, workspace 4 silent
        windowrule = match:class ^(steam|gamescope)$, workspace 5 silent
        windowrule = match:title ^(Friends List|Steam)$, workspace 5 silent
        windowrule = match:class ^(blueman-manager|nm-connection-editor)$, workspace 8 silent
        windowrule = match:class ^(blueman-manager|nm-connection-editor|org.pulseaudio.pavucontrol)$, float yes
        windowrule = match:title ^(Picture-in-Picture)$, float yes
        windowrule = match:title ^(Picture-in-Picture)$, pin true
        windowrule = match:class .*, suppress_event maximize
        windowrule = match:class ^(gamescope|steam_app_.*)$, immediate true
        windowrule = match:class .*, idle_inhibit fullscreen
        windowrule = match:class ^(mpv|vesktop|discord|gamescope|steam_app_.*)$, idle_inhibit focus
        layerrule = match:namespace caelestia.*, blur true
        layerrule = match:namespace caelestia.*, ignore_alpha 0.79
        layerrule = match:namespace selection, no_anim true
      '';

      "hypr/custom/keybinds.conf".text = ''
        # Generated by NixOS for Axiom host policy and Caelestia entrypoints.
        bind = SUPER, slash, exec, ${keybindingHelpScript}
        bind = SUPER, Space, exec, $caelestia shell drawers toggle launcher
        bind = SUPER, A, exec, $caelestia shell drawers toggle sidebar
        bind = CTRL+ALT, Delete, exec, $caelestia shell drawers toggle session
        bind = SUPER+SHIFT, L, exec, ${caelestiaLockCommand}
        bindl = , XF86MonBrightnessUp, exec, $caelestia shell brightness set +10%
        bindl = , XF86MonBrightnessDown, exec, $caelestia shell brightness set 10%-
        bindl = , XF86AudioPlay, exec, $caelestia shell mpris playPause
        bindl = , XF86AudioPause, exec, $caelestia shell mpris playPause
        bindl = , XF86AudioNext, exec, $caelestia shell mpris next
        bindl = , XF86AudioPrev, exec, $caelestia shell mpris previous
        bindl = , XF86AudioStop, exec, $caelestia shell mpris stop

        bindr = CTRL+SUPER+SHIFT, R, exec, ${caelestiaSession} stop
        bindr = CTRL+SUPER+ALT, R, exec, ${caelestiaSession} restart

        bind = SUPER+SHIFT, Return, exec, ${tmuxTerminalCommand}
        bind = SUPER, B, exec, app2unit -- ${browserCommand}
        bind = SUPER, E, exec, app2unit -- $fileExplorer
        bind = SUPER, Q, killactive
        bind = SUPER, F, fullscreen, 0
        bind = SUPER+SHIFT, C, exec, hyprpicker -a

        bindl = , Print, exec, $caelestia screenshot
        bind = SUPER+SHIFT, S, exec, $caelestia shell picker openFreeze
        bind = SUPER+SHIFT+ALT, S, exec, $caelestia shell picker open
        bind = SUPER+ALT, R, exec, $caelestia record -s
        bind = CTRL+ALT, R, exec, $caelestia record
        bind = SUPER+SHIFT+ALT, R, exec, $caelestia record -r
        bind = SUPER, V, exec, $caelestia clipboard
        bind = SUPER, Period, exec, $caelestia emoji -p

        ${workspaceKeybindLines}

        bind = SUPER+SHIFT, R, exec, hey reload
      '';

      "hypr/custom/general.conf".text = ''
        # Generated by NixOS for host policy and module extraConfig.
        ecosystem {
          no_update_news = true
        }

        input {
          # Host keyboard facts come from modules.desktop.input.* and must win
          # over the imported upstream default `kb_layout = us`.
          kb_layout = ${xkbLayout}
          ${optionalString (xkbVariant != "") "kb_variant = ${xkbVariant}"}
          ${optionalString (xkbOptions != "") "kb_options = ${xkbOptions}"}
        }

        ${optionalString hasScaledMonitor ''
          xwayland {
            force_zero_scaling = true
          }
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

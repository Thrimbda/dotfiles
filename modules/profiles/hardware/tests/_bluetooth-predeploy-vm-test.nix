{ pkgs
, lib
, authService
, rfkillProjectionFactory
, caelestiaPackage
, finalizerSource
}:

let
  python = pkgs.python3.withPackages (ps: [ ps.pygobject3 ps.pycairo ]);
  fakeBluez = pkgs.writeShellScript "vm-fake-bluez" ''
    exec ${python}/bin/python ${./vm-fake-bluez.py}
  '';
  agentCall = pkgs.writeShellScript "vm-agent-call" ''
    exec ${pkgs.python3}/bin/python ${./vm-agent-call.py} "$@"
  '';
  rfkillMain = pkgs.writeShellScript "vm-rfkill-main" ''
    exec ${pkgs.python3}/bin/python ${./vm-rfkill-main.py}
  '';
  bluezBtvirt = pkgs.bluez.overrideAttrs (old: {
    pname = "bluez-btvirt";
    configureFlags = (old.configureFlags or [ ]) ++ [ "--enable-testing" ];
    postInstall = (old.postInstall or "") + ''
      install -Dm755 emulator/btvirt "$out/bin/btvirt"
    '';
  });
  fakeRfkill = pkgs.writeShellScript "vm-fake-rfkill" ''
    set -eu
    root=/run/bluetooth-predeploy/rfkill
    [ "$#" -eq 2 ] && [ "$1" = unblock ] && [ "$2" = bluetooth ]
    printf '%s %s\n' "$1" "$2" >> "$root/rfkill-writes"
    mode="$(${pkgs.coreutils}/bin/cat "$root/finalizer-mode")"
    [ "$mode" != command-failure ] || exit 1
    [ "$mode" != verify-fail ] || exit 0
    changed=false
    for type_file in "$root"/sys/class/rfkill/*/type; do
      [ -e "$type_file" ] || continue
      IFS= read -r type < "$type_file" || continue
      [ "$type" = bluetooth ] || continue
      soft="''${type_file%/type}/soft"
      IFS= read -r value < "$soft" || continue
      if [ "$value" = 1 ]; then
        printf '0\n' > "$soft"
        changed=true
      fi
    done
    if [ "$changed" = true ] && [ ! -e "$root/suppress-change" ] \
        && [ -S "$root/systemd-rfkill.socket" ]; then
      printf 'CHANGE' | ${pkgs.socat}/bin/socat - UNIX-SENDTO:"$root/systemd-rfkill.socket"
    fi
    if [ -e "$root/hold-helper-after-write" ]; then
      : > "$root/helper-held-''${INVOCATION_ID:-unknown}"
      while [ ! -e "$root/release-helper" ]; do
        ${pkgs.coreutils}/bin/sleep 0.02
      done
    fi
  '';
  testFinalizer = pkgs.writeTextFile {
    name = "vm-bluetooth-rfkill-finalize";
    executable = true;
    text = builtins.replaceStrings
      [ "@rfkillSysfs@" "@rfkillCommand@" ]
      [ "/run/bluetooth-predeploy/rfkill/sys/class/rfkill" "${fakeRfkill}" ]
      (builtins.readFile finalizerSource);
  };
  tlpProjection = rfkillProjectionFactory {
    tlpEnabled = true;
    finalizer = testFinalizer;
  };
  fakeTlp = pkgs.writeShellScript "vm-fake-tlp" ''
    set -eu
    root=/run/bluetooth-predeploy
    rfkill="$root/rfkill"
    action="$*"

    set_bluetooth_blocked() {
      for type_file in "$rfkill"/sys/class/rfkill/*/type; do
        [ -e "$type_file" ] || continue
        IFS= read -r type < "$type_file" || continue
        [ "$type" = bluetooth ] || continue
        printf '1\n' > "''${type_file%/type}/soft"
      done
    }

    case "$action" in
      "init start")
        mode="$(${pkgs.coreutils}/bin/cat "$root/tlp-init-mode")"
        printf 'tlp-fixture phase=init-start mode=%s\n' "$mode"
        case "$mode" in
          normal)
            set_bluetooth_blocked
            printf 'tlp-fixture phase=init-end result=success\n'
            ;;
          failure)
            set_bluetooth_blocked
            printf 'tlp-fixture phase=init-failure-end result=failed\n'
            exit 42
            ;;
          timeout)
            set_bluetooth_blocked
            trap 'printf "tlp-fixture phase=init-timeout-end result=timeout\\n"; exit 124' TERM INT
            printf 'tlp-fixture phase=init-timeout-start\n'
            ${pkgs.coreutils}/bin/sleep 30
            ;;
          *) exit 64 ;;
        esac
        ;;
      "init stop")
        printf 'tlp-fixture phase=init-stop-end result=success\n'
        ;;
      start)
        printf 'tlp-fixture phase=reload-end result=success\n'
        ;;
      suspend)
        printf 'tlp-fixture phase=suspend-end result=success\n'
        ;;
      resume)
        mode="$(${pkgs.coreutils}/bin/cat "$root/tlp-resume-mode")"
        set_bluetooth_blocked
        if [ "$mode" = failure ]; then
          printf 'tlp-fixture phase=resume-failure-end result=failed\n'
          exit 43
        fi
        [ "$mode" = normal ] || exit 64
        printf 'tlp-fixture phase=resume-end result=success\n'
        ;;
      *) exit 64 ;;
    esac
  '';
  fakeTlpPackage = pkgs.tlp.overrideAttrs (old: {
    pname = "tlp-vm-fixture";
    postInstall = (old.postInstall or "") + ''
      install -Dm755 ${fakeTlp} "$out/sbin/tlp"
    '';
  });
  fakeSystemdSleep = pkgs.writeShellScript "vm-fake-systemd-sleep" ''
    set -eu
    printf 'sleep-fixture phase=executor-start action=%s\n' "''${1:-unknown}"
    ${pkgs.coreutils}/bin/sleep 0.05
    printf 'sleep-fixture phase=executor-end action=%s\n' "''${1:-unknown}"
  '';
  postResumeProbe = pkgs.writeShellScript "vm-post-resume-probe" ''
    set -eu
    root=/run/bluetooth-predeploy
    if [ -e "$root/hold-post-resume" ]; then
      printf 'post-resume-fixture phase=trigger-held\n'
      : > "$root/post-resume-held-''${INVOCATION_ID:?}"
      while [ ! -e "$root/release-post-resume" ]; do
        ${pkgs.coreutils}/bin/sleep 0.02
      done
    fi
  '';
  stopPost = pkgs.writeShellScript "vm-systemd-rfkill-stop-post" ''
    set -u
    root=/run/bluetooth-predeploy/rfkill
    invocation="''${INVOCATION_ID:?}"
    service_result="''${SERVICE_RESULT:-unknown}"
    printf '{"InvocationID":"%s","SERVICE_RESULT":"%s","phase":"exec-stop-post-start"}\n' \
      "$invocation" "$service_result" >> "$root/events.jsonl"
    printf 'rfkill-fixture phase=exec-stop-post-start service-result=%s\n' "$service_result"
    if [ -e "$root/hold-post" ]; then
      ${pkgs.coreutils}/bin/mv "$root/hold-post" "$root/hold-consumed"
      : > "$root/post-held"
      while [ ! -e "$root/release-post" ]; do
        ${pkgs.coreutils}/bin/sleep 0.02
      done
      ${pkgs.coreutils}/bin/rm -f "$root/post-held" "$root/release-post"
    fi
    set +e
    ${testFinalizer}
    finalizer_status=$?
    set -e
    printf '{"InvocationID":"%s","SERVICE_RESULT":"%s","finalizer_status":%s,"phase":"exec-stop-post-end"}\n' \
      "$invocation" "$service_result" "$finalizer_status" >> "$root/events.jsonl"
    printf 'rfkill-fixture phase=exec-stop-post-end service-result=%s finalizer-status=%s\n' \
      "$service_result" "$finalizer_status"
    exit "$finalizer_status"
  '';
  initFixture = pkgs.writeShellScript "vm-bluetooth-predeploy-init" ''
    set -eu
    root=/run/bluetooth-predeploy
    rfkill="$root/rfkill"
    ${pkgs.coreutils}/bin/install -d -m 0777 \
      "$root" "$root/state/caelestia" "$rfkill/sys/class/rfkill/rfkill0" \
      "$rfkill/sys/class/rfkill/rfkill1"
    printf 'wlan\n' > "$rfkill/sys/class/rfkill/rfkill0/type"
    printf 'WLAN-LIVE-SENTINEL\n' > "$rfkill/sys/class/rfkill/rfkill0/soft"
    printf '0\n' > "$rfkill/sys/class/rfkill/rfkill0/hard"
    printf 'bluetooth\n' > "$rfkill/sys/class/rfkill/rfkill1/type"
    printf '1\n' > "$rfkill/sys/class/rfkill/rfkill1/soft"
    printf '0\n' > "$rfkill/sys/class/rfkill/rfkill1/hard"
    printf '1\n' > "$rfkill/persisted-bluetooth"
    printf 'WLAN-PERSISTED-UNIQUE\000\377\n' > "$rfkill/persisted-wlan"
    printf 'normal\n' > "$rfkill/scenario"
    printf 'normal\n' > "$rfkill/finalizer-mode"
    printf 'normal\n' > "$root/tlp-init-mode"
    printf 'normal\n' > "$root/tlp-resume-mode"
    : > "$rfkill/events.jsonl"
    : > "$rfkill/rfkill-writes"
    printf 'TLP-STATE-UNIQUE\000\376\n' > "$root/tlp-state"
    printf '%s' '[{"time":"2026-07-12T00:00:00.000Z","id":"baseline-1","summary":"Baseline notification","body":"must remain unchanged","appIcon":"","appName":"VM fixture","image":"","expireTimeout":0,"urgency":1,"resident":true,"hasActionIcons":false,"actions":[]}]' \
      > "$root/state/caelestia/notifs.json"
    printf 'PIN2468' > "$root/input-pin"
    printf '135790' > "$root/input-passkey"
    ${pkgs.coreutils}/bin/chown -R fixture:users "$root/state"
  '';
  notifsHarnessPackage = caelestiaPackage.overrideAttrs (old: {
    pname = "caelestia-notifs-harness";
    postInstall = (old.postInstall or "") + ''
      install -m 0644 ${./vm-notifs-harness.qml} \
        "$out/share/caelestia-shell/shell.qml"
    '';
  });
in
pkgs.testers.runNixOSTest {
  name = "bluetooth-predeploy-integration";

  nodes.machine = { ... }: {
    virtualisation = {
      memorySize = 1536;
      cores = 2;
    };

    users.users.fixture = {
      isNormalUser = true;
      uid = 1000;
      group = "users";
      linger = true;
    };

    environment.systemPackages = [
      pkgs.dbus
      pkgs.glib
      pkgs.jq
      pkgs.socat
      pkgs.xdotool
    ];

    systemd.tmpfiles.rules = [
      "d /run/bluetooth-predeploy 0777 root root -"
    ];

    systemd.services.bluetooth-predeploy-init = {
      wantedBy = [ "multi-user.target" ];
      before = [
        "bluetooth-private-system-bus.service"
        "bluetooth-private-session-bus.service"
        "systemd-rfkill.socket"
      ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = initFixture;
        RemainAfterExit = true;
      };
    };

    systemd.services.bluetooth-private-system-bus = {
      wantedBy = [ "multi-user.target" ];
      after = [ "bluetooth-predeploy-init.service" ];
      serviceConfig = {
        User = "fixture";
        Group = "users";
        ExecStartPre = "${pkgs.coreutils}/bin/rm -f /run/bluetooth-predeploy/system-bus";
        ExecStart = "${pkgs.dbus}/bin/dbus-daemon --session --nofork --nopidfile --address=unix:path=/run/bluetooth-predeploy/system-bus";
        Restart = "on-failure";
      };
    };

    systemd.services.bluetooth-private-session-bus = {
      wantedBy = [ "multi-user.target" ];
      after = [ "bluetooth-predeploy-init.service" ];
      serviceConfig = {
        User = "fixture";
        Group = "users";
        ExecStartPre = "${pkgs.coreutils}/bin/rm -f /run/bluetooth-predeploy/session-bus";
        ExecStart = "${pkgs.dbus}/bin/dbus-daemon --session --nofork --nopidfile --address=unix:path=/run/bluetooth-predeploy/session-bus";
        Restart = "on-failure";
      };
    };

    systemd.services.vm-fake-bluez = {
      wantedBy = [ "multi-user.target" ];
      requires = [ "bluetooth-private-system-bus.service" ];
      after = [ "bluetooth-private-system-bus.service" ];
      serviceConfig = {
        User = "fixture";
        Group = "users";
        ExecStart = fakeBluez;
        Restart = "on-failure";
      };
    };

    systemd.services.vm-xvfb = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.xorg.xorgserver}/bin/Xvfb :99 -ac -screen 0 1024x768x24 -nolisten tcp";
        Restart = "on-failure";
      };
    };

    systemd.services.vm-notify-monitor = {
      requires = [ "bluetooth-private-session-bus.service" ];
      after = [ "bluetooth-private-session-bus.service" ];
      serviceConfig = {
        User = "fixture";
        Group = "users";
        ExecStart = "${pkgs.dbus}/bin/dbus-monitor --address unix:path=/run/bluetooth-predeploy/session-bus type=method_call,interface=org.freedesktop.Notifications,member=Notify";
        StandardOutput = "append:/run/bluetooth-predeploy/notify-monitor.log";
        StandardError = "append:/run/bluetooth-predeploy/notify-monitor.log";
      };
    };

    systemd.user.targets.graphical-session = {
      description = "VM graphical session";
    };

    systemd.user.services.blueman-auth-agent = authService // {
      environment = (authService.environment or { }) // {
        DISPLAY = ":99";
        XDG_RUNTIME_DIR = "/run/user/1000";
        XDG_STATE_HOME = "/run/bluetooth-predeploy/state";
        DBUS_SYSTEM_BUS_ADDRESS = "unix:path=/run/bluetooth-predeploy/system-bus";
        DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/bluetooth-predeploy/session-bus";
        GDK_BACKEND = "x11";
        GI_TYPELIB_PATH = lib.makeSearchPath "lib/girepository-1.0" (
          map lib.getLib [
            pkgs.gobject-introspection
            pkgs.glib
            pkgs.gtk3
            pkgs.gdk-pixbuf
            pkgs.pango
            pkgs.atk
            pkgs.harfbuzz
          ]
        );
        XDG_DATA_DIRS = lib.makeSearchPath "share" [
          pkgs.gtk3
          pkgs.gsettings-desktop-schemas
          pkgs.adwaita-icon-theme
          pkgs.hicolor-icon-theme
        ];
        LD_LIBRARY_PATH = lib.makeLibraryPath [
          pkgs.glib
          pkgs.gtk3
          pkgs.gdk-pixbuf
          pkgs.pango
          pkgs.atk
          pkgs.cairo
          pkgs.xorg.libX11
        ];
        NO_AT_BRIDGE = "1";
      };
    };

    systemd.user.services.caelestia-notifs-harness = {
      description = "Caelestia production Notifs QML harness";
      environment = {
        DISPLAY = ":99";
        QT_QPA_PLATFORM = "xcb";
        XDG_RUNTIME_DIR = "/run/user/1000";
        XDG_STATE_HOME = "/run/bluetooth-predeploy/state";
        DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/bluetooth-predeploy/session-bus";
        NO_AT_BRIDGE = "1";
      };
      serviceConfig = {
        ExecStart = "${notifsHarnessPackage}/bin/caelestia-shell";
        Restart = "on-failure";
        RestartSec = 1;
      };
    };

    # Suppress the vendor files and expose exact systemd-rfkill aliases to
    # complete generated units. This avoids extending the vendor ExecStart.
    systemd.suppressedSystemUnits = [
      "systemd-rfkill.service"
      "systemd-rfkill.socket"
    ];

    systemd.sockets.vm-systemd-rfkill = {
      aliases = [ "systemd-rfkill.socket" ];
      after = [ "bluetooth-predeploy-init.service" ];
      socketConfig = {
        ListenDatagram = "/run/bluetooth-predeploy/rfkill/systemd-rfkill.socket";
        SocketMode = "0666";
        Service = "systemd-rfkill.service";
      };
    };

    systemd.services.vm-systemd-rfkill = {
      aliases = [ "systemd-rfkill.service" ];
      description = "VM fake socket-activated systemd-rfkill";
      unitConfig.StartLimitIntervalSec = 0;
      serviceConfig = {
        Type = "notify";
        NotifyAccess = "main";
        ExecStart = rfkillMain;
        ExecStopPost = [ stopPost ];
        Restart = "no";
        TimeoutStartSec = 10;
        TimeoutStopSec = 15;
      };
    };
  };

  nodes.tlp = { ... }: {
    virtualisation = {
      memorySize = 768;
      cores = 2;
    };

    boot.kernelModules = [ "hci_vhci" ];

    users.users.fixture = {
      isNormalUser = true;
      uid = 1000;
      group = "users";
    };

    environment.systemPackages = [
      bluezBtvirt
      pkgs.jq
      pkgs.socat
    ];

    systemd.tmpfiles.rules = [
      "d /run/bluetooth-predeploy 0777 root root -"
    ];

    services.tlp = {
      enable = true;
      package = fakeTlpPackage;
    };

    systemd.services.bluetooth-predeploy-init = {
      wantedBy = [ "multi-user.target" ];
      before = [ "tlp.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = initFixture;
        RemainAfterExit = true;
      };
    };

    systemd.services.tlp = {
      after = [ "bluetooth-predeploy-init.service" ];
      requires = [ "bluetooth-predeploy-init.service" ];
      wants = tlpProjection.tlpBootWants;
    };

    # Replace only the sleep executor. Requires/After=sleep.target and every
    # suspend/post-resume ordering edge continue to come from pinned systemd.
    systemd.services.systemd-suspend = {
      overrideStrategy = "asDropin";
      serviceConfig.ExecStart = lib.mkForce [
        ""
        "${fakeSystemdSleep} suspend"
      ];
    };

    systemd.services.bluetooth-rfkill-unblock =
      tlpProjection.bootHelperService;

    systemd.services."bluetooth-rfkill-unblock@" =
      tlpProjection.eventHelperService;

    services.udev.extraRules = tlpProjection.udevRule;
    powerManagement.resumeCommands = tlpProjection.resumeCommands;
    # Runs after the production resume command and only keeps the real
    # post-resume invocation observable to the test driver.
    powerManagement.powerUpCommands = "${postResumeProbe}";
  };

  testScript = ''
    import hashlib
    import json
    import re
    import shlex
    import time

    start_all()
    machine.wait_for_unit("multi-user.target")
    machine.wait_for_unit("bluetooth-predeploy-init.service")
    machine.wait_for_unit("user@1000.service")
    machine.wait_for_unit("bluetooth-private-system-bus.service")
    machine.wait_for_unit("bluetooth-private-session-bus.service")
    machine.wait_for_unit("vm-fake-bluez.service")
    machine.wait_for_unit("vm-xvfb.service")
    machine.succeed("systemctl daemon-reload; systemctl start systemd-rfkill.socket")
    machine.wait_for_unit("systemd-rfkill.socket")

    root = "/run/bluetooth-predeploy"
    rfroot = root + "/rfkill"
    system_address = "unix:path=" + root + "/system-bus"
    session_address = "unix:path=" + root + "/session-bus"

    def userctl(command):
        return machine.succeed(
            "runuser -u fixture -- env XDG_RUNTIME_DIR=/run/user/1000 "
            "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus "
            "systemctl --user " + command
        )

    def records():
        text = machine.succeed("cat " + rfroot + "/events.jsonl")
        return [json.loads(line) for line in text.splitlines() if line]

    def wait_records(count):
        machine.wait_until_succeeds(
            "test $(grep -c '\"phase\":\"exec-stop-post-end\"' "
            + rfroot + "/events.jsonl) -ge " + str(count)
        )

    def trigger(event):
        machine.succeed(
            "printf %s " + shlex.quote(event)
            + " | socat - UNIX-SENDTO:" + rfroot + "/systemd-rfkill.socket"
        )

    def assert_invocations_complete(items):
        grouped = {}
        for item in items:
            invocation = item["InvocationID"]
            assert re.fullmatch(r"[0-9a-f]{32}", invocation), invocation
            grouped.setdefault(invocation, []).append(item)
        for invocation, entries in grouped.items():
            phases = [entry["phase"] for entry in entries]
            assert phases.count("exec-stop-post-start") == 1, (invocation, phases)
            assert phases.count("exec-stop-post-end") == 1, (invocation, phases)
        return grouped

    def quiet():
        machine.wait_until_succeeds("systemctl is-active systemd-rfkill.service >/dev/null 2>&1 || test $? -eq 3")
        time.sleep(0.2)

    wlan_live_before = machine.succeed("cat " + rfroot + "/sys/class/rfkill/rfkill0/soft")
    wlan_persisted_before = machine.succeed("sha256sum " + rfroot + "/persisted-wlan | cut -d' ' -f1").strip()

    # Real socket activation plus finalizer-created CHANGE reactivation.
    start = len(records())
    machine.succeed("printf 'normal\\n' > " + rfroot + "/scenario; printf '1\\n' > " + rfroot + "/persisted-bluetooth; printf '0\\n' > " + rfroot + "/sys/class/rfkill/rfkill1/soft")
    trigger("ADD")
    wait_records(2)
    quiet()
    initial = records()[start:]
    assert len(assert_invocations_complete(initial)) == 2
    assert machine.succeed("cat " + rfroot + "/sys/class/rfkill/rfkill1/soft") == "0\n"
    assert machine.succeed("cat " + rfroot + "/persisted-bluetooth") == "0\n"

    # Hold an old invocation in real ExecStopPost, queue ADD, then release it.
    start = len(records())
    machine.succeed("printf 'idle\\n' > " + rfroot + "/scenario; printf '1\\n' > " + rfroot + "/persisted-bluetooth; touch " + rfroot + "/hold-post")
    trigger("IDLE")
    machine.wait_until_succeeds("test -e " + rfroot + "/post-held")
    old = [entry for entry in records()[start:] if entry["phase"] == "exec-stop-post-start"][0]["InvocationID"]
    machine.succeed("printf 'normal\\n' > " + rfroot + "/scenario")
    trigger("ADD")
    time.sleep(0.2)
    assert len([entry for entry in records()[start:] if entry["phase"] == "socket-receive"]) == 1
    machine.succeed("touch " + rfroot + "/release-post")
    wait_records(5)
    quiet()
    late = records()[start:]
    assert len(assert_invocations_complete(late)) == 3
    old_end = next(i for i, entry in enumerate(late) if entry["InvocationID"] == old and entry["phase"] == "exec-stop-post-end")
    next_start = next(i for i, entry in enumerate(late) if i > old_end and entry["phase"] == "socket-receive")
    assert next_start > old_end

    # Startup failure still receives real ExecStopPost and preserves SERVICE_RESULT.
    start = len(records())
    machine.succeed("printf 'startup-failure\\n' > " + rfroot + "/scenario; touch " + rfroot + "/suppress-change; printf '1\\n' > " + rfroot + "/sys/class/rfkill/rfkill1/soft")
    trigger("STARTUP")
    machine.wait_until_succeeds("systemctl is-failed systemd-rfkill.service")
    wait_records(6)
    startup = records()[start:]
    grouped = assert_invocations_complete(startup)
    assert len(grouped) == 1
    assert "main-start" not in [entry["phase"] for entry in startup]
    assert startup[-1]["SERVICE_RESULT"] == "exit-code"
    machine.succeed("systemctl reset-failed systemd-rfkill.service; rm -f " + rfroot + "/suppress-change")

    # Runtime failure retains exit-code while the finalizer still converges.
    start = len(records())
    machine.succeed("printf 'runtime-failure\\n' > " + rfroot + "/scenario; touch " + rfroot + "/suppress-change; printf '1\\n' > " + rfroot + "/persisted-bluetooth")
    trigger("ADD")
    machine.wait_until_succeeds("systemctl is-failed systemd-rfkill.service")
    wait_records(7)
    runtime = records()[start:]
    assert len(assert_invocations_complete(runtime)) == 1
    assert runtime[-1]["SERVICE_RESULT"] == "exit-code"
    machine.succeed("systemctl reset-failed systemd-rfkill.service; rm -f " + rfroot + "/suppress-change")

    # Real restart transaction: old stop-post must finish before new main starts.
    start = len(records())
    machine.succeed("printf 'wait\\n' > " + rfroot + "/scenario; touch " + rfroot + "/suppress-change")
    trigger("WAIT")
    machine.wait_until_succeeds("test -s " + rfroot + "/main-waiting")
    old_restart = machine.succeed("cat " + rfroot + "/main-waiting").strip()
    machine.succeed("printf 'normal\\n' > " + rfroot + "/scenario; systemctl restart --no-block systemd-rfkill.service")
    machine.wait_until_succeeds("grep -q '\"InvocationID\":\"'" + old_restart + "'\".*exec-stop-post-end' " + rfroot + "/events.jsonl")
    wait_records(9)
    quiet()
    restart = records()[start:]
    assert len(assert_invocations_complete(restart)) == 2
    old_end = next(i for i, entry in enumerate(restart) if entry["InvocationID"] == old_restart and entry["phase"] == "exec-stop-post-end")
    new_start = next(i for i, entry in enumerate(restart) if i > old_end and entry["phase"] == "main-start")
    assert new_start > old_end
    machine.succeed("rm -f " + rfroot + "/suppress-change " + rfroot + "/main-waiting")

    # Stop with the socket stopped (shutdown-style) still runs one finalizer.
    start = len(records())
    machine.succeed("printf 'wait\\n' > " + rfroot + "/scenario; touch " + rfroot + "/suppress-change")
    trigger("STOP")
    machine.wait_until_succeeds("test -s " + rfroot + "/main-waiting")
    machine.succeed("systemctl stop systemd-rfkill.socket systemd-rfkill.service")
    shutdown = records()[start:]
    assert len(assert_invocations_complete(shutdown)) == 1
    machine.succeed("rm -f " + rfroot + "/suppress-change " + rfroot + "/main-waiting; systemctl start systemd-rfkill.socket")

    # Repeated events queued during a held post are handled by real activations.
    start = len(records())
    machine.succeed("printf 'idle\\n' > " + rfroot + "/scenario; touch " + rfroot + "/hold-post")
    trigger("IDLE")
    machine.wait_until_succeeds("test -e " + rfroot + "/post-held")
    machine.succeed("printf 'normal\\n' > " + rfroot + "/scenario")
    trigger("CHANGE"); trigger("CHANGE"); trigger("CHANGE")
    machine.succeed("touch " + rfroot + "/release-post")
    wait_records(14)
    quiet()
    repeated = records()[start:]
    assert len(assert_invocations_complete(repeated)) == 4

    # No device is a zero-write successful invocation.
    start = len(records())
    writes_before = machine.succeed("wc -l < " + rfroot + "/rfkill-writes").strip()
    machine.succeed("rm -rf " + rfroot + "/sys/class/rfkill/rfkill1; printf 'normal\\n' > " + rfroot + "/scenario")
    trigger("NO-DEVICE")
    wait_records(15)
    quiet()
    no_device = records()[start:]
    assert len(assert_invocations_complete(no_device)) == 1
    assert machine.succeed("wc -l < " + rfroot + "/rfkill-writes").strip() == writes_before

    # Finalizer verification failure marks the real unit failed.
    machine.succeed("mkdir -p " + rfroot + "/sys/class/rfkill/rfkill1; printf 'bluetooth\\n' > " + rfroot + "/sys/class/rfkill/rfkill1/type; printf '1\\n' > " + rfroot + "/sys/class/rfkill/rfkill1/soft; printf '0\\n' > " + rfroot + "/sys/class/rfkill/rfkill1/hard; printf 'verify-fail\\n' > " + rfroot + "/finalizer-mode")
    start = len(records())
    trigger("FAIL")
    machine.wait_until_succeeds("systemctl is-failed systemd-rfkill.service")
    failed = records()[start:]
    assert len(assert_invocations_complete(failed)) == 1
    assert failed[-1]["finalizer_status"] != 0
    machine.succeed("systemctl reset-failed systemd-rfkill.service; printf 'normal\\n' > " + rfroot + "/finalizer-mode")

    assert machine.succeed("cat " + rfroot + "/sys/class/rfkill/rfkill0/soft") == wlan_live_before
    assert machine.succeed("sha256sum " + rfroot + "/persisted-wlan | cut -d' ' -f1").strip() == wlan_persisted_before
    all_records = records()
    all_ids = set(assert_invocations_complete(all_records))
    journal = machine.succeed("journalctl -u vm-systemd-rfkill.service -o json --no-pager")
    journal_entries = [json.loads(line) for line in journal.splitlines() if line]
    journal_ids = {entry.get("_SYSTEMD_INVOCATION_ID") for entry in journal_entries if "rfkill-fixture" in entry.get("MESSAGE", "")}
    assert all_ids == journal_ids, (all_ids - journal_ids, journal_ids - all_ids)

    # Start the executable production Notifs.qml harness and generated user unit.
    machine.succeed("runuser -u fixture -- env DBUS_SESSION_BUS_ADDRESS=" + session_address + " gdbus call --session --dest org.freedesktop.DBus --object-path /org/freedesktop/DBus --method org.freedesktop.DBus.ListNames")
    machine.succeed("systemctl start vm-notify-monitor.service")
    userctl("start caelestia-notifs-harness.service")
    machine.wait_until_succeeds("test -s " + root + "/notifs-memory.json")
    machine.wait_until_succeeds("runuser -u fixture -- env DBUS_SESSION_BUS_ADDRESS=" + session_address + " gdbus call --session --dest org.freedesktop.Notifications --object-path /org/freedesktop/Notifications --method org.freedesktop.Notifications.GetServerInformation")
    state_before = machine.succeed("sha256sum " + root + "/state/caelestia/notifs.json | cut -d' ' -f1").strip()
    memory_before = machine.succeed("sha256sum " + root + "/notifs-memory.json | cut -d' ' -f1").strip()
    assert "Baseline notification" in machine.succeed("cat " + root + "/notifs-memory.json")
    machine.succeed("cp " + root + "/state/caelestia/notifs.json " + root + "/notifs-state.before; cp " + root + "/notifs-memory.json " + root + "/notifs-memory.before")

    userctl("start blueman-auth-agent.service")
    machine.wait_until_succeeds("runuser -u fixture -- env XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus systemctl --user is-active blueman-auth-agent.service")
    machine.wait_until_succeeds("test -s " + root + "/agent.json")
    unit_show = userctl("show blueman-auth-agent.service -p Type -p ActiveState -p SubState -p InvocationID")
    assert "Type=notify" in unit_show and "ActiveState=active" in unit_show and "SubState=running" in unit_show
    unit_match = re.search(r"InvocationID=([0-9a-f]{32})", unit_show)
    assert unit_match is not None
    unit_invocation = unit_match.group(1)

    client = ${builtins.toJSON "${agentCall}"}
    device = "@DEVICE@"

    def call(method, signature="()", reply="-", values=None):
        if values is None: values = []
        return machine.succeed(" ".join(map(shlex.quote, [client, method, signature, reply, json.dumps(values)])))

    def call_async(tag, method, signature, reply, values):
        result = root + "/call-" + tag + ".json"
        status = root + "/call-" + tag + ".status"
        command = " ".join(map(shlex.quote, [client, method, signature, reply, json.dumps(values)]))
        payload = command + " > " + result + " 2>&1; echo $? > " + status
        machine.succeed(
            "rm -f " + result + " " + status + "; systemd-run --quiet --collect --no-block "
            "--unit=vm-agent-call-" + tag + " -- /bin/sh -c " + shlex.quote(payload)
        )
        return result, status

    def enter_pairing_value(secret_file):
        machine.wait_until_succeeds("DISPLAY=:99 xdotool search --onlyvisible --name '^Pairing request$'")
        machine.succeed("window=$(DISPLAY=:99 xdotool search --onlyvisible --name '^Pairing request$' | tail -1); DISPLAY=:99 xdotool type --window $window --delay 1 \"$(cat " + root + "/" + secret_file + ")\"; DISPLAY=:99 xdotool key --window $window Return")

    pin_result, pin_status = call_async("pin", "RequestPinCode", "(o)", "(s)", [device])
    enter_pairing_value("input-pin")
    machine.wait_until_succeeds("test -s " + pin_status + " && test $(cat " + pin_status + ") -eq 0")

    pass_result, pass_status = call_async("pass", "RequestPasskey", "(o)", "(u)", [device])
    enter_pairing_value("input-passkey")
    machine.wait_until_succeeds("test -s " + pass_status + " && test $(cat " + pass_status + ") -eq 0")

    # Restart clears the two informational local windows before remaining flows.
    userctl("restart blueman-auth-agent.service")
    machine.wait_until_succeeds("test -s " + root + "/agent.json")
    restarted_show = userctl("show blueman-auth-agent.service -p ActiveState -p SubState -p InvocationID")
    restarted_match = re.search(r"InvocationID=([0-9a-f]{32})", restarted_show)
    assert restarted_match is not None
    restarted_invocation = restarted_match.group(1)
    assert restarted_invocation != unit_invocation
    call("DisplayPinCode", "(os)", "-", [device, "@DISPLAY_PIN@"])
    call("Cancel")
    call("DisplayPasskey", "(ouq)", "-", [device, "@DISPLAY_PASSKEY@", 2])
    call("Cancel")

    confirm_result, confirm_status = call_async(
        "confirm", "RequestConfirmation", "(ou)", "-", [device, "@CONFIRM_PASSKEY@"]
    )
    machine.wait_until_succeeds("DISPLAY=:99 xdotool search --onlyvisible --name '^Bluetooth$'")
    machine.succeed("window=$(DISPLAY=:99 xdotool search --onlyvisible --name '^Bluetooth$' | tail -1); eval $(DISPLAY=:99 xdotool getwindowgeometry --shell $window); DISPLAY=:99 xdotool mousemove --window $window $((WIDTH / 4)) $((HEIGHT - 20)) click 1")
    machine.wait_until_succeeds("test -s " + confirm_status + " && test $(cat " + confirm_status + ") -eq 0")

    auth_result, auth_status = call_async("authorization", "RequestAuthorization", "(o)", "-", [device])
    machine.wait_until_succeeds("DISPLAY=:99 xdotool search --onlyvisible --name '^Bluetooth$'")
    machine.succeed("window=$(DISPLAY=:99 xdotool search --onlyvisible --name '^Bluetooth$' | tail -1); eval $(DISPLAY=:99 xdotool getwindowgeometry --shell $window); DISPLAY=:99 xdotool mousemove --window $window $((WIDTH / 4)) $((HEIGHT - 20)) click 1")
    machine.wait_until_succeeds("test -s " + auth_status + " && test $(cat " + auth_status + ") -eq 0")

    service_result, service_status = call_async(
        "service", "AuthorizeService", "(os)", "-", [device, "@SERVICE_UUID@"]
    )
    machine.wait_until_succeeds("DISPLAY=:99 xdotool search --onlyvisible --name '^Bluetooth Authentication$'")
    machine.succeed("window=$(DISPLAY=:99 xdotool search --onlyvisible --name '^Bluetooth Authentication$' | tail -1); eval $(DISPLAY=:99 xdotool getwindowgeometry --shell $window); DISPLAY=:99 xdotool mousemove --window $window $((WIDTH / 2)) $((HEIGHT - 20)) click 1")
    machine.wait_until_succeeds("test -s " + service_status + " && test $(cat " + service_status + ") -eq 0")

    time.sleep(2)
    userctl("stop caelestia-notifs-harness.service")
    machine.succeed("cmp -s " + root + "/notifs-state.before " + root + "/state/caelestia/notifs.json; cmp -s " + root + "/notifs-memory.before " + root + "/notifs-memory.json")
    assert machine.succeed("sha256sum " + root + "/state/caelestia/notifs.json | cut -d' ' -f1").strip() == state_before
    assert machine.succeed("sha256sum " + root + "/notifs-memory.json | cut -d' ' -f1").strip() == memory_before
    assert "Baseline notification" in machine.succeed("cat " + root + "/notifs-memory.json")
    notify_log = machine.succeed("cat " + root + "/notify-monitor.log")
    assert "member=Notify" not in notify_log

    userctl("stop blueman-auth-agent.service")
    machine.succeed("journalctl _SYSTEMD_USER_UNIT=blueman-auth-agent.service -o cat --no-pager > " + root + "/auth-unit.log")
    unit_log = machine.succeed("cat " + root + "/auth-unit.log")
    assert "event=startup_check result=ok stage=runtime" in unit_log
    assert "event=state from=registered reason=initial result=ok to=default" in unit_log
    for sentinel in ["PIN2468", "135790", "654321", "123456", "456789", "AA:BB:CC:DD:EE:FF", "/org/bluez/hci0/dev_AA_BB_CC_DD_EE_FF"]:
        assert sentinel not in unit_log
    auth_journal = machine.succeed("journalctl _SYSTEMD_USER_UNIT=blueman-auth-agent.service -o json --no-pager")
    assert unit_invocation in auth_journal
    assert restarted_invocation in auth_journal

    # Real PID 1 projection of the Revision 5 TLP branch. Pinned vendor TLP
    # units start the full multi-user transaction; only their executable has
    # test behavior. All Bluetooth edges come from the production projection.
    tlp.wait_for_unit("multi-user.target")
    tlp.wait_for_unit("bluetooth-predeploy-init.service")
    tlp.wait_for_unit("systemd-udevd.service")
    tlp.wait_until_succeeds(
        "test \"$(systemctl show -P ActiveState tlp.service)\" = active "
        "&& test -n \"$(systemctl show -P InvocationID bluetooth-rfkill-unblock.service)\" "
        "&& test \"$(systemctl show -P ActiveState bluetooth-rfkill-unblock.service)\" = inactive"
    )
    tlp_root = "/run/bluetooth-predeploy"
    tlp_rfroot = tlp_root + "/rfkill"
    cycle_diagnostic = re.compile(
        r"ordering cycle|found .* cycle|job .* deleted to break ordering cycle",
        re.IGNORECASE,
    )

    def tlp_show(unit, properties):
        return tlp.succeed("systemctl show " + unit + " " + " ".join("-p " + prop for prop in properties))

    def invocation_id(show_output):
        match = re.search(r"InvocationID=([0-9a-f]{32})", show_output)
        assert match is not None, show_output
        return match.group(1)

    def bluetooth_rfkill_names():
        output = tlp.succeed(
            "for type_file in /sys/class/rfkill/*/type; do "
            "[ -e $type_file ] || continue; "
            "[ \"$(cat $type_file)\" = bluetooth ] || continue; "
            "basename $(dirname $type_file); done"
        )
        return {line for line in output.splitlines() if line}

    def wait_new_helper(previous):
        tlp.wait_until_succeeds(
            "new=$(systemctl show -P InvocationID bluetooth-rfkill-unblock.service); "
            "test -n \"$new\" && test \"$new\" != " + previous + " "
            "&& test \"$(systemctl show -P ActiveState bluetooth-rfkill-unblock.service)\" = inactive"
        )
        show = tlp_show(
            "bluetooth-rfkill-unblock.service",
            ["Result", "ActiveState", "InvocationID"],
        )
        assert "Result=success" in show and "ActiveState=inactive" in show
        return invocation_id(show)

    def journal_timestamp(message, unit=None, invocation=None):
        command = "journalctl -b -o json --no-pager"
        if unit is not None:
            command += " -u " + unit
        entries = [
            json.loads(line)
            for line in tlp.succeed(command).splitlines()
            if line
        ]
        matches = [
            int(entry["__MONOTONIC_TIMESTAMP"])
            for entry in entries
            if message in entry.get("MESSAGE", "")
            and (invocation is None or entry.get("_SYSTEMD_INVOCATION_ID") == invocation)
        ]
        assert matches, (message, unit, invocation)
        return max(matches)

    def latest_journal_entry(message, unit):
        entries = [
            json.loads(line)
            for line in tlp.succeed(
                "journalctl -b -u " + unit + " -o json --no-pager"
            ).splitlines()
            if line
        ]
        matches = [
            entry for entry in entries
            if message in entry.get("MESSAGE", "")
        ]
        assert matches, (message, unit)
        return max(
            matches, key=lambda entry: int(entry["__MONOTONIC_TIMESTAMP"])
        )

    # The derived test package must retain both pinned vendor unit files byte
    # for byte after normalizing only their immutable output path.
    tlp.succeed(
        "sed 's#${fakeTlpPackage}#@TLP@#g' ${fakeTlpPackage}/lib/systemd/system/tlp.service "
        "> " + tlp_root + "/fixture-tlp.service; "
        "sed 's#${pkgs.tlp}#@TLP@#g' ${pkgs.tlp}/lib/systemd/system/tlp.service "
        "> " + tlp_root + "/vendor-tlp.service; "
        "cmp -s " + tlp_root + "/fixture-tlp.service " + tlp_root + "/vendor-tlp.service; "
        "sed 's#${fakeTlpPackage}#@TLP@#g' ${fakeTlpPackage}/lib/systemd/system/tlp-sleep.service "
        "> " + tlp_root + "/fixture-tlp-sleep.service; "
        "sed 's#${pkgs.tlp}#@TLP@#g' ${pkgs.tlp}/lib/systemd/system/tlp-sleep.service "
        "> " + tlp_root + "/vendor-tlp-sleep.service; "
        "cmp -s " + tlp_root + "/fixture-tlp-sleep.service " + tlp_root + "/vendor-tlp-sleep.service"
    )

    # Check both status and diagnostics from pinned systemd's complete unit
    # search path. A status-zero cycle diagnostic is still a fixture failure.
    verify_status, verify_output = tlp.execute(
        "LC_ALL=C SYSTEMD_COLORS=0 systemd-analyze verify multi-user.target 2>&1"
    )
    assert verify_status == 0, verify_output
    assert cycle_diagnostic.search(verify_output) is None, verify_output
    boot_journal_text = tlp.succeed("journalctl -b -o cat --no-pager")
    assert cycle_diagnostic.search(boot_journal_text) is None, boot_journal_text

    tlp_effective = tlp_show(
        "tlp.service",
        ["Wants", "Requires", "After", "Type", "RemainAfterExit", "Result", "InvocationID"],
    )
    wants_match = re.search(r"^Wants=(.*)$", tlp_effective, re.MULTILINE)
    assert wants_match is not None
    assert "bluetooth-rfkill-unblock.service" in wants_match.group(1).split()
    after_match = re.search(r"^After=(.*)$", tlp_effective, re.MULTILINE)
    assert after_match is not None
    tlp_after = after_match.group(1).split()
    assert "multi-user.target" in tlp_after
    assert "NetworkManager.service" in tlp_after
    assert "bluetooth-predeploy-init.service" in tlp_after
    assert "Type=oneshot" in tlp_effective
    assert "RemainAfterExit=yes" in tlp_effective
    assert tlp.succeed("systemctl is-enabled tlp.service").strip() == "enabled"
    tlp.succeed(
        "test ! -e /etc/systemd/system/multi-user.target.wants/bluetooth-rfkill-unblock.service"
    )
    base_effective = tlp_show(
        "bluetooth-rfkill-unblock.service", ["After", "ExecStart"]
    )
    base_after_match = re.search(r"^After=(.*)$", base_effective, re.MULTILINE)
    assert base_after_match is not None
    assert "tlp.service" in base_after_match.group(1).split()
    assert "${testFinalizer}" in base_effective

    template_unit = "bluetooth-rfkill-unblock@probe.service"
    template_effective = tlp_show(template_unit, ["After", "ExecStart", "Environment"])
    malicious_effective = tlp_show(
        "bluetooth-rfkill-unblock@malicious-instance.service",
        ["ExecStart", "Environment"],
    )
    template_after_match = re.search(
        r"^After=(.*)$", template_effective, re.MULTILINE
    )
    assert template_after_match is not None
    assert "tlp.service" in template_after_match.group(1).split()
    for effective in (template_effective, malicious_effective):
        exec_match = re.search(r"^ExecStart=(.*)$", effective, re.MULTILINE)
        assert exec_match is not None
        exec_line = exec_match.group(1)
        assert "path=${testFinalizer}" in exec_line
        assert "argv[]=${testFinalizer}" in exec_line
        assert "%i" not in exec_line.lower()
        assert "%I" not in exec_line
        assert "malicious-instance" not in exec_line
    udev_rule = tlp.succeed(
        "grep -R -F 'ACTION==\"add\", SUBSYSTEM==\"rfkill\", ATTR{type}==\"bluetooth\", "
        "TAG+=\"systemd\", ENV{SYSTEMD_WANTS}+=\"bluetooth-rfkill-unblock@%k.service\"' "
        "/etc/udev/rules.d"
    )
    assert udev_rule.count("bluetooth-rfkill-unblock@%k.service") == 1

    post_resume_unit = tlp.succeed("systemctl cat post-resume.service")
    resume_command = "${pkgs.systemd}/bin/systemctl --no-block restart bluetooth-rfkill-unblock.service"
    post_resume_exec = tlp_show("post-resume.service", ["ExecStart"])
    post_resume_path_match = re.search(r"path=([^ ;]+)", post_resume_exec)
    assert post_resume_path_match is not None
    post_resume_script = tlp.succeed("cat " + post_resume_path_match.group(1))
    assert post_resume_script.count(resume_command) == 1
    assert post_resume_script.index(resume_command) < post_resume_script.index("${postResumeProbe}")
    tlp_sleep_unit = tlp.succeed("systemctl cat tlp-sleep.service")
    assert "ExecStop=${fakeTlpPackage}/sbin/tlp resume" in tlp_sleep_unit
    assert "bluetooth-rfkill-unblock" not in tlp_sleep_unit

    masked_service = tlp_show("systemd-rfkill.service", ["LoadState", "ActiveState", "InvocationID"])
    masked_socket = tlp_show("systemd-rfkill.socket", ["LoadState", "ActiveState", "InvocationID"])
    assert "LoadState=masked" in masked_service and "ActiveState=inactive" in masked_service
    assert "LoadState=masked" in masked_socket and "ActiveState=inactive" in masked_socket
    assert not re.search(r"InvocationID=[0-9a-f]", masked_service + masked_socket)

    boot_show = tlp_show(
        "bluetooth-rfkill-unblock.service",
        ["Result", "ActiveState", "InvocationID"],
    )
    boot_id = invocation_id(boot_show)
    assert "Result=success" in boot_show and "ActiveState=inactive" in boot_show
    tlp_boot_id = invocation_id(tlp_effective)
    assert "Result=success" in tlp_effective
    assert tlp_boot_id != boot_id
    assert tlp.succeed("cat " + tlp_rfroot + "/sys/class/rfkill/rfkill1/soft") == "0\n"
    boot_journal = tlp.succeed(
        "journalctl _SYSTEMD_INVOCATION_ID=" + boot_id + " -o cat --no-pager"
    )
    assert "result=unblocked" in boot_journal
    tlp_init_end = journal_timestamp(
        "tlp-fixture phase=init-end result=success", "tlp.service", tlp_boot_id
    )
    helper_after_tlp_boot = journal_timestamp(
        "bluetooth-rfkill-finalize:",
        "bluetooth-rfkill-unblock.service",
        boot_id,
    )
    assert helper_after_tlp_boot > tlp_init_end

    tlp_wlan_live = tlp.succeed("cat " + tlp_rfroot + "/sys/class/rfkill/rfkill0/soft")
    tlp_wlan_live_hash = tlp.succeed(
        "sha256sum " + tlp_rfroot + "/sys/class/rfkill/rfkill0/soft | cut -d' ' -f1"
    ).strip()
    tlp_wlan_hard_hash = tlp.succeed(
        "sha256sum " + tlp_rfroot + "/sys/class/rfkill/rfkill0/hard | cut -d' ' -f1"
    ).strip()
    tlp_wlan_persisted = tlp.succeed(
        "sha256sum " + tlp_rfroot + "/persisted-wlan | cut -d' ' -f1"
    ).strip()
    tlp_state_hash = tlp.succeed(
        "sha256sum " + tlp_root + "/tlp-state | cut -d' ' -f1"
    ).strip()
    tlp_config_hash = tlp.succeed(
        "sha256sum /etc/tlp.conf | cut -d' ' -f1"
    ).strip()
    tlp.succeed(
        "cp " + tlp_rfroot + "/sys/class/rfkill/rfkill0/soft " + tlp_root + "/wlan-live.before; "
        "cp " + tlp_rfroot + "/sys/class/rfkill/rfkill0/hard " + tlp_root + "/wlan-hard.before; "
        "cp " + tlp_rfroot + "/persisted-wlan " + tlp_root + "/wlan-persisted.before; "
        "cp " + tlp_root + "/tlp-state " + tlp_root + "/tlp-state.before; "
        "cp /etc/tlp.conf " + tlp_root + "/tlp.conf.before"
    )

    # Weak Wants keeps the TLP and helper results independent. The helper must
    # still run after both a non-zero TLP init and a manager timeout.
    def run_tlp_init_variant(mode, expected_result, phase, previous_helper):
        tlp.succeed(
            "systemctl stop tlp.service; "
            "systemctl reset-failed tlp.service bluetooth-rfkill-unblock.service; "
            "printf '%s\\n' " + shlex.quote(mode) + " > " + tlp_root + "/tlp-init-mode"
        )
        if mode == "timeout":
            tlp.succeed(
                "mkdir -p /run/systemd/system/tlp.service.d; "
                "printf '[Service]\\nTimeoutStartSec=2s\\n' "
                "> /run/systemd/system/tlp.service.d/fixture-timeout.conf; "
                "systemctl daemon-reload"
            )
        status, output = tlp.execute("systemctl start tlp.service 2>&1")
        assert status != 0, output
        helper_id = wait_new_helper(previous_helper)
        show = tlp_show(
            "tlp.service", ["Result", "ActiveState", "InvocationID"]
        )
        tlp_id = invocation_id(show)
        assert "Result=" + expected_result in show
        assert "ActiveState=failed" in show
        tlp_end = journal_timestamp(phase, "tlp.service", tlp_id)
        helper_start = journal_timestamp(
            "bluetooth-rfkill-finalize:",
            "bluetooth-rfkill-unblock.service",
            helper_id,
        )
        assert helper_start > tlp_end
        assert tlp.succeed(
            "cat " + tlp_rfroot + "/sys/class/rfkill/rfkill1/soft"
        ) == "0\n"
        if mode == "timeout":
            tlp.succeed(
                "rm /run/systemd/system/tlp.service.d/fixture-timeout.conf; "
                "systemctl daemon-reload"
            )
        return tlp_id, helper_id

    tlp_failure_id, helper_after_tlp_failure = run_tlp_init_variant(
        "failure", "exit-code", "tlp-fixture phase=init-failure-end", boot_id
    )
    tlp_timeout_id, helper_after_tlp_timeout = run_tlp_init_variant(
        "timeout", "timeout", "tlp-fixture phase=init-timeout-end", helper_after_tlp_failure
    )
    tlp.succeed(
        "systemctl reset-failed tlp.service; "
        "printf 'normal\\n' > " + tlp_root + "/tlp-init-mode; "
        "systemctl start tlp.service"
    )
    helper_after_tlp_restore = wait_new_helper(helper_after_tlp_timeout)
    restored_tlp_show = tlp_show(
        "tlp.service", ["Result", "ActiveState", "InvocationID"]
    )
    tlp_restore_id = invocation_id(restored_tlp_show)
    assert "Result=success" in restored_tlp_show and "ActiveState=active" in restored_tlp_show

    # TLP no-device and already-unblocked calls remain successful zero-write
    # invocations of the same immutable base helper.
    writes_before_noop = int(tlp.succeed(
        "wc -l < " + tlp_rfroot + "/rfkill-writes"
    ).strip())
    tlp.succeed("systemctl start bluetooth-rfkill-unblock.service")
    already_id = invocation_id(tlp_show(
        "bluetooth-rfkill-unblock.service", ["Result", "InvocationID"]
    ))
    assert already_id != helper_after_tlp_restore
    assert int(tlp.succeed(
        "wc -l < " + tlp_rfroot + "/rfkill-writes"
    ).strip()) == writes_before_noop
    tlp.succeed(
        "mv " + tlp_rfroot + "/sys/class/rfkill/rfkill1 " + tlp_root + "/rfkill1.hidden; "
        "systemctl start bluetooth-rfkill-unblock.service; "
        "mv " + tlp_root + "/rfkill1.hidden " + tlp_rfroot + "/sys/class/rfkill/rfkill1"
    )
    no_device_id = invocation_id(tlp_show(
        "bluetooth-rfkill-unblock.service", ["Result", "InvocationID"]
    ))
    assert no_device_id != already_id
    assert int(tlp.succeed(
        "wc -l < " + tlp_rfroot + "/rfkill-writes"
    ).strip()) == writes_before_noop

    # A real hci_vhci rfkill ADD must traverse the production udev rule into
    # a generated template helper, without changing the boot helper invocation.
    existing_rfkill = bluetooth_rfkill_names()
    tlp.succeed("printf '1\\n' > " + tlp_rfroot + "/sys/class/rfkill/rfkill1/soft")
    tlp.succeed(
        "systemd-run --quiet --no-block --unit=btvirt-add -- "
        "${bluezBtvirt}/bin/btvirt -l1"
    )
    tlp.wait_until_succeeds(
        "for f in /sys/class/rfkill/*/type; do [ -e $f ] && [ \"$(cat $f)\" = bluetooth ] && exit 0; done; exit 1"
    )
    tlp.succeed("udevadm settle")
    add_names = bluetooth_rfkill_names() - existing_rfkill
    assert len(add_names) == 1, add_names
    add_name = next(iter(add_names))
    add_unit = "bluetooth-rfkill-unblock@" + add_name + ".service"
    tlp.wait_until_succeeds(
        "test -n \"$(systemctl show -P InvocationID " + add_unit + ")\" "
        "&& test \"$(systemctl show -P ActiveState " + add_unit + ")\" = inactive"
    )
    add_show = tlp_show(add_unit, ["Result", "InvocationID"])
    add_id = invocation_id(add_show)
    assert "Result=success" in add_show
    assert invocation_id(tlp_show("bluetooth-rfkill-unblock.service", ["InvocationID"])) == no_device_id
    assert tlp.succeed("cat " + tlp_rfroot + "/sys/class/rfkill/rfkill1/soft") == "0\n"

    # Hold the base helper after its rfkill write. Two new hci_vhci devices
    # must produce two distinct template jobs while the base is activating.
    tlp.succeed(
        "rm -f " + tlp_rfroot + "/helper-held-* " + tlp_rfroot + "/release-helper; "
        "touch " + tlp_rfroot + "/hold-helper-after-write; "
        "printf '1\\n' > " + tlp_rfroot + "/sys/class/rfkill/rfkill1/soft; "
        "systemctl restart --no-block bluetooth-rfkill-unblock.service"
    )
    tlp.wait_until_succeeds(
        "test \"$(systemctl show -P ActiveState bluetooth-rfkill-unblock.service)\" = activating "
        "&& test $(find " + tlp_rfroot + " -maxdepth 1 -name 'helper-held-*' | wc -l) -ge 1"
    )
    concurrent_base_id = invocation_id(tlp_show(
        "bluetooth-rfkill-unblock.service", ["ActiveState", "InvocationID"]
    ))
    tlp.succeed(
        "mkdir -p " + tlp_rfroot + "/sys/class/rfkill/rfkill2; "
        "printf 'bluetooth\\n' > " + tlp_rfroot + "/sys/class/rfkill/rfkill2/type; "
        "printf '1\\n' > " + tlp_rfroot + "/sys/class/rfkill/rfkill2/soft; "
        "printf '0\\n' > " + tlp_rfroot + "/sys/class/rfkill/rfkill2/hard"
    )
    existing_rfkill = bluetooth_rfkill_names()
    tlp.succeed(
        "systemd-run --quiet --no-block --unit=btvirt-concurrent-a -- "
        "${bluezBtvirt}/bin/btvirt -l1"
    )
    tlp.wait_until_succeeds(
        "test $(for f in /sys/class/rfkill/*/type; do [ -e $f ] && [ \"$(cat $f)\" = bluetooth ] && echo x; done | wc -l) -gt "
        + str(len(existing_rfkill))
    )
    tlp.succeed("udevadm settle")
    first_concurrent_names = bluetooth_rfkill_names() - existing_rfkill
    assert len(first_concurrent_names) == 1, first_concurrent_names
    first_concurrent_unit = (
        "bluetooth-rfkill-unblock@"
        + next(iter(first_concurrent_names))
        + ".service"
    )
    tlp.wait_until_succeeds(
        "test \"$(systemctl show -P ActiveState " + first_concurrent_unit + ")\" = activating "
        "&& test $(find " + tlp_rfroot + " -maxdepth 1 -name 'helper-held-*' | wc -l) -ge 2"
    )
    tlp.succeed(
        "mkdir -p " + tlp_rfroot + "/sys/class/rfkill/rfkill3; "
        "printf 'bluetooth\\n' > " + tlp_rfroot + "/sys/class/rfkill/rfkill3/type; "
        "printf '1\\n' > " + tlp_rfroot + "/sys/class/rfkill/rfkill3/soft; "
        "printf '0\\n' > " + tlp_rfroot + "/sys/class/rfkill/rfkill3/hard"
    )
    existing_rfkill = bluetooth_rfkill_names()
    tlp.succeed(
        "systemd-run --quiet --no-block --unit=btvirt-concurrent-b -- "
        "${bluezBtvirt}/bin/btvirt -l1"
    )
    tlp.wait_until_succeeds(
        "test $(for f in /sys/class/rfkill/*/type; do [ -e $f ] && [ \"$(cat $f)\" = bluetooth ] && echo x; done | wc -l) -gt "
        + str(len(existing_rfkill))
    )
    tlp.succeed("udevadm settle")
    second_concurrent_names = bluetooth_rfkill_names() - existing_rfkill
    assert len(second_concurrent_names) == 1, second_concurrent_names
    second_concurrent_unit = (
        "bluetooth-rfkill-unblock@"
        + next(iter(second_concurrent_names))
        + ".service"
    )
    concurrent_units = [first_concurrent_unit, second_concurrent_unit]
    tlp.wait_until_succeeds(
        "test \"$(systemctl show -P ActiveState " + concurrent_units[0] + ")\" = activating "
        "&& test \"$(systemctl show -P ActiveState " + concurrent_units[1] + ")\" = activating "
        "&& test $(find " + tlp_rfroot + " -maxdepth 1 -name 'helper-held-*' | wc -l) -ge 3"
    )
    concurrent_event_ids = [
        invocation_id(tlp_show(unit, ["ActiveState", "InvocationID"]))
        for unit in concurrent_units
    ]
    assert len({concurrent_base_id, *concurrent_event_ids}) == 3
    concurrent_jobs = tlp.succeed("systemctl list-jobs --no-legend")
    assert "bluetooth-rfkill-unblock.service" in concurrent_jobs
    assert all(unit in concurrent_jobs for unit in concurrent_units)
    concurrent_job_count = sum(
        1 for line in concurrent_jobs.splitlines()
        if "bluetooth-rfkill-unblock" in line
    )
    assert concurrent_job_count == 3, concurrent_jobs
    tlp.succeed("touch " + tlp_rfroot + "/release-helper")
    tlp.wait_until_succeeds(
        "test \"$(systemctl show -P ActiveState bluetooth-rfkill-unblock.service)\" = inactive "
        "&& test \"$(systemctl show -P ActiveState " + concurrent_units[0] + ")\" = inactive "
        "&& test \"$(systemctl show -P ActiveState " + concurrent_units[1] + ")\" = inactive"
    )
    tlp.succeed(
        "rm -f " + tlp_rfroot + "/hold-helper-after-write "
        + tlp_rfroot + "/release-helper " + tlp_rfroot + "/helper-held-*"
    )
    assert tlp.succeed("cat " + tlp_rfroot + "/sys/class/rfkill/rfkill2/soft") == "0\n"
    assert tlp.succeed("cat " + tlp_rfroot + "/sys/class/rfkill/rfkill3/soft") == "0\n"

    # A failed production helper is visible to PID 1 and a later invocation
    # recovers without involving either masked stock unit.
    tlp.succeed(
        "systemctl reset-failed bluetooth-rfkill-unblock.service; "
        "printf 'command-failure\\n' > " + tlp_rfroot + "/finalizer-mode; "
        "printf '1\\n' > " + tlp_rfroot + "/sys/class/rfkill/rfkill1/soft"
    )
    tlp.fail("systemctl start bluetooth-rfkill-unblock.service")
    failed_show = tlp_show(
        "bluetooth-rfkill-unblock.service", ["Result", "ActiveState", "InvocationID"]
    )
    failure_id = invocation_id(failed_show)
    assert "Result=exit-code" in failed_show and "ActiveState=failed" in failed_show
    tlp.succeed(
        "systemctl reset-failed bluetooth-rfkill-unblock.service; "
        "printf 'normal\\n' > " + tlp_rfroot + "/finalizer-mode; "
        "systemctl start bluetooth-rfkill-unblock.service"
    )
    recovery_show = tlp_show(
        "bluetooth-rfkill-unblock.service", ["Result", "ActiveState", "InvocationID"]
    )
    recovery_id = invocation_id(recovery_show)
    assert recovery_id != failure_id and "Result=success" in recovery_show
    assert tlp.succeed("cat " + tlp_rfroot + "/sys/class/rfkill/rfkill1/soft") == "0\n"

    # Exercise the actual sleep.target -> systemd-suspend -> suspend.target ->
    # post-resume graph. Only systemd-sleep's executor is replaced; the test
    # never starts the helper directly for either resume variant.
    def monotonic_property(show_output, name):
        match = re.search(r"^" + re.escape(name) + r"=(\d+)$", show_output, re.MULTILINE)
        assert match is not None, show_output
        return int(match.group(1))

    def run_resume_variant(mode, expected_tlp_result, phase, previous_helper):
        tlp.succeed(
            "systemctl reset-failed bluetooth-rfkill-unblock.service; "
            "for unit in tlp-sleep.service systemd-suspend.service suspend.target "
            "post-resume.service post-resume.target; do "
            "systemctl reset-failed $unit 2>/dev/null || :; done; "
            "rm -f " + tlp_root + "/post-resume-held-* " + tlp_root + "/release-post-resume; "
            "touch " + tlp_root + "/hold-post-resume; "
            "printf '%s\\n' " + shlex.quote(mode) + " > " + tlp_root + "/tlp-resume-mode; "
            "systemctl start --no-block suspend.target"
        )
        tlp.wait_until_succeeds(
            "test $(find " + tlp_root + " -maxdepth 1 -name 'post-resume-held-*' | wc -l) -eq 1"
        )
        helper_id = wait_new_helper(previous_helper)
        phase_entry = latest_journal_entry(phase, "tlp-sleep.service")
        sleep_id = phase_entry.get("_SYSTEMD_INVOCATION_ID", "")
        assert re.fullmatch(r"[0-9a-f]{32}", sleep_id) is not None
        sleep_journal = tlp.succeed(
            "journalctl -b -u tlp-sleep.service -o cat --no-pager"
        )
        if expected_tlp_result == "success":
            assert "tlp-sleep.service: Deactivated successfully." in sleep_journal
        else:
            assert "tlp-sleep.service: Failed with result '" + expected_tlp_result + "'." in sleep_journal
        post_id = tlp.succeed(
            "basename " + tlp_root + "/post-resume-held-* | sed 's/^post-resume-held-//'"
        ).strip()
        assert re.fullmatch(r"[0-9a-f]{32}", post_id) is not None
        post_show = tlp_show(
            "post-resume.service",
            [
                "Result",
                "ActiveState",
                "InvocationID",
                "ExecMainStartTimestampMonotonic",
                "ExecMainExitTimestampMonotonic",
            ],
        )
        assert invocation_id(post_show) == post_id
        assert "ActiveState=activating" in post_show
        resume_end = int(phase_entry["__MONOTONIC_TIMESTAMP"])
        post_start = monotonic_property(post_show, "ExecMainStartTimestampMonotonic")
        helper_start = journal_timestamp(
            "bluetooth-rfkill-finalize:",
            "bluetooth-rfkill-unblock.service",
            helper_id,
        )
        probe_timestamp = journal_timestamp(
            "post-resume-fixture phase=trigger-held",
            "post-resume.service",
            post_id,
        )
        assert resume_end < helper_start, (resume_end, helper_start)
        assert resume_end < probe_timestamp, (resume_end, probe_timestamp)
        assert post_start <= probe_timestamp, (post_start, probe_timestamp)
        tlp.succeed("touch " + tlp_root + "/release-post-resume")
        tlp.wait_until_succeeds(
            "test \"$(systemctl show -P ActiveState suspend.target)\" = inactive "
            "&& test \"$(systemctl show -P ActiveState post-resume.service)\" = inactive"
        )
        tlp.succeed(
            "rm -f " + tlp_root + "/hold-post-resume "
            + tlp_root + "/release-post-resume " + tlp_root + "/post-resume-held-*"
        )
        assert tlp.succeed(
            "cat " + tlp_rfroot + "/sys/class/rfkill/rfkill1/soft"
        ) == "0\n"
        return sleep_id, post_id, helper_id, 0

    tlp_sleep_id, post_resume_id, resume_id, resume_status = run_resume_variant(
        "normal", "success", "tlp-fixture phase=resume-end", recovery_id
    )
    (
        failed_tlp_sleep_id,
        failed_post_resume_id,
        helper_after_resume_failure,
        failed_resume_status,
    ) = run_resume_variant(
        "failure",
        "exit-code",
        "tlp-fixture phase=resume-failure-end",
        resume_id,
    )
    tlp.succeed(
        "for type_file in " + tlp_rfroot + "/sys/class/rfkill/*/type; do "
        "[ -e $type_file ] || continue; [ \"$(cat $type_file)\" = bluetooth ] || continue; "
        "test \"$(cat $(dirname $type_file)/soft)\" = 0; done"
    )

    assert tlp.succeed("cat " + tlp_rfroot + "/sys/class/rfkill/rfkill0/soft") == tlp_wlan_live
    tlp.succeed(
        "cmp -s " + tlp_root + "/wlan-live.before "
        + tlp_rfroot + "/sys/class/rfkill/rfkill0/soft; "
        "cmp -s " + tlp_root + "/wlan-hard.before "
        + tlp_rfroot + "/sys/class/rfkill/rfkill0/hard; "
        "cmp -s " + tlp_root + "/wlan-persisted.before " + tlp_rfroot + "/persisted-wlan; "
        "cmp -s " + tlp_root + "/tlp-state.before " + tlp_root + "/tlp-state; "
        "cmp -s " + tlp_root + "/tlp.conf.before /etc/tlp.conf"
    )
    assert tlp.succeed(
        "sha256sum " + tlp_rfroot + "/sys/class/rfkill/rfkill0/soft | cut -d' ' -f1"
    ).strip() == tlp_wlan_live_hash
    assert tlp.succeed(
        "sha256sum " + tlp_rfroot + "/sys/class/rfkill/rfkill0/hard | cut -d' ' -f1"
    ).strip() == tlp_wlan_hard_hash
    assert tlp.succeed(
        "sha256sum " + tlp_rfroot + "/persisted-wlan | cut -d' ' -f1"
    ).strip() == tlp_wlan_persisted
    assert tlp.succeed(
        "sha256sum " + tlp_root + "/tlp-state | cut -d' ' -f1"
    ).strip() == tlp_state_hash
    assert tlp.succeed(
        "sha256sum /etc/tlp.conf | cut -d' ' -f1"
    ).strip() == tlp_config_hash
    stock_journal = [
        json.loads(line)
        for line in tlp.succeed(
            "journalctl -u systemd-rfkill.service -u systemd-rfkill.socket -o json --no-pager"
        ).splitlines()
        if line
    ]
    assert not any(entry.get("_SYSTEMD_INVOCATION_ID") for entry in stock_journal)
    final_mask = tlp_show(
        "systemd-rfkill.service", ["LoadState", "ActiveState", "InvocationID"]
    ) + tlp_show(
        "systemd-rfkill.socket", ["LoadState", "ActiveState", "InvocationID"]
    )
    assert final_mask.count("LoadState=masked") == 2
    assert not re.search(r"InvocationID=[0-9a-f]", final_mask)
    final_tlp_journal = tlp.succeed("journalctl -b -o cat --no-pager")
    assert cycle_diagnostic.search(final_tlp_journal) is None, final_tlp_journal

    success_results = sum(1 for entry in all_records if entry.get("phase") == "exec-stop-post-end" and entry.get("SERVICE_RESULT") == "success")
    exit_results = sum(1 for entry in all_records if entry.get("phase") == "exec-stop-post-end" and entry.get("SERVICE_RESULT") == "exit-code")
    print("real-systemd-rfkill invocations=%d service-results=success:%d,exit-code:%d finalizer-failures=1 wlan-delta=0 result=pass" % (len(all_ids), success_results, exit_results))
    print("real-systemd-rfkill invocation-ids=" + ",".join(sorted(all_ids)))
    print("rfkill-wlan live-sha256=%s persisted-sha256=%s" % (hashlib.sha256(wlan_live_before.encode()).hexdigest(), wlan_persisted_before))
    print("generated-auth-unit invocations=%s,%s interactions=7 ready=2 notify=0 qml-memory-delta=0 state-delta=0 result=pass" % (unit_invocation, restarted_invocation))
    print("caelestia-notifs memory-sha256=%s state-sha256=%s" % (memory_before, state_before))
    print("tlp-rfkill verify-status=%d boot=%s,%s init-failure=%s,%s init-timeout=%s,%s init-restore=%s,%s noop=%s,%s add=%s concurrent=%s,%s concurrent-jobs=%d helper-failure=%s recovery=%s resume=%s,%s,%s,status:%d resume-failure=%s,%s,%s,status:%d stock=masked wlan-delta=0 tlp-state-delta=0 result=pass" % (verify_status, tlp_boot_id, boot_id, tlp_failure_id, helper_after_tlp_failure, tlp_timeout_id, helper_after_tlp_timeout, tlp_restore_id, helper_after_tlp_restore, already_id, no_device_id, add_id, concurrent_base_id, ",".join(concurrent_event_ids), concurrent_job_count, failure_id, recovery_id, tlp_sleep_id, post_resume_id, resume_id, resume_status, failed_tlp_sleep_id, failed_post_resume_id, helper_after_resume_failure, failed_resume_status))
    print("tlp-rfkill wlan-live-sha256=%s wlan-hard-sha256=%s wlan-persisted-sha256=%s tlp-state-sha256=%s tlp-config-sha256=%s" % (tlp_wlan_live_hash, tlp_wlan_hard_hash, tlp_wlan_persisted, tlp_state_hash, tlp_config_hash))
  '';
}

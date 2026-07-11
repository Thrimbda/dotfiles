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
    phase="$1"
    printf 'tlp-fixture phase=%s\n' "$phase"
    if [ "$phase" = init ] || [ "$phase" = resume ]; then
      for type_file in "$rfkill"/sys/class/rfkill/*/type; do
        [ -e "$type_file" ] || continue
        IFS= read -r type < "$type_file" || continue
        [ "$type" = bluetooth ] || continue
        printf '1\n' > "''${type_file%/type}/soft"
      done
    fi
    if [ "$phase" = init ]; then
      printf 'tlp-fixture phase=init-end\n'
    fi
    if [ "$phase" = resume ]; then
      printf 'tlp-fixture phase=resume-end\n'
    fi
  '';
  fakeTlpPackage = pkgs.writeShellScriptBin "tlp" ''
    exec ${fakeTlp} "''${1:-init}"
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
      before = [
        "bluetooth-rfkill-unblock.service"
        "tlp.service"
      ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = initFixture;
        RemainAfterExit = true;
      };
    };

    systemd.services.tlp = {
      after = [ "bluetooth-predeploy-init.service" ];
      requires = [ "bluetooth-predeploy-init.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${fakeTlp} init";
      };
    };

    systemd.services.tlp-sleep = {
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${fakeTlp} suspend";
        ExecStop = "${fakeTlp} resume";
      };
      postStop = tlpProjection.tlpSleepPostStop;
    };

    systemd.services.bluetooth-rfkill-unblock =
      tlpProjection.bootHelperService
      // {
        after = (tlpProjection.bootHelperService.after or [ ])
          ++ [ "bluetooth-predeploy-init.service" ];
        requires = [ "bluetooth-predeploy-init.service" ];
      };

    systemd.services."bluetooth-rfkill-unblock@" =
      tlpProjection.eventHelperService
      // {
        after = (tlpProjection.eventHelperService.after or [ ])
          ++ [ "bluetooth-predeploy-init.service" ];
        requires = [ "bluetooth-predeploy-init.service" ];
      };

    services.udev.extraRules = tlpProjection.udevRule;
    powerManagement.resumeCommands = tlpProjection.resumeCommands;
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

    # Real PID 1 projection of the TLP branch: production-generated helper,
    # templated udev target, TLP post-stop resume hook, and stock unit masks.
    tlp.wait_for_unit("multi-user.target")
    tlp.wait_for_unit("bluetooth-predeploy-init.service")
    tlp.wait_for_unit("systemd-udevd.service")
    tlp_root = "/run/bluetooth-predeploy"
    tlp_rfroot = tlp_root + "/rfkill"

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
    assert tlp.succeed("cat " + tlp_rfroot + "/sys/class/rfkill/rfkill1/soft") == "0\n"
    boot_journal = tlp.succeed(
        "journalctl _SYSTEMD_INVOCATION_ID=" + boot_id + " -o cat --no-pager"
    )
    assert "result=unblocked" in boot_journal
    boot_order_journal = [
        json.loads(line)
        for line in tlp.succeed(
            "journalctl -u tlp.service -u bluetooth-rfkill-unblock.service -o json --no-pager"
        ).splitlines()
        if line
    ]
    tlp_init_end = max(
        int(entry["__MONOTONIC_TIMESTAMP"])
        for entry in boot_order_journal
        if entry.get("MESSAGE") == "tlp-fixture phase=init-end"
    )
    helper_after_tlp_boot = min(
        int(entry["__MONOTONIC_TIMESTAMP"])
        for entry in boot_order_journal
        if entry.get("_SYSTEMD_INVOCATION_ID") == boot_id
        and "bluetooth-rfkill-finalize:" in entry.get("MESSAGE", "")
    )
    assert helper_after_tlp_boot > tlp_init_end

    tlp_wlan_live = tlp.succeed("cat " + tlp_rfroot + "/sys/class/rfkill/rfkill0/soft")
    tlp_wlan_live_hash = tlp.succeed(
        "sha256sum " + tlp_rfroot + "/sys/class/rfkill/rfkill0/soft | cut -d' ' -f1"
    ).strip()
    tlp_wlan_persisted = tlp.succeed(
        "sha256sum " + tlp_rfroot + "/persisted-wlan | cut -d' ' -f1"
    ).strip()
    tlp_state_hash = tlp.succeed(
        "sha256sum " + tlp_root + "/tlp-state | cut -d' ' -f1"
    ).strip()
    tlp.succeed(
        "cp " + tlp_rfroot + "/sys/class/rfkill/rfkill0/soft " + tlp_root + "/wlan-live.before; "
        "cp " + tlp_rfroot + "/persisted-wlan " + tlp_root + "/wlan-persisted.before; "
        "cp " + tlp_root + "/tlp-state " + tlp_root + "/tlp-state.before"
    )

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
    assert invocation_id(tlp_show("bluetooth-rfkill-unblock.service", ["InvocationID"])) == boot_id
    assert tlp.succeed("cat " + tlp_rfroot + "/sys/class/rfkill/rfkill1/soft") == "0\n"

    # Hold the boot helper after its rfkill write. A second real ADD starts a
    # distinct production template job while the base oneshot is activating.
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
        "systemd-run --quiet --no-block --unit=btvirt-concurrent -- "
        "${bluezBtvirt}/bin/btvirt -l1"
    )
    tlp.wait_until_succeeds(
        "test $(for f in /sys/class/rfkill/*/type; do [ -e $f ] && [ \"$(cat $f)\" = bluetooth ] && echo x; done | wc -l) -gt "
        + str(len(existing_rfkill))
    )
    tlp.succeed("udevadm settle")
    concurrent_names = bluetooth_rfkill_names() - existing_rfkill
    assert len(concurrent_names) == 1, concurrent_names
    concurrent_name = next(iter(concurrent_names))
    concurrent_unit = "bluetooth-rfkill-unblock@" + concurrent_name + ".service"
    tlp.wait_until_succeeds(
        "test \"$(systemctl show -P ActiveState " + concurrent_unit + ")\" = activating "
        "&& test $(find " + tlp_rfroot + " -maxdepth 1 -name 'helper-held-*' | wc -l) -ge 2"
    )
    concurrent_event_id = invocation_id(tlp_show(
        concurrent_unit, ["ActiveState", "InvocationID"]
    ))
    concurrent_jobs = tlp.succeed("systemctl list-jobs --no-legend")
    assert "bluetooth-rfkill-unblock.service" in concurrent_jobs
    assert concurrent_unit in concurrent_jobs
    concurrent_job_count = sum(
        1 for line in concurrent_jobs.splitlines()
        if "bluetooth-rfkill-unblock" in line
    )
    assert concurrent_job_count == 2, concurrent_jobs
    tlp.succeed("touch " + tlp_rfroot + "/release-helper")
    tlp.wait_until_succeeds(
        "test \"$(systemctl show -P ActiveState bluetooth-rfkill-unblock.service)\" = inactive "
        "&& test \"$(systemctl show -P ActiveState " + concurrent_unit + ")\" = inactive"
    )
    tlp.succeed(
        "rm -f " + tlp_rfroot + "/hold-helper-after-write "
        + tlp_rfroot + "/release-helper " + tlp_rfroot + "/helper-held-*"
    )
    assert tlp.succeed("cat " + tlp_rfroot + "/sys/class/rfkill/rfkill2/soft") == "0\n"

    # A failed production helper is visible to PID 1 and a later invocation
    # recovers without involving either masked stock unit.
    tlp.succeed(
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

    # The production TLP post-stop hook queues the helper only after fake TLP's
    # resume action has completed and reintroduced Bluetooth soft blocks.
    tlp.succeed("systemctl start tlp-sleep.service")
    tlp_sleep_id = invocation_id(tlp_show(
        "tlp-sleep.service", ["ActiveState", "InvocationID"]
    ))
    tlp.succeed("systemctl stop tlp-sleep.service")
    tlp.wait_until_succeeds(
        "new=$(systemctl show -P InvocationID bluetooth-rfkill-unblock.service); "
        "test -n \"$new\" && test \"$new\" != " + recovery_id + " "
        "&& test \"$(systemctl show -P ActiveState bluetooth-rfkill-unblock.service)\" = inactive"
    )
    resume_show = tlp_show(
        "bluetooth-rfkill-unblock.service", ["Result", "ActiveState", "InvocationID"]
    )
    resume_id = invocation_id(resume_show)
    assert "Result=success" in resume_show
    resume_journal = [
        json.loads(line)
        for line in tlp.succeed(
            "journalctl -u tlp-sleep.service -u bluetooth-rfkill-unblock.service -o json --no-pager"
        ).splitlines()
        if line
    ]
    tlp_resume_end = max(
        int(entry["__MONOTONIC_TIMESTAMP"])
        for entry in resume_journal
        if entry.get("MESSAGE") == "tlp-fixture phase=resume-end"
    )
    helper_after_resume = min(
        int(entry["__MONOTONIC_TIMESTAMP"])
        for entry in resume_journal
        if entry.get("_SYSTEMD_INVOCATION_ID") == resume_id
        and "bluetooth-rfkill-finalize:" in entry.get("MESSAGE", "")
    )
    assert helper_after_resume > tlp_resume_end
    assert tlp.succeed("cat " + tlp_rfroot + "/sys/class/rfkill/rfkill1/soft") == "0\n"

    assert tlp.succeed("cat " + tlp_rfroot + "/sys/class/rfkill/rfkill0/soft") == tlp_wlan_live
    tlp.succeed(
        "cmp -s " + tlp_root + "/wlan-live.before "
        + tlp_rfroot + "/sys/class/rfkill/rfkill0/soft; "
        "cmp -s " + tlp_root + "/wlan-persisted.before " + tlp_rfroot + "/persisted-wlan; "
        "cmp -s " + tlp_root + "/tlp-state.before " + tlp_root + "/tlp-state"
    )
    assert tlp.succeed(
        "sha256sum " + tlp_rfroot + "/sys/class/rfkill/rfkill0/soft | cut -d' ' -f1"
    ).strip() == tlp_wlan_live_hash
    assert tlp.succeed(
        "sha256sum " + tlp_rfroot + "/persisted-wlan | cut -d' ' -f1"
    ).strip() == tlp_wlan_persisted
    assert tlp.succeed(
        "sha256sum " + tlp_root + "/tlp-state | cut -d' ' -f1"
    ).strip() == tlp_state_hash
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

    success_results = sum(1 for entry in all_records if entry.get("phase") == "exec-stop-post-end" and entry.get("SERVICE_RESULT") == "success")
    exit_results = sum(1 for entry in all_records if entry.get("phase") == "exec-stop-post-end" and entry.get("SERVICE_RESULT") == "exit-code")
    print("real-systemd-rfkill invocations=%d service-results=success:%d,exit-code:%d finalizer-failures=1 wlan-delta=0 result=pass" % (len(all_ids), success_results, exit_results))
    print("real-systemd-rfkill invocation-ids=" + ",".join(sorted(all_ids)))
    print("rfkill-wlan live-sha256=%s persisted-sha256=%s" % (hashlib.sha256(wlan_live_before.encode()).hexdigest(), wlan_persisted_before))
    print("generated-auth-unit invocations=%s,%s interactions=7 ready=2 notify=0 qml-memory-delta=0 state-delta=0 result=pass" % (unit_invocation, restarted_invocation))
    print("caelestia-notifs memory-sha256=%s state-sha256=%s" % (memory_before, state_before))
    print("tlp-rfkill boot=%s add=%s concurrent=%s,%s concurrent-jobs=%d failure=%s recovery=%s resume=%s tlp-sleep=%s stock=masked wlan-delta=0 tlp-state-delta=0 result=pass" % (boot_id, add_id, concurrent_base_id, concurrent_event_id, concurrent_job_count, failure_id, recovery_id, resume_id, tlp_sleep_id))
    print("tlp-rfkill wlan-live-sha256=%s wlan-persisted-sha256=%s tlp-state-sha256=%s" % (tlp_wlan_live_hash, tlp_wlan_persisted, tlp_state_hash))
  '';
}

#!/usr/bin/env python3
"""Socket-reactivation model exercising the production rfkill finalizer.

The build sandbox cannot run a nested PID1/cgroup manager, so this fixture uses
an isolated AF_UNIX systemd-rfkill.socket double. It preserves the relevant
single-unit rule: a queued activation cannot start until the current
InvocationID has completed ExecStopPost.
"""

import hashlib
import os
from pathlib import Path
import socket
import subprocess
import sys
import tempfile
import uuid


FINALIZER_SOURCE = Path(sys.argv[1]).read_text()
FAKE_RFKILL_SOURCE = Path(sys.argv[2]).read_text()


class IsolatedRfkillFixture:
    def __init__(self, root):
        self.root = Path(root)
        self.sysfs = self.root / "sys" / "class" / "rfkill"
        self.state = self.root / "var" / "lib" / "systemd" / "rfkill"
        self.socket_path = self.root / "run" / "systemd-rfkill.socket"
        self.write_log = self.root / "rfkill-writes"
        self.records = []
        self.sysfs.mkdir(parents=True)
        self.state.mkdir(parents=True)
        self.socket_path.parent.mkdir(parents=True)
        self.server = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
        self.server.bind(str(self.socket_path))
        self.server.setblocking(False)
        self.wlan_live = self.add_entry(0, "wlan", "WLAN-LIVE-SENTINEL", "0")
        self.wlan_persisted = self.state / "wlan-sentinel"
        self.wlan_persisted.write_bytes(b"WLAN-PERSISTED-UNIQUE\x00\xff\n")
        self.wlan_live_before = self.wlan_live.read_bytes()
        self.wlan_persisted_before = self.wlan_persisted.read_bytes()
        self.wlan_persisted_hash = hashlib.sha256(self.wlan_persisted_before).hexdigest()
        self.bluetooth_persisted = self.state / "bluetooth-sentinel"
        self.bluetooth_persisted.write_text("1\n")
        self.bluetooth_soft = None
        self.set_bluetooth("0")

    def close(self):
        self.server.close()

    def add_entry(self, index, radio_type, soft, hard):
        entry = self.sysfs / f"rfkill{index}"
        entry.mkdir(parents=True, exist_ok=True)
        (entry / "type").write_text(f"{radio_type}\n")
        (entry / "soft").write_text(f"{soft}\n")
        (entry / "hard").write_text(f"{hard}\n")
        return entry / "soft"

    def set_bluetooth(self, soft):
        entry = self.sysfs / "rfkill1"
        entry.mkdir(parents=True, exist_ok=True)
        (entry / "type").write_text("bluetooth\n")
        (entry / "soft").write_text(f"{soft}\n")
        (entry / "hard").write_text("0\n")
        self.bluetooth_soft = entry / "soft"

    def remove_bluetooth(self):
        entry = self.sysfs / "rfkill1"
        if entry.exists():
            for child in entry.iterdir():
                child.unlink()
            entry.rmdir()
        self.bluetooth_soft = None

    def build_finalizer(self, mode="unblock"):
        fake = self.root / f"rfkill-{mode}"
        fake.write_text(
            FAKE_RFKILL_SOURCE
            .replace("@rfkillSysfs@", str(self.sysfs))
            .replace("@writeLog@", str(self.write_log))
            .replace("@mode@", mode)
        )
        fake.chmod(0o755)
        finalizer = self.root / f"bluetooth-rfkill-finalize-{mode}"
        finalizer.write_text(
            FINALIZER_SOURCE
            .replace("@rfkillSysfs@", str(self.sysfs))
            .replace("@rfkillCommand@", str(fake))
        )
        finalizer.chmod(0o755)
        if "@rfkill" in finalizer.read_text() or "@mode@" in fake.read_text():
            raise AssertionError("fixture left a substitution placeholder")
        return finalizer

    def send_socket_event(self, event):
        client = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
        try:
            client.sendto(event.encode(), str(self.socket_path))
        finally:
            client.close()

    def queued_events(self):
        events = []
        while True:
            try:
                events.append(self.server.recv(128).decode())
            except BlockingIOError:
                return events

    def write_count(self):
        if not self.write_log.exists():
            return 0
        return len(self.write_log.read_text().splitlines())

    def record(self, invocation, phase, service_result="success", finalizer_result="pending"):
        self.records.append({
            "InvocationID": invocation,
            "phase": phase,
            "SERVICE_RESULT": service_result,
            "finalizer_result": finalizer_result,
        })

    def assert_wlan_unchanged(self):
        assert self.wlan_live.read_bytes() == self.wlan_live_before
        assert self.wlan_persisted.read_bytes() == self.wlan_persisted_before
        assert hashlib.sha256(self.wlan_persisted.read_bytes()).hexdigest() == self.wlan_persisted_hash

    def invoke(self, event, service_result="success", finalizer_mode="unblock",
               during_stop_post=None, reactivate_on_change=True):
        invocation = str(uuid.uuid4())
        self.record(invocation, "main-start", service_result)

        if event in ("ADD", "RESTART") and service_result != "start-failure":
            if self.bluetooth_soft is not None:
                self.bluetooth_soft.write_text(self.bluetooth_persisted.read_text())
        elif event == "CHANGE" and self.bluetooth_soft is not None:
            self.bluetooth_persisted.write_text(self.bluetooth_soft.read_text())

        self.record(invocation, "main-exit", service_result)
        self.record(invocation, "exec-stop-post-start", service_result)
        writes_before = self.write_count()
        completed = subprocess.run(
            [self.build_finalizer(finalizer_mode)],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False,
        )
        writes_after = self.write_count()
        if writes_after > writes_before and completed.returncode == 0 and reactivate_on_change:
            self.send_socket_event("CHANGE")
        if during_stop_post is not None:
            during_stop_post()
        finalizer_result = "success" if completed.returncode == 0 else "failed"
        self.record(invocation, "exec-stop-post-end", service_result, finalizer_result)
        self.assert_wlan_unchanged()

        if self.bluetooth_soft is not None and completed.returncode == 0:
            assert self.bluetooth_soft.read_text() == "0\n"
        phases = [record["phase"] for record in self.records if record["InvocationID"] == invocation]
        assert phases.count("exec-stop-post-start") == 1
        assert phases.count("exec-stop-post-end") == 1
        return invocation, completed.returncode

    def drain_reactivations(self, maximum=20):
        handled = 0
        while handled < maximum:
            events = self.queued_events()
            if not events:
                return
            for event in events:
                previous_end = len(self.records) - 1
                assert self.records[previous_end]["phase"] == "exec-stop-post-end"
                self.invoke(event)
                new_start = next(
                    index for index in range(previous_end + 1, len(self.records))
                    if self.records[index]["phase"] == "main-start"
                )
                assert new_start > previous_end
                handled += 1
        raise AssertionError("socket reactivation did not become quiet")


def assert_result_preserved(fixture, invocation, expected):
    results = {
        record["SERVICE_RESULT"]
        for record in fixture.records
        if record["InvocationID"] == invocation
    }
    assert results == {expected}


def run_scenarios():
    with tempfile.TemporaryDirectory() as temporary:
        fixture = IsolatedRfkillFixture(temporary)
        try:
            # Normal ADD restore -> finalizer -> CHANGE socket reactivation -> quiet.
            normal, result = fixture.invoke("ADD")
            assert result == 0
            fixture.drain_reactivations()
            assert fixture.bluetooth_soft.read_text() == "0\n"
            assert fixture.bluetooth_persisted.read_text() == "0\n"

            # Old invocation is in ExecStopPost when a held ADD reaches the socket.
            fixture.bluetooth_persisted.write_text("1\n")
            fixture.bluetooth_soft.write_text("0\n")
            old, result = fixture.invoke(
                "IDLE", during_stop_post=lambda: fixture.send_socket_event("ADD")
            )
            assert result == 0
            old_end = len(fixture.records) - 1
            fixture.drain_reactivations()
            next_start = next(
                index for index in range(old_end + 1, len(fixture.records))
                if fixture.records[index]["phase"] == "main-start"
            )
            assert fixture.records[old_end]["InvocationID"] == old
            assert next_start > old_end
            assert fixture.bluetooth_soft.read_text() == "0\n"
            assert fixture.bluetooth_persisted.read_text() == "0\n"

            # Explicit restart is queued behind the old invocation's finalizer.
            fixture.bluetooth_persisted.write_text("1\n")
            restart_old, result = fixture.invoke(
                "IDLE", during_stop_post=lambda: fixture.send_socket_event("RESTART")
            )
            assert result == 0
            restart_end = len(fixture.records) - 1
            fixture.drain_reactivations()
            assert fixture.records[restart_end]["InvocationID"] == restart_old
            assert fixture.bluetooth_soft.read_text() == "0\n"
            assert fixture.bluetooth_persisted.read_text() == "0\n"

            # Startup/runtime failures retain SERVICE_RESULT but still finalize.
            fixture.bluetooth_soft.write_text("1\n")
            startup, result = fixture.invoke("STARTUP", service_result="start-failure")
            assert result == 0
            assert_result_preserved(fixture, startup, "start-failure")
            fixture.drain_reactivations()

            fixture.bluetooth_persisted.write_text("1\n")
            runtime, result = fixture.invoke("ADD", service_result="runtime-failure")
            assert result == 0
            assert_result_preserved(fixture, runtime, "runtime-failure")
            fixture.drain_reactivations()

            # Shutdown runs one finalizer but the stopped socket does not reactivate.
            fixture.bluetooth_soft.write_text("1\n")
            shutdown, result = fixture.invoke(
                "SHUTDOWN", service_result="signal", reactivate_on_change=False
            )
            assert result == 0
            assert_result_preserved(fixture, shutdown, "signal")
            assert fixture.queued_events() == []

            # No device and already-unblocked paths are strict zero-write no-ops.
            fixture.remove_bluetooth()
            writes = fixture.write_count()
            _no_device, result = fixture.invoke("NO-DEVICE")
            assert result == 0 and fixture.write_count() == writes

            fixture.set_bluetooth("0")
            writes = fixture.write_count()
            _already, result = fixture.invoke("CHANGE")
            assert result == 0 and fixture.write_count() == writes

            # Repeated finite socket events serialize and eventually become quiet.
            fixture.bluetooth_persisted.write_text("1\n")
            fixture.send_socket_event("ADD")
            fixture.send_socket_event("CHANGE")
            fixture.send_socket_event("ADD")
            fixture.drain_reactivations()
            assert fixture.queued_events() == []
            assert fixture.bluetooth_soft.read_text() == "0\n"

            # A failed finalizer is visible and does not claim convergence.
            fixture.bluetooth_soft.write_text("1\n")
            failed, result = fixture.invoke(
                "FAILURE", finalizer_mode="verify-fail", reactivate_on_change=False
            )
            assert result != 0
            final = [record for record in fixture.records if record["InvocationID"] == failed][-1]
            assert final["finalizer_result"] == "failed"
            fixture.assert_wlan_unchanged()

            for invocation in {record["InvocationID"] for record in fixture.records}:
                phases = [
                    record["phase"] for record in fixture.records
                    if record["InvocationID"] == invocation
                ]
                assert phases.count("exec-stop-post-start") == 1
                assert phases.count("exec-stop-post-end") == 1
            print(f"isolated-systemd-rfkill: invocations={len(set(r['InvocationID'] for r in fixture.records))} result=pass")
        finally:
            fixture.close()


if __name__ == "__main__":
    run_scenarios()

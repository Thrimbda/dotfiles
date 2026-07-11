#!/usr/bin/env python3
"""Private-bus integration coverage for the production Blueman adapter seam."""

import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import select
import signal
import subprocess
import sys
import tempfile
import threading
import time
import unittest

import gi

gi.disable_legacy_autoinit()
gi.require_version("Gtk", "3.0")
from gi.repository import Gio, GLib, Gtk


RUNNER_PATH = Path(sys.argv.pop(1))
NOTIFS_QML_PATH = Path(sys.argv.pop(1))
INSTALLED_RUNNER_PATH = Path(sys.argv.pop(1))
DBUS_CONFIG_PATH = Path(sys.argv.pop(1))
spec = importlib.util.spec_from_file_location("blueman_auth_agent_integration_runner", RUNNER_PATH)
runner = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(runner)


AGENT_MANAGER_XML = """
<node>
  <interface name="org.bluez.AgentManager1">
    <method name="RegisterAgent">
      <arg name="agent" type="o" direction="in"/>
      <arg name="capability" type="s" direction="in"/>
    </method>
    <method name="RequestDefaultAgent">
      <arg name="agent" type="o" direction="in"/>
    </method>
    <method name="UnregisterAgent">
      <arg name="agent" type="o" direction="in"/>
    </method>
  </interface>
</node>
"""

DEVICE_XML = """
<node>
  <interface name="org.bluez.Device1">
    <property name="Alias" type="s" access="read"/>
    <property name="Address" type="s" access="read"/>
    <property name="Trusted" type="b" access="readwrite"/>
  </interface>
</node>
"""

NOTIFICATIONS_XML = """
<node>
  <interface name="org.freedesktop.Notifications">
    <method name="GetCapabilities"><arg type="as" direction="out"/></method>
    <method name="GetServerInformation">
      <arg type="s" direction="out"/><arg type="s" direction="out"/>
      <arg type="s" direction="out"/><arg type="s" direction="out"/>
    </method>
    <method name="Notify">
      <arg type="s" direction="in"/><arg type="u" direction="in"/>
      <arg type="s" direction="in"/><arg type="s" direction="in"/>
      <arg type="s" direction="in"/><arg type="as" direction="in"/>
      <arg type="a{sv}" direction="in"/><arg type="i" direction="in"/>
      <arg type="u" direction="out"/>
    </method>
    <method name="CloseNotification"><arg type="u" direction="in"/></method>
    <signal name="NotificationClosed"><arg type="u"/><arg type="u"/></signal>
    <signal name="ActionInvoked"><arg type="u"/><arg type="s"/></signal>
  </interface>
</node>
"""


def request_name(connection, name):
    reply = connection.call_sync(
        "org.freedesktop.DBus",
        "/org/freedesktop/DBus",
        "org.freedesktop.DBus",
        "RequestName",
        GLib.Variant("(su)", (name, 0)),
        GLib.VariantType.new("(u)"),
        Gio.DBusCallFlags.NONE,
        5_000,
        None,
    )
    if reply.unpack()[0] not in (1, 4):
        raise RuntimeError("failed to own private bus name")


class PrivateDBusDaemon:
    def __init__(self):
        self.process = None
        self.address = None

    def start(self):
        self.process = subprocess.Popen(
            [
                "dbus-daemon",
                f"--config-file={DBUS_CONFIG_PATH}",
                "--nofork",
                "--nopidfile",
                "--print-address=1",
            ],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        self.address = self.process.stdout.readline().strip()
        if not self.address or self.process.poll() is not None:
            error = self.process.stderr.read()
            self.stop()
            raise RuntimeError(f"private dbus-daemon failed: {error}")

    def stop(self):
        if self.process is None:
            return
        if self.process.poll() is None:
            self.process.terminate()
            try:
                self.process.wait(5)
            except subprocess.TimeoutExpired:
                self.process.kill()
                self.process.wait(5)
        if self.process.stdout is not None:
            self.process.stdout.close()
        if self.process.stderr is not None:
            self.process.stderr.close()


class PendingCall:
    def __init__(self):
        self.done = threading.Event()
        self.result = None
        self.error = None


class PrivateBusService:
    def __init__(self, address, name):
        self.address = address
        self.name = name
        self.context = None
        self.loop = None
        self.connection = None
        self.thread = None
        self.ready = threading.Event()
        self.start_error = None
        self.registration_ids = []

    def start(self):
        self.thread = threading.Thread(target=self._run, name=f"fixture-{self.name}", daemon=True)
        self.thread.start()
        if not self.ready.wait(10):
            raise TimeoutError(f"private service did not start: {self.name}")
        if self.start_error is not None:
            raise self.start_error

    def _run(self):
        self.context = GLib.MainContext.new()
        self.context.push_thread_default()
        try:
            flags = (
                Gio.DBusConnectionFlags.AUTHENTICATION_CLIENT
                | Gio.DBusConnectionFlags.MESSAGE_BUS_CONNECTION
            )
            self.connection = Gio.DBusConnection.new_for_address_sync(
                self.address, flags, None, None
            )
            self.register_objects()
            request_name(self.connection, self.name)
            self.loop = GLib.MainLoop.new(self.context, False)
            self.ready.set()
            self.loop.run()
        except BaseException as error:
            self.start_error = error
            self.ready.set()
        finally:
            if self.connection is not None:
                for registration_id in self.registration_ids:
                    try:
                        self.connection.unregister_object(registration_id)
                    except GLib.Error:
                        pass
                try:
                    self.connection.close_sync(None)
                except GLib.Error:
                    pass
            self.context.pop_thread_default()

    def register_objects(self):
        raise NotImplementedError

    def invoke(self, callback):
        source = GLib.idle_source_new()
        source.set_callback(callback)
        source.attach(self.context)

    def stop(self):
        if self.thread is None or not self.thread.is_alive():
            return

        def stop_in_context(*_args):
            if self.connection is not None:
                self.connection.close_sync(None)
            self.loop.quit()
            return GLib.SOURCE_REMOVE

        self.invoke(stop_in_context)
        self.thread.join(10)
        if self.thread.is_alive():
            raise TimeoutError(f"private service did not stop: {self.name}")


class FakeBluezService(PrivateBusService):
    DEVICE_PATH = "/org/bluez/hci0/dev_AA_BB_CC_DD_EE_FF"
    DEVICE_ADDRESS = "AA:BB:CC:DD:EE:FF"

    def __init__(self, address):
        super().__init__(address, "org.bluez")
        self.manager_calls = []
        self.agent_sender = None
        self.agent_path = None
        self.trusted = False
        self.lock = threading.Lock()

    def register_objects(self):
        manager_info = Gio.DBusNodeInfo.new_for_xml(AGENT_MANAGER_XML).interfaces[0]
        device_info = Gio.DBusNodeInfo.new_for_xml(DEVICE_XML).interfaces[0]
        self.registration_ids.append(self.connection.register_object(
            "/org/bluez", manager_info, self._manager_call, None, None
        ))
        self.registration_ids.append(self.connection.register_object(
            self.DEVICE_PATH, device_info, None, self._get_device_property,
            self._set_device_property
        ))

    def _manager_call(self, _connection, sender, _path, _interface, method,
                      parameters, invocation):
        values = parameters.unpack()
        with self.lock:
            self.manager_calls.append((method, sender, values))
            if method == "RegisterAgent":
                self.agent_sender = sender
                self.agent_path = values[0]
                if values[1] != "KeyboardDisplay":
                    invocation.return_dbus_error("org.bluez.Error.Rejected", "bad capability")
                    return
            elif values and values[0] != self.agent_path:
                invocation.return_dbus_error("org.bluez.Error.DoesNotExist", "wrong path")
                return
        invocation.return_value(None)

    def _get_device_property(self, _connection, _sender, _path, _interface, property_name):
        values = {
            "Alias": GLib.Variant("s", "Fixture Headset"),
            "Address": GLib.Variant("s", self.DEVICE_ADDRESS),
            "Trusted": GLib.Variant("b", self.trusted),
        }
        return values[property_name]

    def _set_device_property(self, _connection, _sender, _path, _interface,
                             property_name, value):
        if property_name != "Trusted":
            return False
        self.trusted = value.unpack()
        return True

    def call_agent(self, method, signature="()", values=(), reply_signature=None):
        pending = PendingCall()

        def call_in_context(*_args):
            reply_type = (
                GLib.VariantType.new(reply_signature)
                if reply_signature is not None else None
            )

            def call_finished(connection, result):
                try:
                    pending.result = connection.call_finish(result)
                except BaseException as error:
                    pending.error = error
                finally:
                    pending.done.set()

            self.connection.call(
                self.agent_sender,
                self.agent_path,
                "org.bluez.Agent1",
                method,
                GLib.Variant(signature, values) if signature != "()" else None,
                reply_type,
                Gio.DBusCallFlags.NONE,
                5_000,
                None,
                call_finished,
            )
            return GLib.SOURCE_REMOVE

        self.invoke(call_in_context)
        return pending

    def call_names(self):
        with self.lock:
            return [entry[0] for entry in self.manager_calls]


class FakeNotificationsService(PrivateBusService):
    def __init__(self, address, state_path):
        super().__init__(address, "org.freedesktop.Notifications")
        self.state_path = state_path
        self.method_calls = []
        self.notify_calls = []

    def register_objects(self):
        interface = Gio.DBusNodeInfo.new_for_xml(NOTIFICATIONS_XML).interfaces[0]
        self.registration_ids.append(self.connection.register_object(
            "/org/freedesktop/Notifications", interface, self._method_call, None, None
        ))

    def _method_call(self, _connection, _sender, _path, _interface, method,
                     parameters, invocation):
        self.method_calls.append(method)
        if method == "GetCapabilities":
            invocation.return_value(GLib.Variant("(as)", (["body", "actions"],)))
        elif method == "GetServerInformation":
            invocation.return_value(GLib.Variant("(ssss)", ("fixture", "fixture", "1", "1.2")))
        elif method == "Notify":
            values = parameters.unpack()
            self.notify_calls.append(values)
            current = json.loads(self.state_path.read_text())
            current.append({"summary": values[3], "body": values[4]})
            self.state_path.write_text(json.dumps(current, sort_keys=True) + "\n")
            invocation.return_value(GLib.Variant("(u)", (len(self.notify_calls),)))
        elif method == "CloseNotification":
            invocation.return_value(None)
        else:
            invocation.return_dbus_error("org.freedesktop.DBus.Error.UnknownMethod", "unknown")


def spin_until(predicate, timeout=8):
    context = GLib.MainContext.default()
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        while context.pending():
            context.iteration(False)
        if predicate():
            return
        time.sleep(0.01)
    raise TimeoutError("condition was not reached")


def wait_call(pending):
    spin_until(pending.done.is_set)
    if pending.error is not None:
        raise pending.error
    return pending.result


def find_entry(widget):
    if isinstance(widget, Gtk.Entry):
        return widget
    if hasattr(widget, "get_children"):
        for child in widget.get_children():
            found = find_entry(child)
            if found is not None:
                return found
    return None


def respond_to_action(dialog, action):
    for response_id, action_name in dialog.actions.items():
        if action_name == action:
            dialog.response(response_id)
            return
    raise AssertionError(f"missing local dialog action: {action}")


def assert_installed_runner_path_boundary():
    process = subprocess.Popen(
        [INSTALLED_RUNNER_PATH],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        env=os.environ.copy(),
    )
    captured_stderr = []
    try:
        deadline = time.monotonic() + 8
        while time.monotonic() < deadline and process.poll() is None:
            environ_path = Path(f"/proc/{process.pid}/environ")
            if environ_path.exists():
                environment = {}
                for entry in environ_path.read_bytes().split(b"\0"):
                    if b"=" in entry:
                        key, value = entry.split(b"=", 1)
                        environment[key.decode()] = value.decode()
                python_path = environment.get("PYTHONPATH", "").split(":")
                if any("blueman-2.4.6/lib/python" in entry for entry in python_path):
                    break
            time.sleep(0.02)
        else:
            stdout, stderr = process.communicate(timeout=1)
            raise AssertionError(f"installed runner did not remain healthy: {stdout}{stderr}")

        path_entries = [entry for entry in environment.get("PATH", "").split(":") if entry]
        assert not any("blueman-2.4.6/bin" in entry for entry in path_entries)
        assert not any(
            "blueman-2.4.6" in entry
            for entry in environment.get("XDG_DATA_DIRS", "").split(":")
        )
        stock_commands = (
            "blueman-applet", "blueman-manager", "blueman-tray",
            "blueman-adapters", "blueman-sendto", "blueman-services",
        )
        for command in stock_commands:
            assert not any(
                (Path(directory) / command).is_file()
                and os.access(Path(directory) / command, os.X_OK)
                for directory in path_entries
            ), f"stock command reachable through runner PATH: {command}"

        deadline = time.monotonic() + 8
        while time.monotonic() < deadline:
            if process.poll() is not None:
                break
            readable, _writable, _errors = select.select([process.stderr], [], [], 0.1)
            if not readable:
                continue
            line = process.stderr.readline()
            if not line:
                continue
            captured_stderr.append(line)
            if "event=bluez_owner result=absent" in line:
                break
        else:
            raise AssertionError("installed runner did not reach absent-owner state")
    finally:
        if process.poll() is None:
            process.send_signal(signal.SIGTERM)
        stdout, remaining_stderr = process.communicate(timeout=8)
    stderr = "".join(captured_stderr) + remaining_stderr
    assert process.returncode == 0, stdout + stderr
    assert "event=startup_check result=ok stage=runtime" in stderr
    assert "event=bluez_owner result=absent" in stderr


class AuthAgentPrivateBusIntegration(unittest.TestCase):
    def test_actual_adapter_lifecycle_and_pairing_privacy(self):
        notifs_qml = NOTIFS_QML_PATH.read_text()
        self.assertIn("notifs.json", notifs_qml)
        self.assertIn("notif.tracked = true", notifs_qml)

        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            runtime_dir = root / "runtime"
            state_dir = root / "state" / "caelestia"
            runtime_dir.mkdir(mode=0o700)
            state_dir.mkdir(parents=True)
            state_path = state_dir / "notifs.json"
            baseline = [{"id": 1, "summary": "baseline", "body": "unchanged"}]
            state_path.write_text(json.dumps(baseline, sort_keys=True) + "\n")
            baseline_bytes = state_path.read_bytes()
            baseline_hash = hashlib.sha256(baseline_bytes).hexdigest()

            old_environment = os.environ.copy()
            system_bus = PrivateDBusDaemon()
            session_bus = PrivateDBusDaemon()
            system_bus.start()
            session_bus.start()
            os.environ.update({
                "DBUS_SYSTEM_BUS_ADDRESS": system_bus.address,
                "DBUS_SESSION_BUS_ADDRESS": session_bus.address,
                "XDG_RUNTIME_DIR": str(runtime_dir),
                "XDG_STATE_HOME": str(root / "state"),
            })

            bluez = FakeBluezService(system_bus.address)
            notifications = FakeNotificationsService(session_bus.address, state_path)
            capture = io.StringIO()
            try:
                notifications.start()
                assert_installed_runner_path_boundary()
                bluez.start()
                runner.configure_logging(capture)
                runtime = runner.RuntimeChecks().run()
                adapter = runner.PrivateBluezAgentAdapter(runtime)
                loop = GLib.MainLoop()
                notices = []
                machine = runner.AgentStateMachine(
                    adapter,
                    adapter.system_connection,
                    Gio,
                    GLib,
                    loop,
                    lambda message: notices.append(message) is None,
                )
                machine.start()
                self.assertEqual(machine.state, "default")
                self.assertEqual(bluez.call_names()[:2], ["RegisterAgent", "RequestDefaultAgent"])
                self.assertTrue(all(
                    sender == adapter.system_connection.get_unique_name()
                    for _method, sender, _values in bluez.manager_calls
                ))
                self.assertEqual(bluez.agent_path, runner.AGENT_PATH)

                sentinels = [
                    "PIN2468", "135790", "654321", "123456", "456789",
                    FakeBluezService.DEVICE_ADDRESS, FakeBluezService.DEVICE_PATH,
                ]

                created = adapter.notification_factory.created_count
                pending = bluez.call_agent(
                    "RequestPinCode", "(o)", (bluez.DEVICE_PATH,), "(s)"
                )
                spin_until(lambda: adapter.agent.dialog is not None)
                entry = find_entry(adapter.agent.dialog)
                self.assertIsNotNone(entry)
                entry.set_text("PIN2468")
                adapter.agent.dialog.response(Gtk.ResponseType.ACCEPT)
                self.assertEqual(wait_call(pending).unpack(), ("PIN2468",))
                self.assertEqual(adapter.notification_factory.created_count, created + 1)
                adapter.close_ui()

                created = adapter.notification_factory.created_count
                pending = bluez.call_agent(
                    "RequestPasskey", "(o)", (bluez.DEVICE_PATH,), "(u)"
                )
                spin_until(lambda: adapter.agent.dialog is not None)
                entry = find_entry(adapter.agent.dialog)
                entry.set_text("135790")
                adapter.agent.dialog.response(Gtk.ResponseType.ACCEPT)
                self.assertEqual(wait_call(pending).unpack(), (135790,))
                self.assertEqual(adapter.notification_factory.created_count, created + 1)
                adapter.close_ui()

                created = adapter.notification_factory.created_count
                wait_call(bluez.call_agent(
                    "DisplayPinCode", "(os)", (bluez.DEVICE_PATH, "654321")
                ))
                self.assertEqual(adapter.notification_factory.created_count, created + 1)
                adapter.close_ui()

                created = adapter.notification_factory.created_count
                wait_call(bluez.call_agent(
                    "DisplayPasskey", "(ouq)", (bluez.DEVICE_PATH, 123456, 2)
                ))
                self.assertEqual(adapter.notification_factory.created_count, created + 1)
                adapter.close_ui()

                created = adapter.notification_factory.created_count
                pending = bluez.call_agent(
                    "RequestConfirmation", "(ou)", (bluez.DEVICE_PATH, 456789)
                )
                spin_until(lambda: adapter.notification_factory.created_count == created + 1)
                respond_to_action(adapter.notification_factory.dialogs[-1], "confirm")
                wait_call(pending)
                adapter.close_ui()

                created = adapter.notification_factory.created_count
                pending = bluez.call_agent(
                    "RequestAuthorization", "(o)", (bluez.DEVICE_PATH,)
                )
                spin_until(lambda: adapter.notification_factory.created_count == created + 1)
                respond_to_action(adapter.notification_factory.dialogs[-1], "confirm")
                wait_call(pending)
                adapter.close_ui()

                created = adapter.notification_factory.created_count
                pending = bluez.call_agent(
                    "AuthorizeService", "(os)",
                    (bluez.DEVICE_PATH, "0000110b-0000-1000-8000-00805f9b34fb"),
                )
                spin_until(lambda: adapter.notification_factory.created_count == created + 1)
                respond_to_action(adapter.notification_factory.dialogs[-1], "accept")
                wait_call(pending)
                adapter.close_ui()

                self.assertEqual(notifications.method_calls, [])
                self.assertEqual(notifications.notify_calls, [])
                self.assertEqual(state_path.read_bytes(), baseline_bytes)
                self.assertEqual(hashlib.sha256(state_path.read_bytes()).hexdigest(), baseline_hash)
                self.assertEqual(json.loads(state_path.read_text()), baseline)
                for sentinel in sentinels:
                    self.assertNotIn(sentinel, capture.getvalue())
                    self.assertNotIn(sentinel, state_path.read_text())

                old_owner = machine.owner
                vanished_service = bluez
                bluez.stop()
                spin_until(lambda: machine.state == "absent" and machine.owner is None)
                self.assertNotIn("UnregisterAgent", vanished_service.call_names())
                replacement = FakeBluezService(system_bus.address)
                replacement.start()
                bluez = replacement
                spin_until(lambda: machine.state == "default")
                self.assertNotEqual(machine.owner, old_owner)
                self.assertEqual(bluez.call_names()[:2], ["RegisterAgent", "RequestDefaultAgent"])
                self.assertTrue(all(
                    sender == adapter.system_connection.get_unique_name()
                    for _method, sender, _values in bluez.manager_calls
                ))

                runner.install_unix_signal_handlers(machine, GLib)
                os.kill(os.getpid(), signal.SIGTERM)
                spin_until(lambda: machine.stopped)
                self.assertEqual(machine.state, "absent")
                self.assertEqual(bluez.call_names()[-1], "UnregisterAgent")

                release_adapter = runner.PrivateBluezAgentAdapter(runtime)
                release_machine = runner.AgentStateMachine(
                    release_adapter,
                    release_adapter.system_connection,
                    Gio,
                    GLib,
                    GLib.MainLoop(),
                    lambda _message: True,
                )
                release_machine.start()
                self.assertEqual(release_machine.state, "default")
                unregisters_before = bluez.call_names().count("UnregisterAgent")
                wait_call(bluez.call_agent("Release"))
                self.assertTrue(release_machine.exit_requested)
                self.assertEqual(release_machine.state, "absent")
                self.assertEqual(
                    bluez.call_names().count("UnregisterAgent"), unregisters_before
                )
                release_machine.shutdown("test-exit")
                print(
                    "private-dbus-auth-agent: interactions=7 notify=0 "
                    "state-delta=0 path-boundary=pass result=pass"
                )
            finally:
                for window in Gtk.Window.list_toplevels():
                    window.destroy()
                bluez.stop()
                notifications.stop()
                os.environ.clear()
                os.environ.update(old_environment)
                session_bus.stop()
                system_bus.stop()


if __name__ == "__main__":
    unittest.main()

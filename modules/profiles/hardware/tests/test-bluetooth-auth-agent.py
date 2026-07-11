#!/usr/bin/env python3

import importlib.util
import inspect
import io
import logging
import os
from pathlib import Path
import sys
import tempfile
import types
import unittest


RUNNER_PATH = Path(sys.argv.pop(1))
spec = importlib.util.spec_from_file_location("blueman_auth_agent_runner", RUNNER_PATH)
runner = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(runner)


class NameHasNoOwner(Exception):
    pass


class FakeVariant:
    def __init__(self, _signature, value):
        self.value = value

    def unpack(self):
        return self.value


class FakeResult:
    def __init__(self, value=()):
        self.value = value

    def unpack(self):
        return self.value


class FakeGio:
    class DBusCallFlags:
        NONE = 0
        NO_AUTO_START = 1

    class DBusSignalFlags:
        NONE = 0

    class DBusError:
        @staticmethod
        def get_remote_error(error):
            if isinstance(error, NameHasNoOwner):
                return "org.freedesktop.DBus.Error.NameHasNoOwner"
            return None


class FakeGLib:
    Variant = FakeVariant


class FakeLoop:
    def __init__(self):
        self.quit_count = 0

    def quit(self):
        self.quit_count += 1


class FakeConnection:
    def __init__(self, owner=":1.10"):
        self.owner = owner
        self.fail_method = None
        self.calls = []
        self.events = []
        self.owner_query_count = 0
        self.fail_owner_queries = set()
        self.closed = False
        self.signal_callback = None
        self.closed_callback = None

    def call_sync(self, destination, path, interface, method, parameters,
                  _result_type, _flags, _timeout, _cancellable):
        unpacked = None if parameters is None else parameters.unpack()
        self.calls.append((method, destination, path, interface, unpacked, id(self)))
        if method == "GetNameOwner":
            self.owner_query_count += 1
            if self.owner_query_count in self.fail_owner_queries:
                raise RuntimeError("ordinary GetNameOwner failure")
            if self.owner is None:
                raise NameHasNoOwner()
            return FakeResult((self.owner,))
        if method == self.fail_method:
            raise RuntimeError("sentinel failure with 12:34:56:78:9A:BC")
        self.events.append(f"manager:{method}")
        return FakeResult()

    def signal_subscribe(self, _sender, _interface, _member, _path, _arg0, _flags, callback):
        self.signal_callback = callback
        return 41

    def signal_unsubscribe(self, _subscription_id):
        self.signal_callback = None

    def connect(self, signal_name, callback):
        assert signal_name == "closed"
        self.closed_callback = callback
        return 42

    def disconnect(self, _handler_id):
        self.closed_callback = None

    def is_closed(self):
        return self.closed

    def manager_methods(self):
        return [call[0] for call in self.calls if call[0] != "GetNameOwner"]


class FakeAdapter:
    def __init__(self, connection):
        self.system_connection = connection
        self.release_handler = None
        self.actions = []
        self.exported = False
        self.fail_export = False

    def set_release_handler(self, handler):
        self.release_handler = handler

    def export(self):
        self.actions.append("export")
        self.system_connection.events.append("local:export")
        if self.fail_export:
            raise RuntimeError("export failure")
        self.exported = True

    def unexport(self):
        self.actions.append("unexport")
        self.system_connection.events.append("local:unexport")
        self.exported = False

    def close_ui(self):
        self.actions.append("close-ui")
        self.system_connection.events.append("local:close-ui")

    def release(self):
        self.unexport()
        self.release_handler()


def make_machine(owner=":1.10"):
    connection = FakeConnection(owner)
    adapter = FakeAdapter(connection)
    loop = FakeLoop()
    notifications = []

    def notify(message):
        notifications.append(message)
        return True

    machine = runner.AgentStateMachine(
        adapter, connection, FakeGio, FakeGLib, loop, notify
    )
    return machine, adapter, connection, loop, notifications


class StateMachineTests(unittest.TestCase):
    def setUp(self):
        runner.configure_logging(io.StringIO())

    def test_normal_path_uses_one_connection_and_reaches_default(self):
        machine, adapter, connection, _loop, notifications = make_machine()
        machine.start()

        self.assertEqual(machine.state, "default")
        self.assertEqual(connection.manager_methods(), ["RegisterAgent", "RequestDefaultAgent"])
        self.assertTrue(all(call[-1] == id(connection) for call in connection.calls))
        self.assertEqual(adapter.actions, ["export"])
        self.assertEqual(notifications, ["READY=1\nSTATUS=default"])

        machine.shutdown("signal")
        self.assertEqual(connection.manager_methods()[-1], "UnregisterAgent")
        self.assertEqual(machine.state, "absent")

    def test_register_failure_only_unexports(self):
        machine, adapter, connection, _loop, _notifications = make_machine()
        connection.fail_method = "RegisterAgent"
        machine.start()

        self.assertTrue(machine.exit_requested)
        self.assertEqual(machine.state, "absent")
        self.assertNotIn("UnregisterAgent", connection.manager_methods())
        self.assertEqual(adapter.actions[-2:], ["close-ui", "unexport"])

    def test_export_failure_makes_no_remote_agent_calls(self):
        machine, adapter, connection, _loop, notifications = make_machine()
        adapter.fail_export = True
        machine.start()

        self.assertTrue(machine.exit_requested)
        self.assertEqual(machine.state, "absent")
        self.assertEqual(connection.manager_methods(), [])
        self.assertEqual(notifications, [])

    def test_default_failure_unregisters_before_local_unexport(self):
        machine, adapter, connection, _loop, _notifications = make_machine()
        connection.fail_method = "RequestDefaultAgent"
        machine.start()

        self.assertTrue(machine.exit_requested)
        self.assertEqual(
            connection.manager_methods(),
            ["RegisterAgent", "RequestDefaultAgent", "UnregisterAgent"],
        )
        self.assertEqual(adapter.actions[-2:], ["close-ui", "unexport"])

    def assert_owner_query_failure_exits(self, machine, adapter, loop):
        self.assertTrue(machine.exit_requested)
        self.assertEqual(machine.exit_code, 1)
        self.assertEqual(machine.state, "absent")
        self.assertIsNone(machine.owner)
        self.assertFalse(adapter.exported)
        self.assertEqual(adapter.actions[-2:], ["close-ui", "unexport"])
        self.assertGreaterEqual(loop.quit_count, 1)

    def assert_unregister_precedes_local_cleanup(self, connection):
        self.assertIn("manager:UnregisterAgent", connection.events)
        unregister = connection.events.index("manager:UnregisterAgent")
        self.assertLess(unregister, len(connection.events) - 2)
        self.assertEqual(
            connection.events[-2:], ["local:close-ui", "local:unexport"]
        )

    def test_owner_query_failure_after_register_reverses_registration_and_exits(self):
        machine, adapter, connection, loop, notifications = make_machine()
        connection.fail_owner_queries.add(3)
        machine.start()

        self.assert_owner_query_failure_exits(machine, adapter, loop)
        self.assertEqual(
            connection.manager_methods(), ["RegisterAgent", "UnregisterAgent"]
        )
        self.assert_unregister_precedes_local_cleanup(connection)
        self.assertEqual(notifications, [])

    def test_owner_query_failure_after_default_unregisters_and_exits(self):
        machine, adapter, connection, loop, notifications = make_machine()
        connection.fail_owner_queries.add(5)
        machine.start()

        self.assert_owner_query_failure_exits(machine, adapter, loop)
        self.assertEqual(
            connection.manager_methods(),
            ["RegisterAgent", "RequestDefaultAgent", "UnregisterAgent"],
        )
        self.assert_unregister_precedes_local_cleanup(connection)
        self.assertEqual(notifications, [])

    def test_owner_query_failure_in_release_cleans_locally_and_exits(self):
        machine, adapter, connection, loop, _notifications = make_machine()
        machine.start()
        connection.fail_owner_queries.add(connection.owner_query_count + 1)
        adapter.release()

        self.assert_owner_query_failure_exits(machine, adapter, loop)
        self.assertNotIn("UnregisterAgent", connection.manager_methods())

    def test_owner_query_failure_during_replacement_reverses_new_registration(self):
        machine, adapter, connection, loop, _notifications = make_machine()
        machine.start()
        old_owner = connection.owner
        connection.owner = ":1.12"
        connection.fail_owner_queries.add(connection.owner_query_count + 2)
        machine._on_name_owner_changed(
            None,
            "",
            "",
            "",
            "",
            FakeVariant("", (runner.BLUEZ_NAME, old_owner, connection.owner)),
        )

        self.assert_owner_query_failure_exits(machine, adapter, loop)
        self.assertEqual(
            connection.manager_methods(),
            [
                "RegisterAgent",
                "RequestDefaultAgent",
                "RegisterAgent",
                "UnregisterAgent",
            ],
        )
        self.assert_unregister_precedes_local_cleanup(connection)

    def test_initial_owner_query_failure_never_waits_in_absent(self):
        machine, adapter, connection, loop, _notifications = make_machine()
        connection.fail_owner_queries.add(1)
        machine.start()

        self.assert_owner_query_failure_exits(machine, adapter, loop)
        self.assertEqual(connection.manager_methods(), [])

    def test_name_vanish_and_reappear_do_not_unregister_dead_owner(self):
        machine, _adapter, connection, _loop, notifications = make_machine()
        machine.start()
        old_owner = connection.owner
        connection.owner = None
        machine._on_name_owner_changed(None, "", "", "", "", FakeVariant("", (runner.BLUEZ_NAME, old_owner, "")))

        self.assertEqual(machine.state, "absent")
        self.assertNotIn("UnregisterAgent", connection.manager_methods())

        connection.owner = ":1.11"
        machine._on_name_owner_changed(None, "", "", "", "", FakeVariant("", (runner.BLUEZ_NAME, "", connection.owner)))
        self.assertEqual(machine.state, "default")
        self.assertEqual(connection.manager_methods().count("RegisterAgent"), 2)
        self.assertEqual(len(notifications), 2)

    def test_owner_replacement_rebuilds_without_old_unregister(self):
        machine, _adapter, connection, _loop, _notifications = make_machine()
        machine.start()
        old_owner = connection.owner
        connection.owner = ":1.12"
        machine._on_name_owner_changed(None, "", "", "", "", FakeVariant("", (runner.BLUEZ_NAME, old_owner, connection.owner)))

        self.assertEqual(machine.state, "default")
        self.assertNotIn("UnregisterAgent", connection.manager_methods())
        self.assertEqual(connection.manager_methods().count("RegisterAgent"), 2)

    def test_release_never_unregisters_remotely(self):
        machine, adapter, connection, _loop, _notifications = make_machine()
        machine.start()
        adapter.release()

        self.assertTrue(machine.exit_requested)
        self.assertEqual(machine.state, "absent")
        self.assertNotIn("UnregisterAgent", connection.manager_methods())

    def test_connection_close_is_local_cleanup_and_failure(self):
        machine, _adapter, connection, _loop, _notifications = make_machine()
        machine.start()
        connection.closed = True
        machine._on_connection_closed()

        self.assertEqual(machine.exit_code, 1)
        self.assertEqual(machine.state, "absent")
        self.assertNotIn("UnregisterAgent", connection.manager_methods())

    def test_shutdown_is_idempotent_in_all_states(self):
        for state in runner.AgentStateMachine.STATES:
            with self.subTest(state=state):
                machine, _adapter, connection, _loop, _notifications = make_machine()
                machine.state = state
                machine.owner = connection.owner if state != "absent" else None
                machine.shutdown("signal")
                machine.shutdown("signal")
                expected = 1 if state in ("registered", "default") else 0
                self.assertEqual(connection.manager_methods().count("UnregisterAgent"), expected)
                self.assertEqual(machine.state, "absent")


class FakeDialog:
    instances = []

    def __init__(self, *args):
        self.args = args
        self.closed = False
        self.destroyed = False
        FakeDialog.instances.append(self)

    def connect(self, _signal, _callback):
        return 1

    def close(self):
        self.closed = True

    def destroy(self):
        self.destroyed = True


class PrivacyTests(unittest.TestCase):
    def test_local_factory_never_constructs_a_notification_proxy(self):
        FakeDialog.instances.clear()
        factory = runner.LocalNotificationFactory(FakeDialog)
        callback = object()
        dialog = factory(
            "Bluetooth", "PIN2468 for AA:BB:CC:DD:EE:FF", 0, False,
            [("confirm", "Confirm")], callback, "untrusted-icon", None,
        )

        self.assertIs(dialog, FakeDialog.instances[0])
        self.assertEqual(dialog.args[4], [("confirm", "Confirm")])
        self.assertIs(dialog.args[5], callback)
        self.assertEqual(dialog.args[6], "blueman")
        factory.close_all()
        self.assertTrue(dialog.closed)
        self.assertTrue(dialog.destroyed)

    def test_logs_redact_upstream_payload_and_runner_fields(self):
        capture = io.StringIO()
        runner.configure_logging(capture)
        logging.getLogger("blueman.upstream").warning(
            "PIN2468 /org/bluez/hci0/dev_AA_BB_CC_DD_EE_FF AA:BB:CC:DD:EE:FF 135790"
        )
        runner.log_event(
            logging.ERROR,
            "error",
            stage="privacy",
            type="AA:BB:CC:DD:EE:FF",
            result="failed",
        )
        output = capture.getvalue()
        for sentinel in (
            "PIN2468", "135790", "AA:BB:CC:DD:EE:FF",
            "/org/bluez/hci0/dev_AA_BB_CC_DD_EE_FF",
        ):
            self.assertNotIn(sentinel, output)
        self.assertNotIn("Traceback", output)

    def test_pinned_blueman_call_sites_share_the_local_factory_seam(self):
        try:
            import gi
        except ModuleNotFoundError:
            self.skipTest("PyGObject is provided by the Nix check")

        gi.disable_legacy_autoinit()
        from gi.repository import Gio
        from blueman import Constants
        from blueman.gui.Notification import _NotificationDialog
        from blueman.main.DbusService import DbusService
        import importlib

        module = importlib.import_module("blueman.main.applet.BluezAgent")
        self.assertEqual(Constants.VERSION, "2.4.6")
        self.assertTrue(hasattr(Gio.DBusError, "get_remote_error"))
        self.assertTrue(hasattr(Gio.DBusCallFlags, "NO_AUTO_START"))
        runner.RuntimeChecks._check_private_api(module, _NotificationDialog)
        self.assertIn("self._bus = Gio.bus_get_sync", inspect.getsource(DbusService.__init__))
        self.assertIn("self._bus.register_object", inspect.getsource(DbusService.register))
        self.assertIn("self._regid: Optional[int] = None", inspect.getsource(DbusService.__init__))
        source = inspect.getsource(module.BluezAgent)
        self.assertEqual(source.count("Notification("), 5)

        factory = runner.LocalNotificationFactory(FakeDialog)
        module.Notification = factory
        handlers = (
            module.BluezAgent.ask_passkey,
            module.BluezAgent._on_display_pin_code,
            module.BluezAgent._on_display_passkey,
            module.BluezAgent._on_request_confirmation,
            module.BluezAgent._on_authorize_service,
        )
        self.assertTrue(all(handler.__globals__["Notification"] is factory for handler in handlers))
        self.assertNotIn("blueman.main.Applet", sys.modules)
        self.assertFalse(any("PowerManager" in name or "KillSwitch" in name for name in sys.modules))


class RuntimeCheckTests(unittest.TestCase):
    def test_gtk_failure_performs_no_system_bus_action(self):
        bus_calls = []

        class FakeSchemaSource:
            @staticmethod
            def get_default():
                return None

            @staticmethod
            def new_from_directory(_path, _parent, _trusted):
                return FakeSchemaSource()

            def lookup(self, _schema, _recursive):
                return object()

        class FakeSessionConnection:
            @staticmethod
            def is_closed():
                return False

        class FakeRuntimeGio:
            class BusType:
                SESSION = "session"
                SYSTEM = "system"

            SettingsSchemaSource = FakeSchemaSource

            @staticmethod
            def bus_get_sync(bus_type, _cancellable):
                bus_calls.append(bus_type)
                return FakeSessionConnection()

        class FakeRuntimeGtk:
            @staticmethod
            def init_check(_arguments):
                return False, []

        fake_gi = types.ModuleType("gi")
        fake_repository = types.ModuleType("gi.repository")
        fake_repository.Gio = FakeRuntimeGio
        fake_repository.GLib = object()
        fake_repository.Gtk = FakeRuntimeGtk
        fake_gi.repository = fake_repository
        fake_gi.disable_legacy_autoinit = lambda: None
        fake_gi.require_version = lambda _name, _version: None

        saved_modules = {name: sys.modules.get(name) for name in ("gi", "gi.repository")}
        saved_environment = os.environ.copy()
        try:
            sys.modules["gi"] = fake_gi
            sys.modules["gi.repository"] = fake_repository
            with tempfile.TemporaryDirectory() as schema_dir:
                os.environ.update({
                    "XDG_RUNTIME_DIR": schema_dir,
                    "DBUS_SESSION_BUS_ADDRESS": "unix:path=/not-used",
                    "GSETTINGS_SCHEMA_DIR": schema_dir,
                    "WAYLAND_DISPLAY": "wayland-test",
                })
                with self.assertRaises(runner.StartupCheckError) as raised:
                    runner.RuntimeChecks().run()
                self.assertEqual(raised.exception.stage, "gtk")
                self.assertEqual(bus_calls, [FakeRuntimeGio.BusType.SESSION])
        finally:
            os.environ.clear()
            os.environ.update(saved_environment)
            for name, module in saved_modules.items():
                if module is None:
                    sys.modules.pop(name, None)
                else:
                    sys.modules[name] = module


if __name__ == "__main__":
    unittest.main()

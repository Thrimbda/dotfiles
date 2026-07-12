#!/usr/bin/env python3
"""Private Blueman Agent1 runner with no applet or management surfaces."""

from __future__ import annotations

import inspect
import logging
import os
import re
import signal
import socket
import sys
from typing import Any, Callable, Optional


AGENT_PATH = "/org/bluez/agent/blueman"
BLUEZ_NAME = "org.bluez"
DBUS_NAME = "org.freedesktop.DBus"
DBUS_PATH = "/org/freedesktop/DBus"
DBUS_INTERFACE = "org.freedesktop.DBus"
AGENT_MANAGER_PATH = "/org/bluez"
AGENT_MANAGER_INTERFACE = "org.bluez.AgentManager1"
CALL_TIMEOUT_MS = 5_000

LOGGER = logging.getLogger("blueman_auth_agent")
_SAFE_TOKEN = re.compile(r"^[A-Za-z][A-Za-z0-9_.-]*$")
_MAC = re.compile(r"(?i)(?:[0-9a-f]{2}:){5}[0-9a-f]{2}")
_OBJECT_PATH = re.compile(r"/org/bluez/(?:[A-Za-z0-9_]+/?)+")
_SECRET_NUMBER = re.compile(r"\b[0-9]{4,16}\b")


class _PrivacyFilter(logging.Filter):
    def __init__(self, upstream: bool) -> None:
        super().__init__()
        self.upstream = upstream

    def filter(self, record: logging.LogRecord) -> bool:
        if self.upstream:
            record.msg = "event=error stage=upstream result=filtered"
        else:
            message = record.getMessage()
            message = _MAC.sub("[redacted]", message)
            message = _OBJECT_PATH.sub("[redacted]", message)
            message = _SECRET_NUMBER.sub("[redacted]", message)
            record.msg = message

        record.args = ()
        record.exc_info = None
        record.exc_text = None
        record.stack_info = None
        return True


def configure_logging(stream: Any = None) -> None:
    formatter = logging.Formatter("%(levelname)s %(message)s")

    root = logging.getLogger()
    root.handlers.clear()
    root.setLevel(logging.WARNING)
    upstream_handler = logging.StreamHandler(stream)
    upstream_handler.setFormatter(formatter)
    upstream_handler.addFilter(_PrivacyFilter(upstream=True))
    root.addHandler(upstream_handler)

    LOGGER.handlers.clear()
    LOGGER.setLevel(logging.INFO)
    LOGGER.propagate = False
    runner_handler = logging.StreamHandler(stream)
    runner_handler.setFormatter(formatter)
    runner_handler.addFilter(_PrivacyFilter(upstream=False))
    LOGGER.addHandler(runner_handler)
    logging.captureWarnings(True)


def _safe_value(value: Any) -> str:
    if isinstance(value, bool):
        return "yes" if value else "no"
    if isinstance(value, int):
        return str(value)
    text = str(value)
    return text if _SAFE_TOKEN.fullmatch(text) else "redacted"


def log_event(level: int, event: str, **fields: Any) -> None:
    parts = [f"event={_safe_value(event)}"]
    parts.extend(f"{key}={_safe_value(value)}" for key, value in sorted(fields.items()))
    LOGGER.log(level, " ".join(parts))


class StartupCheckError(Exception):
    def __init__(self, stage: str, error_type: str = "CheckFailed") -> None:
        super().__init__(stage)
        self.stage = stage
        self.error_type = error_type


class OwnerChanged(Exception):
    pass


class OwnerQueryFailed(Exception):
    def __init__(self, error: BaseException) -> None:
        super().__init__("BlueZ owner query failed")
        self.error_type = error.__class__.__name__


class RuntimeContext:
    def __init__(self, gio: Any, glib: Any, gtk: Any, bluez_agent_module: Any,
                 dialog_class: Any, device_class: Any) -> None:
        self.Gio = gio
        self.GLib = glib
        self.Gtk = gtk
        self.bluez_agent_module = bluez_agent_module
        self.dialog_class = dialog_class
        self.device_class = device_class


class RuntimeChecks:
    REQUIRED_ENVIRONMENT = (
        "XDG_RUNTIME_DIR",
        "DBUS_SESSION_BUS_ADDRESS",
        "GSETTINGS_SCHEMA_DIR",
    )

    @staticmethod
    def _fail(stage: str, error: Optional[BaseException] = None) -> None:
        error_type = error.__class__.__name__ if error is not None else "CheckFailed"
        raise StartupCheckError(stage, error_type)

    def run(self) -> RuntimeContext:
        for name in self.REQUIRED_ENVIRONMENT:
            if not os.environ.get(name):
                self._fail("environment")
        if not (os.environ.get("WAYLAND_DISPLAY") or os.environ.get("DISPLAY")):
            self._fail("display")

        schema_dir = os.environ["GSETTINGS_SCHEMA_DIR"]
        if not os.path.isdir(schema_dir) or not os.access(schema_dir, os.R_OK):
            self._fail("schema")

        try:
            import gi

            gi.disable_legacy_autoinit()
            from gi.repository import Gio, GLib
        except BaseException as error:
            self._fail("gi", error)

        try:
            schema_source = Gio.SettingsSchemaSource.new_from_directory(
                schema_dir,
                Gio.SettingsSchemaSource.get_default(),
                False,
            )
            if schema_source.lookup("org.blueman.general", True) is None:
                self._fail("schema")
        except StartupCheckError:
            raise
        except BaseException as error:
            self._fail("schema", error)

        try:
            session_connection = Gio.bus_get_sync(Gio.BusType.SESSION, None)
            if session_connection is None or session_connection.is_closed():
                self._fail("session-bus")
        except StartupCheckError:
            raise
        except BaseException as error:
            self._fail("session-bus", error)

        try:
            gi.require_version("Gtk", "3.0")
            from gi.repository import Gtk

            initialized = Gtk.init_check([])[0]
            if not initialized:
                self._fail("gtk")
        except StartupCheckError:
            raise
        except BaseException as error:
            self._fail("gtk", error)

        try:
            import importlib
            from blueman import Constants
            from blueman.Functions import setup_icon_path
            from blueman.bluez.Device import Device
            from blueman.gui.Notification import _NotificationDialog

            bluez_agent_module = importlib.import_module("blueman.main.applet.BluezAgent")
            if Constants.VERSION != "2.4.6":
                self._fail("blueman-version")
            self._check_private_api(bluez_agent_module, _NotificationDialog)

            setup_icon_path()
            icon_theme = Gtk.IconTheme.get_default()
            if icon_theme is None or icon_theme.lookup_icon(
                "blueman", 16, Gtk.IconLookupFlags.USE_BUILTIN
            ) is None:
                self._fail("icon")
        except StartupCheckError:
            raise
        except BaseException as error:
            self._fail("blueman-import", error)

        return RuntimeContext(Gio, GLib, Gtk, bluez_agent_module, _NotificationDialog, Device)

    @staticmethod
    def _check_private_api(bluez_agent_module: Any, dialog_class: Any) -> None:
        expected_notification = [
            "summary", "message", "timeout", "transient", "actions",
            "actions_cb", "icon_name", "image_data",
        ]
        expected_dialog = [
            "self", "summary", "message", "_timeout", "_transient", "actions",
            "actions_cb", "icon_name", "image_data",
        ]
        if list(inspect.signature(bluez_agent_module.Notification).parameters) != expected_notification:
            raise StartupCheckError("blueman-api")
        if list(inspect.signature(dialog_class.__init__).parameters) != expected_dialog:
            raise StartupCheckError("blueman-api")

        agent_class = bluez_agent_module.BluezAgent
        if getattr(agent_class, "_BluezAgent__agent_path", None) != AGENT_PATH:
            raise StartupCheckError("blueman-api")
        required_methods = (
            "register", "unregister", "_on_release", "_on_request_pin_code",
            "_on_display_pin_code", "_on_request_passkey", "_on_display_passkey",
            "_on_request_confirmation", "_on_request_authorization",
            "_on_authorize_service", "_on_cancel",
        )
        if any(not hasattr(agent_class, method) for method in required_methods):
            raise StartupCheckError("blueman-api")


class LocalNotificationFactory:
    """Signature-compatible factory that can only create local GTK dialogs."""

    def __init__(self, dialog_class: Any) -> None:
        self.dialog_class = dialog_class
        self.dialogs: list[Any] = []
        self.created_count = 0

    def __call__(self, summary: str, message: str, timeout: int = -1,
                 transient: bool = False, actions: Any = None,
                 actions_cb: Any = None, icon_name: Any = None,
                 image_data: Any = None) -> Any:
        del icon_name
        dialog = self.dialog_class(
            summary, message, timeout, transient, actions, actions_cb, "blueman", image_data
        )
        self.created_count += 1
        self.dialogs.append(dialog)
        if hasattr(dialog, "connect"):
            dialog.connect("destroy", self._on_destroy)
        return dialog

    def _on_destroy(self, dialog: Any, *_args: Any) -> None:
        if dialog in self.dialogs:
            self.dialogs.remove(dialog)

    def close_all(self) -> None:
        for dialog in list(self.dialogs):
            try:
                dialog.close()
            except BaseException:
                pass
            try:
                dialog.destroy()
            except BaseException:
                pass
        self.dialogs.clear()


class PrivateBluezAgentAdapter:
    def __init__(self, runtime: RuntimeContext) -> None:
        self.runtime = runtime
        self.notification_factory = LocalNotificationFactory(runtime.dialog_class)
        runtime.bluez_agent_module.Notification = self.notification_factory
        self._release_handler: Callable[[], None] = lambda: None
        adapter = self
        base_agent = runtime.bluez_agent_module.BluezAgent

        class PrivateBluezAgent(base_agent):  # type: ignore[misc, valid-type]
            def _request(self, kind: str) -> None:
                log_event(logging.INFO, "request", kind=kind, result="received")

            def _on_release(self) -> None:
                self._request("Release")
                adapter.close_ui()
                self.unregister()
                adapter._release_handler()

            def _on_request_pin_code(self, *args: Any) -> Any:
                self._request("RequestPinCode")
                return super()._on_request_pin_code(*args)

            def _on_display_pin_code(self, *args: Any) -> Any:
                self._request("DisplayPinCode")
                return super()._on_display_pin_code(*args)

            def _on_request_passkey(self, *args: Any) -> Any:
                self._request("RequestPasskey")
                return super()._on_request_passkey(*args)

            def _on_display_passkey(self, *args: Any) -> Any:
                self._request("DisplayPasskey")
                return super()._on_display_passkey(*args)

            def _on_request_confirmation(self, *args: Any) -> Any:
                self._request("RequestConfirmation")
                return super()._on_request_confirmation(*args)

            def _on_request_authorization(self, *args: Any) -> Any:
                self._request("RequestAuthorization")
                return super()._on_request_authorization(*args)

            def _on_authorize_service(self, *args: Any) -> Any:
                self._request("AuthorizeService")
                return super()._on_authorize_service(*args)

            def _on_cancel(self) -> Any:
                self._request("Cancel")
                return super()._on_cancel()

        self.agent = PrivateBluezAgent()
        if not hasattr(self.agent, "_bus") or not hasattr(self.agent, "_regid"):
            raise StartupCheckError("blueman-api")
        if self.agent._regid is not None:
            raise StartupCheckError("blueman-api")
        self.system_connection = self.agent._bus

    def set_release_handler(self, handler: Callable[[], None]) -> None:
        self._release_handler = handler

    def export(self) -> None:
        if self.agent._regid is not None:
            return
        self.agent.register()
        if self.agent._regid is None:
            raise RuntimeError("local export failed")

    def unexport(self) -> None:
        self.agent.unregister()

    def close_ui(self) -> None:
        dialog = getattr(self.agent, "dialog", None)
        if dialog is not None:
            try:
                dialog.destroy()
            except BaseException:
                pass
            self.agent.dialog = None

        notification = getattr(self.agent, "_notification", None)
        if notification is not None:
            try:
                notification.close()
            except BaseException:
                pass
            try:
                notification.destroy()
            except BaseException:
                pass
            self.agent._notification = None

        for notification in list(getattr(self.agent, "_service_notifications", [])):
            try:
                notification.close()
            except BaseException:
                pass
            try:
                notification.destroy()
            except BaseException:
                pass
        self.agent._service_notifications = []
        self.notification_factory.close_all()

        handlers = dict(getattr(self.agent, "_devhandlerids", {}))
        for object_path, handler_id in handlers.items():
            try:
                self.runtime.device_class(obj_path=object_path).disconnect_signal(handler_id)
            except BaseException:
                pass
        self.agent._devhandlerids = {}


class AgentStateMachine:
    STATES = ("absent", "exported", "registered", "default")

    def __init__(self, adapter: Any, connection: Any, gio: Any, glib: Any,
                 main_loop: Any, notifier: Callable[[str], bool]) -> None:
        if adapter.system_connection is not connection:
            raise ValueError("agent and state machine must share one connection")
        self.adapter = adapter
        self.connection = connection
        self.Gio = gio
        self.GLib = glib
        self.main_loop = main_loop
        self.notifier = notifier
        self.state = "absent"
        self.owner: Optional[str] = None
        self.subscription_id: Optional[int] = None
        self.closed_handler_id: Optional[int] = None
        self.exit_code = 0
        self.exit_requested = False
        self.stopped = False
        self.adapter.set_release_handler(self.on_release)

    def _variant(self, signature: str, value: Any) -> Any:
        return self.GLib.Variant(signature, value)

    def _is_name_absent(self, error: BaseException) -> bool:
        try:
            remote_name = self.Gio.DBusError.get_remote_error(error)
            return remote_name == "org.freedesktop.DBus.Error.NameHasNoOwner"
        except BaseException:
            return error.__class__.__name__ == "NameHasNoOwner"

    def _current_owner(self) -> Optional[str]:
        try:
            result = self.connection.call_sync(
                DBUS_NAME,
                DBUS_PATH,
                DBUS_INTERFACE,
                "GetNameOwner",
                self._variant("(s)", (BLUEZ_NAME,)),
                None,
                self.Gio.DBusCallFlags.NONE,
                CALL_TIMEOUT_MS,
                None,
            )
        except BaseException as error:
            if self._is_name_absent(error):
                return None
            raise OwnerQueryFailed(error) from None
        return result.unpack()[0]

    def _manager_call(self, method: str, expected_owner: str,
                      success_state: Optional[str] = None,
                      reason: str = "manager-call") -> None:
        if self._current_owner() != expected_owner:
            raise OwnerChanged()
        if method == "RegisterAgent":
            parameters = self._variant("(os)", (AGENT_PATH, "KeyboardDisplay"))
        else:
            parameters = self._variant("(o)", (AGENT_PATH,))
        self.connection.call_sync(
            BLUEZ_NAME,
            AGENT_MANAGER_PATH,
            AGENT_MANAGER_INTERFACE,
            method,
            parameters,
            None,
            self.Gio.DBusCallFlags.NO_AUTO_START,
            CALL_TIMEOUT_MS,
            None,
        )
        if success_state is not None:
            self._set_state(success_state, reason)
        if self._current_owner() != expected_owner:
            raise OwnerChanged()

    def _owner_query_failed(self, error: OwnerQueryFailed, reason: str,
                            cleanup_local: bool = True) -> None:
        log_event(
            logging.ERROR,
            "error",
            stage="owner-query",
            type=error.error_type,
            result="failed",
        )
        self.owner = None
        if cleanup_local:
            self._cleanup_local(reason)
        self.request_exit(1)

    def _set_state(self, state: str, reason: str) -> None:
        if state not in self.STATES:
            raise ValueError("invalid agent state")
        previous = self.state
        self.state = state
        if previous != state:
            log_event(
                logging.INFO,
                "state",
                **{"from": previous, "to": state, "reason": reason, "result": "ok"},
            )

    def start(self) -> None:
        self.subscription_id = self.connection.signal_subscribe(
            DBUS_NAME,
            DBUS_INTERFACE,
            "NameOwnerChanged",
            DBUS_PATH,
            BLUEZ_NAME,
            self.Gio.DBusSignalFlags.NONE,
            self._on_name_owner_changed,
        )
        self.closed_handler_id = self.connection.connect("closed", self._on_connection_closed)
        try:
            owner = self._current_owner()
        except OwnerQueryFailed as error:
            self._owner_query_failed(error, "owner-query-failed")
            return
        if owner is None:
            log_event(logging.INFO, "bluez_owner", result="absent")
            return
        self._activate(owner, "initial")

    def _activate(self, owner: str, reason: str) -> None:
        if self.exit_requested or self.stopped:
            return
        if self.owner == owner and self.state == "default":
            return
        if self.state != "absent":
            self._cleanup_local("owner-replaced")
        self.owner = owner
        log_event(logging.INFO, "bluez_owner", result="present")
        stage = "export"
        try:
            self.adapter.export()
            self._set_state("exported", reason)
            stage = "register"
            self._manager_call("RegisterAgent", owner, "registered", reason)
            stage = "default"
            self._manager_call("RequestDefaultAgent", owner, "default", reason)
            stage = "notify"
            if not self.notifier("READY=1\nSTATUS=default"):
                raise RuntimeError("notify failed")
        except OwnerChanged:
            self.owner = None
            self._cleanup_local("owner-changed")
            try:
                current = self._current_owner()
            except OwnerQueryFailed as error:
                self._owner_query_failed(error, "owner-query-failed", cleanup_local=False)
                return
            if current is not None:
                self._activate(current, "owner-replaced")
        except OwnerQueryFailed as error:
            self._cleanup_registered(owner, "activation-failed")
            self._owner_query_failed(error, "owner-query-failed", cleanup_local=False)
            log_event(
                logging.ERROR,
                "error",
                stage=stage,
                type=error.error_type,
                result="failed",
            )
        except BaseException as error:
            cleanup_error = self._cleanup_registered(owner, "activation-failed")
            if cleanup_error is not None:
                self._owner_query_failed(
                    cleanup_error, "owner-query-failed", cleanup_local=False
                )
                current = None
            else:
                try:
                    current = self._current_owner()
                except OwnerQueryFailed as owner_error:
                    self._owner_query_failed(
                        owner_error, "owner-query-failed", cleanup_local=False
                    )
                    current = None
            self.owner = current
            log_event(
                logging.ERROR,
                "error",
                stage=stage,
                type=error.__class__.__name__,
                result="failed",
            )
            if current is not None and not self.exit_requested:
                self.request_exit(1)

    def _cleanup_registered(self, expected_owner: str,
                            reason: str) -> Optional[OwnerQueryFailed]:
        owner_query_error = None
        if self.state in ("registered", "default"):
            try:
                if self._current_owner() == expected_owner:
                    self._manager_call("UnregisterAgent", expected_owner)
            except OwnerQueryFailed as error:
                owner_query_error = error
                log_event(
                    logging.ERROR,
                    "cleanup",
                    reason=reason,
                    stage="unregister",
                    type=error.error_type,
                    result="failed",
                )
            except BaseException as error:
                log_event(
                    logging.ERROR,
                    "cleanup",
                    reason=reason,
                    stage="unregister",
                    type=error.__class__.__name__,
                    result="failed",
                )
        self._cleanup_local(reason)
        return owner_query_error

    def _cleanup_local(self, reason: str) -> None:
        try:
            self.adapter.close_ui()
        except BaseException as error:
            log_event(
                logging.ERROR,
                "cleanup",
                reason=reason,
                stage="ui",
                type=error.__class__.__name__,
                result="failed",
            )
        try:
            self.adapter.unexport()
        except BaseException as error:
            log_event(
                logging.ERROR,
                "cleanup",
                reason=reason,
                stage="unexport",
                type=error.__class__.__name__,
                result="failed",
            )
        self._set_state("absent", reason)

    def _on_name_owner_changed(self, _connection: Any, _sender: str, _path: str,
                               _interface: str, _signal: str, parameters: Any) -> None:
        try:
            name, old_owner, new_owner = parameters.unpack()
            if name != BLUEZ_NAME or self.exit_requested or self.stopped:
                return
            if self.owner is not None and old_owner == self.owner:
                self.owner = None
                self._cleanup_local("owner-vanished")
                log_event(logging.INFO, "bluez_owner", result="absent")
            if new_owner:
                self._activate(new_owner, "owner-appeared")
        except BaseException as error:
            self._callback_failed("owner-signal", error)

    def on_release(self) -> None:
        try:
            self._set_state("absent", "release")
            current = self._current_owner()
            if current == self.owner and current is not None:
                log_event(logging.ERROR, "error", stage="release", type="UnexpectedRelease", result="failed")
                self.request_exit(1)
            else:
                self.owner = current
                if current is not None:
                    self._activate(current, "owner-replaced")
        except OwnerQueryFailed as error:
            self._owner_query_failed(error, "release-owner-query-failed")
        except BaseException as error:
            self._callback_failed("release", error)

    def _on_connection_closed(self, *_args: Any) -> None:
        try:
            self.owner = None
            self._cleanup_local("connection-closed")
            log_event(logging.ERROR, "error", stage="connection", type="Closed", result="failed")
            self.request_exit(1)
        except BaseException as error:
            self._callback_failed("connection", error)

    def _callback_failed(self, stage: str, error: BaseException) -> None:
        log_event(
            logging.ERROR,
            "error",
            stage=stage,
            type=error.__class__.__name__,
            result="failed",
        )
        self.owner = None
        self._cleanup_local("callback-failed")
        self.request_exit(1)

    def request_exit(self, code: int) -> None:
        self.exit_code = max(self.exit_code, code)
        self.exit_requested = True
        self.main_loop.quit()

    def shutdown(self, reason: str, code: int = 0) -> None:
        if self.stopped:
            self.request_exit(code)
            return
        self.stopped = True
        self.exit_code = max(self.exit_code, code)
        owner = self.owner
        if owner is not None:
            owner_query_error = self._cleanup_registered(owner, reason)
            if owner_query_error is not None:
                self._owner_query_failed(
                    owner_query_error, "owner-query-failed", cleanup_local=False
                )
        else:
            self._cleanup_local(reason)
        self.owner = None

        if self.subscription_id is not None and not self.connection.is_closed():
            try:
                self.connection.signal_unsubscribe(self.subscription_id)
            except BaseException:
                pass
            self.subscription_id = None
        if self.closed_handler_id is not None:
            try:
                self.connection.disconnect(self.closed_handler_id)
            except BaseException:
                pass
            self.closed_handler_id = None
        self.notifier("STOPPING=1\nSTATUS=stopped")
        self.request_exit(code)


def sd_notify(message: str) -> bool:
    notify_socket = os.environ.get("NOTIFY_SOCKET")
    if not notify_socket:
        return False
    address: Any = notify_socket
    if notify_socket.startswith("@"):
        address = "\0" + notify_socket[1:]
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM | socket.SOCK_CLOEXEC) as client:
            client.connect(address)
            client.sendall(message.encode("utf-8"))
        return True
    except BaseException as error:
        log_event(
            logging.ERROR,
            "error",
            stage="notify",
            type=error.__class__.__name__,
            result="failed",
        )
        return False


def install_unix_signal_handlers(machine: AgentStateMachine, glib: Any) -> list[int]:
    def on_signal(_signum: int) -> bool:
        machine.shutdown("signal", 0)
        return glib.SOURCE_REMOVE

    return [
        glib.unix_signal_add(glib.PRIORITY_DEFAULT, signal.SIGTERM, on_signal, signal.SIGTERM),
        glib.unix_signal_add(glib.PRIORITY_DEFAULT, signal.SIGINT, on_signal, signal.SIGINT),
    ]


def main() -> int:
    configure_logging()

    def report_uncaught(error_type: Any, stage: str) -> None:
        log_event(
            logging.ERROR,
            "error",
            stage=stage,
            type=getattr(error_type, "__name__", "Exception"),
            result="failed",
        )

    sys.excepthook = lambda error_type, _error, _traceback: report_uncaught(error_type, "uncaught")
    sys.unraisablehook = lambda unraisable: report_uncaught(unraisable.exc_type, "callback")

    try:
        runtime = RuntimeChecks().run()
        log_event(logging.INFO, "startup_check", stage="runtime", result="ok")
    except StartupCheckError as error:
        log_event(
            logging.ERROR,
            "startup_check",
            stage=error.stage,
            type=error.error_type,
            result="failed",
        )
        return 1
    except BaseException as error:
        log_event(
            logging.ERROR,
            "startup_check",
            stage="unexpected",
            type=error.__class__.__name__,
            result="failed",
        )
        return 1

    machine: Optional[AgentStateMachine] = None
    try:
        adapter = PrivateBluezAgentAdapter(runtime)
        main_loop = runtime.GLib.MainLoop()
        machine = AgentStateMachine(
            adapter,
            adapter.system_connection,
            runtime.Gio,
            runtime.GLib,
            main_loop,
            sd_notify,
        )

        install_unix_signal_handlers(machine, runtime.GLib)
        machine.start()
        if not machine.exit_requested:
            main_loop.run()
    except StartupCheckError as error:
        log_event(
            logging.ERROR,
            "startup_check",
            stage=error.stage,
            type=error.error_type,
            result="failed",
        )
        return 1
    except BaseException as error:
        log_event(
            logging.ERROR,
            "error",
            stage="main",
            type=error.__class__.__name__,
            result="failed",
        )
        if machine is not None:
            machine.exit_code = 1
    finally:
        if machine is not None and not machine.stopped:
            machine.shutdown("exit", machine.exit_code)

    return machine.exit_code if machine is not None else 1


if __name__ == "__main__":
    raise SystemExit(main())

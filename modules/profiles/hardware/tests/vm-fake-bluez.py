#!/usr/bin/env python3
"""Fake org.bluez service and Agent1 call controller for the NixOS VM test."""

import json
import os
from pathlib import Path
import signal
import socket
import threading

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib


ROOT = Path("/run/bluetooth-predeploy")
ADDRESS = "unix:path=/run/bluetooth-predeploy/system-bus"
CONTROL = ROOT / "bluez-control.sock"
AGENT_FILE = ROOT / "agent.json"
DEVICE_PATH = "/org/bluez/hci0/dev_AA_BB_CC_DD_EE_FF"
DEVICE_ADDRESS = "AA:BB:CC:DD:EE:FF"

MANAGER_XML = """
<node><interface name="org.bluez.AgentManager1">
  <method name="RegisterAgent"><arg type="o" direction="in"/><arg type="s" direction="in"/></method>
  <method name="RequestDefaultAgent"><arg type="o" direction="in"/></method>
  <method name="UnregisterAgent"><arg type="o" direction="in"/></method>
</interface></node>
"""

DEVICE_XML = """
<node><interface name="org.bluez.Device1">
  <property name="Alias" type="s" access="read"/>
  <property name="Address" type="s" access="read"/>
  <property name="Trusted" type="b" access="readwrite"/>
</interface></node>
"""


class FakeBluez:
    def __init__(self):
        flags = Gio.DBusConnectionFlags.AUTHENTICATION_CLIENT | Gio.DBusConnectionFlags.MESSAGE_BUS_CONNECTION
        self.connection = Gio.DBusConnection.new_for_address_sync(ADDRESS, flags, None, None)
        self.agent_sender = None
        self.agent_path = None
        self.trusted = False
        self.loop = GLib.MainLoop()
        self.connection.register_object(
            "/org/bluez",
            Gio.DBusNodeInfo.new_for_xml(MANAGER_XML).interfaces[0],
            self.manager_call,
            None,
            None,
        )
        self.connection.register_object(
            DEVICE_PATH,
            Gio.DBusNodeInfo.new_for_xml(DEVICE_XML).interfaces[0],
            None,
            self.get_property,
            self.set_property,
        )
        reply = self.connection.call_sync(
            "org.freedesktop.DBus",
            "/org/freedesktop/DBus",
            "org.freedesktop.DBus",
            "RequestName",
            GLib.Variant("(su)", ("org.bluez", 0)),
            GLib.VariantType.new("(u)"),
            Gio.DBusCallFlags.NONE,
            5_000,
            None,
        )
        if reply.unpack()[0] not in (1, 4):
            raise RuntimeError("unable to own org.bluez")

    def manager_call(self, _connection, sender, _path, _interface, method, parameters, invocation):
        values = parameters.unpack()
        if method == "RegisterAgent":
            if values[1] != "KeyboardDisplay":
                invocation.return_dbus_error("org.bluez.Error.Rejected", "bad capability")
                return
            self.agent_sender = sender
            self.agent_path = values[0]
            AGENT_FILE.write_text(json.dumps({"sender": sender, "path": values[0]}) + "\n")
            os.chmod(AGENT_FILE, 0o644)
        elif values and values[0] != self.agent_path:
            invocation.return_dbus_error("org.bluez.Error.DoesNotExist", "wrong path")
            return
        if method == "UnregisterAgent":
            AGENT_FILE.unlink(missing_ok=True)
        print(f"fake-bluez method={method} sender={sender}", flush=True)
        invocation.return_value(None)

    def get_property(self, _connection, _sender, _path, _interface, name):
        return {
            "Alias": GLib.Variant("s", "VM Fixture Headset"),
            "Address": GLib.Variant("s", DEVICE_ADDRESS),
            "Trusted": GLib.Variant("b", self.trusted),
        }[name]

    def set_property(self, _connection, _sender, _path, _interface, name, value):
        if name != "Trusted":
            return False
        self.trusted = value.unpack()
        return True

    def call_agent(self, command, client):
        method = command["method"]
        signature = command.get("signature", "()")
        values = tuple(command.get("values", []))
        reply_signature = command.get("reply_signature")

        def finished(connection, result):
            try:
                reply = connection.call_finish(result)
                payload = {"ok": True, "result": None if reply is None else reply.unpack()}
            except BaseException as error:
                payload = {"ok": False, "error": error.__class__.__name__}
            try:
                client.sendall((json.dumps(payload) + "\n").encode())
            finally:
                client.close()

        self.connection.call(
            self.agent_sender,
            self.agent_path,
            "org.bluez.Agent1",
            method,
            None if signature == "()" else GLib.Variant(signature, values),
            None if reply_signature is None else GLib.VariantType.new(reply_signature),
            Gio.DBusCallFlags.NONE,
            10_000,
            None,
            finished,
        )
        return GLib.SOURCE_REMOVE

    def control_server(self):
        CONTROL.unlink(missing_ok=True)
        server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        server.bind(str(CONTROL))
        os.chmod(CONTROL, 0o666)
        server.listen()
        while True:
            client, _address = server.accept()
            try:
                data = b""
                while not data.endswith(b"\n"):
                    chunk = client.recv(4096)
                    if not chunk:
                        break
                    data += chunk
                command = json.loads(data.decode())
                GLib.idle_add(self.call_agent, command, client)
            except BaseException as error:
                client.sendall((json.dumps({"ok": False, "error": error.__class__.__name__}) + "\n").encode())
                client.close()

    def run(self):
        threading.Thread(target=self.control_server, daemon=True).start()
        signal.signal(signal.SIGTERM, lambda *_args: self.loop.quit())
        signal.signal(signal.SIGINT, lambda *_args: self.loop.quit())
        self.loop.run()


if __name__ == "__main__":
    FakeBluez().run()

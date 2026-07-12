#!/usr/bin/env python3
"""Send one Agent1 interaction through the VM fake BlueZ connection."""

import json
import socket
import sys


TOKENS = {
    "@DEVICE@": "/org/bluez/hci0/dev_AA_BB_CC_DD_EE_FF",
    "@DISPLAY_PIN@": "654321",
    "@DISPLAY_PASSKEY@": 123456,
    "@CONFIRM_PASSKEY@": 456789,
    "@SERVICE_UUID@": "0000110b-0000-1000-8000-00805f9b34fb",
}


def resolve(value):
    if isinstance(value, list):
        return [resolve(item) for item in value]
    return TOKENS.get(value, value) if isinstance(value, str) else value


command = {
    "method": sys.argv[1],
    "signature": sys.argv[2],
    "reply_signature": None if sys.argv[3] == "-" else sys.argv[3],
    "values": resolve(json.loads(sys.argv[4])),
}
client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
client.connect("/run/bluetooth-predeploy/bluez-control.sock")
client.sendall((json.dumps(command) + "\n").encode())
data = b""
while not data.endswith(b"\n"):
    chunk = client.recv(4096)
    if not chunk:
        break
    data += chunk
result = json.loads(data.decode())
print(json.dumps(result, sort_keys=True))
raise SystemExit(0 if result.get("ok") else 1)

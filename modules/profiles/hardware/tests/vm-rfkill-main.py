#!/usr/bin/env python3
"""Fake systemd-rfkill main process for the real-manager VM fixture."""

import json
import os
from pathlib import Path
import socket
import time


ROOT = Path("/run/bluetooth-predeploy/rfkill")
invocation = os.environ["INVOCATION_ID"]
event = "MANUAL"
if int(os.environ.get("LISTEN_FDS", "0")) > 0:
    listener = socket.socket(fileno=3)
    listener.settimeout(0.1)
    try:
        event = listener.recv(128).decode().strip() or "EMPTY"
    except TimeoutError:
        event = "MANUAL"
scenario = (ROOT / "scenario").read_text().strip()
soft = ROOT / "sys" / "class" / "rfkill" / "rfkill1" / "soft"
persisted = ROOT / "persisted-bluetooth"


def record(phase):
    value = {
        "InvocationID": invocation,
        "phase": phase,
        "event": event,
        "scenario": scenario,
    }
    with (ROOT / "events.jsonl").open("a") as output:
        output.write(json.dumps(value, sort_keys=True) + "\n")
    print(f"rfkill-fixture phase={phase} event={event} scenario={scenario}", flush=True)


record("socket-receive")
if scenario == "startup-failure":
    if soft.exists():
        soft.write_text("1\n")
    raise SystemExit(44)

notify_socket = os.environ["NOTIFY_SOCKET"]
notify_address = "\0" + notify_socket[1:] if notify_socket.startswith("@") else notify_socket
notifier = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
notifier.sendto(b"READY=1", notify_address)
notifier.close()
record("main-start")
if soft.exists():
    if event in ("ADD", "MANUAL", "RESTART"):
        soft.write_text(persisted.read_text())
    elif event == "CHANGE":
        persisted.write_text(soft.read_text())

if scenario == "runtime-failure":
    record("main-exit")
    raise SystemExit(42)
if scenario == "wait":
    (ROOT / "main-waiting").write_text(invocation + "\n")
    while True:
        time.sleep(1)

record("main-exit")

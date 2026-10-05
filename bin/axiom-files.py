#!/usr/bin/env python3
"""Mount Axiom through native macOS SMB, keeping credentials out of argv/files."""
import argparse
import ctypes as C
import fcntl
import json
import os
from pathlib import Path
import socket
import subprocess
import sys
import time


def mounted(path):
    # Reading the mount table avoids stat() against an unavailable SMB server.
    result = subprocess.run(["/sbin/mount", "-t", "smbfs"], capture_output=True, text=True, check=True)
    for line in result.stdout.splitlines():
        if f" on {path} (" in line:
            return line.split(" on ", 1)[0]
    return None


def p2p_ready(log):
    try:
        with log.open("rb") as handle:
            handle.seek(0, 2)
            handle.seek(max(0, handle.tell() - 131072))
            text = handle.read().decode("utf-8", errors="replace")
    except OSError:
        return False
    # A new FRP process invalidates successful connections from the previous
    # run. Listening on 1446 alone can otherwise select its slower fallback.
    text = text[text.rfind("start frpc service"):] if "start frpc service" in text else text
    events = [line for line in text.splitlines()
              if "[charles-axiom-files-p2p]" in line and
              any(marker in line for marker in ("establishing nat hole connection successful",
                  "no tunnel session", "open tunnel error", "nathole prepare error",
                  "nathole exchange info error"))]
    return bool(events and "establishing nat hole connection successful" in events[-1])


def native_mount(url, path, password):
    cf = C.CDLL("/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation")
    net = C.CDLL("/System/Library/Frameworks/NetFS.framework/NetFS")
    ptr = C.c_void_p
    cf.CFStringCreateWithCString.argtypes = [ptr, C.c_char_p, C.c_uint32]
    cf.CFStringCreateWithCString.restype = ptr
    cf.CFURLCreateWithString.argtypes = [ptr, ptr, ptr]
    cf.CFURLCreateWithString.restype = ptr
    cf.CFURLCreateFromFileSystemRepresentation.argtypes = [ptr, C.c_char_p, C.c_long, C.c_bool]
    cf.CFURLCreateFromFileSystemRepresentation.restype = ptr
    cf.CFDictionaryCreateMutable.argtypes = [ptr, C.c_long, ptr, ptr]
    cf.CFDictionaryCreateMutable.restype = ptr
    cf.CFDictionarySetValue.argtypes = [ptr, ptr, ptr]
    cf.CFRelease.argtypes = [ptr]
    net.NetFSMountURLSync.argtypes = [ptr, ptr, ptr, ptr, ptr, ptr, C.POINTER(ptr)]
    net.NetFSMountURLSync.restype = C.c_int
    refs = []

    def string(value):
        ref = cf.CFStringCreateWithCString(None, value.encode("utf-8"), 0x08000100)
        refs.append(ref)
        return ref

    def dictionary():
        ref = cf.CFDictionaryCreateMutable(None, 0, None, None)
        refs.append(ref)
        return ref

    try:
        url_ref = cf.CFURLCreateWithString(None, string(url), None)
        refs.append(url_ref)
        raw_path = os.fsencode(path)
        path_ref = cf.CFURLCreateFromFileSystemRepresentation(None, raw_path, len(raw_path), True)
        refs.append(path_ref)
        open_opts, mount_opts = dictionary(), dictionary()
        true = ptr.in_dll(cf, "kCFBooleanTrue").value
        # Fail unattended rather than displaying an authentication dialog.
        cf.CFDictionarySetValue(open_opts, string("NoUserPreferences"), true)
        cf.CFDictionarySetValue(open_opts, string("AllowLoopback"), true)
        cf.CFDictionarySetValue(open_opts, string("ForceNewSession"), true)
        ui_key = string("UIOption")
        cf.CFDictionarySetValue(open_opts, ui_key, string("NoUI"))
        cf.CFDictionarySetValue(mount_opts, string("MountAtMountDir"), true)
        points = ptr()
        status = net.NetFSMountURLSync(url_ref, path_ref, string("c1"), string(password), open_opts, mount_opts, C.byref(points))
        if points:
            cf.CFRelease(points)
        return status
    finally:
        for ref in reversed(refs):
            if ref:
                cf.CFRelease(ref)


def connect(args):
    if args.auto and args.paused.exists():
        return
    if args.network_tool:
        subprocess.run([args.network_tool], check=True)
    source = mounted(args.mountpoint)
    if source:
        expected = {"p2p": "@127.0.0.1:1446/", "wireguard": f"@{args.wireguard_host}/", "frp": "@127.0.0.1:1445/"}
        if args.transport != "auto" and expected[args.transport] not in source:
            raise RuntimeError("Already mounted through another transport; disconnect first")
        return
    if not args.auto:
        args.paused.unlink(missing_ok=True)
    path = Path(args.mountpoint)
    if path.is_symlink():
        raise RuntimeError("Mountpoint must not be a symlink")
    path.mkdir(parents=True, exist_ok=True)
    if any(path.iterdir()):
        raise RuntimeError("Mountpoint contains local files; choose an empty directory")
    password = subprocess.run(
        [args.age, "--decrypt", "-i", args.identity, args.password_file],
        check=True, capture_output=True, text=True,
    ).stdout.strip()
    if not password or any(c in password for c in "\r\n\0"):
        raise RuntimeError("Invalid SMB credential")
    endpoints = {
        "p2p": ("127.0.0.1", 1446),
        "wireguard": (args.wireguard_host, 445),
        "frp": ("127.0.0.1", 1445),
    }
    order = ["p2p", "wireguard", "frp"] if args.transport == "auto" else [args.transport]
    errors = []
    for name in order:
        host, port = endpoints[name]
        # Launchd starts FRP and this helper independently. Allow the local
        # visitor to finish starting before selecting a slower relay path.
        deadline = time.monotonic() + (5 if name == "p2p" else 0)
        try:
            while True:
                try:
                    with socket.create_connection((host, port), timeout=3):
                        pass
                    break
                except OSError:
                    if time.monotonic() >= deadline:
                        raise
                    time.sleep(.2)
        except OSError:
            errors.append(f"{name}: unavailable")
            continue
        if name == "p2p" and args.frp_log:
            deadline = time.monotonic() + 30
            while not p2p_ready(args.frp_log) and time.monotonic() < deadline:
                time.sleep(.2)
            if not p2p_ready(args.frp_log):
                errors.append("p2p: direct tunnel unavailable")
                continue
        if any(path.iterdir()):
            raise RuntimeError("Mountpoint contains local files; choose an empty directory")
        url = f"smb://{host}{':' + str(port) if port != 445 else ''}/work"
        status = native_mount(url, args.mountpoint, password)
        if status == 0 and mounted(args.mountpoint):
            print(json.dumps({"mountpoint": args.mountpoint, "transport": name, "url": url}))
            return
        errors.append(f"{name}: NetFS status {status}")
    raise RuntimeError("; ".join(errors))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--age", required=True)
    parser.add_argument("--password-file", required=True)
    parser.add_argument("--identity", required=True)
    parser.add_argument("--mountpoint", required=True)
    parser.add_argument("--wireguard-host", default="10.77.0.2")
    parser.add_argument("--network-tool")
    parser.add_argument("--frp-log", type=Path)
    parser.add_argument("--transport", choices=["auto", "p2p", "wireguard", "frp"], default="auto")
    parser.add_argument("--auto", action="store_true")
    parser.add_argument("action", choices=["connect", "disconnect", "status"], nargs="?", default="connect")
    args = parser.parse_args()
    state = Path.home() / "Library/Application Support/axiom-files"
    state.mkdir(parents=True, exist_ok=True)
    args.paused = state / "paused"
    # Launchd and a manual connect must not race to mount the same path.
    with (state / "lock").open("w") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            if args.auto:
                return
            raise RuntimeError("Another mount operation is running; retry after it completes")
        if args.action == "status":
            print(json.dumps({"mountpoint": args.mountpoint, "source": mounted(args.mountpoint), "automount_paused": args.paused.exists()}))
        elif args.action == "disconnect":
            args.paused.touch(mode=0o600)
            if mounted(args.mountpoint):
                subprocess.run(["/usr/sbin/diskutil", "unmount", args.mountpoint], check=True)
        else:
            connect(args)


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        # Subprocess argv contains no plaintext credentials.
        print(f"axiom-files: {error}", file=sys.stderr)
        sys.exit(1)

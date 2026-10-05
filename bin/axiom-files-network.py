#!/usr/bin/env python3
"""Keep FRP NAT traversal outside proxy routes, preserving other Verge rules."""
import argparse
import http.client
import json
import os
from pathlib import Path
import re
import socket
import sys
import tempfile

BEGIN = "// BEGIN C1 AXIOM FILES DIRECT"
END = "// END C1 AXIOM FILES DIRECT"
BLOCK = """// BEGIN C1 AXIOM FILES DIRECT
main = ((userMain) => function(config, profileName) {
  const result = userMain(config, profileName);
  result['find-process-mode'] = 'strict';
  result.rules = ['PROCESS-NAME,frpc,DIRECT',
    ...(result.rules || []).filter(rule => rule !== 'PROCESS-NAME,frpc,DIRECT')];
  return result;
})(main);
// END C1 AXIOM FILES DIRECT
"""


def save(path, text):
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, prefix=".axiom-files-", delete=False) as handle:
        temporary = Path(handle.name)
        handle.write(text)
    try:
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def apply(home):
    darwin = sys.platform == "darwin"
    root = home / ("Library/Application Support" if darwin else ".local/share") / "io.github.clash-verge-rev.clash-verge-rev"
    profile = root / "profiles/Script.js"
    if not profile.is_file():
        print("axiom-files-network: Verge profile unavailable; skipped", file=sys.stderr)
        return
    if profile.is_symlink():
        raise RuntimeError("Verge script is a symlink; preserve it and configure FRP DIRECT manually")
    original = profile.read_text()
    count = original.count(BEGIN)
    if count == 0:
        if not re.search(r"\bfunction\s+main\s*\(", original):
            raise RuntimeError("Verge script has no main function; preserve it and configure FRP DIRECT manually")
        updated = original.rstrip() + "\n\n" + BLOCK
    elif count == 1 and original.count(END) == 1:
        updated = re.sub(re.escape(BEGIN) + r".*?" + re.escape(END) + r"\n?", lambda _: BLOCK, original, flags=re.S)
    else:
        raise RuntimeError("Ambiguous managed Verge block; preserve profile")
    if updated != original:
        backup = profile.with_name("Script.js.pre-axiom-files")
        if not backup.exists():
            with backup.open("x") as handle:
                os.chmod(backup, 0o600)
                handle.write(original)
        save(profile, updated)

    # The service-mode Mac core uses a different socket from Verge's UI config.
    source = root / "clash-verge.yaml"
    if not source.is_file():
        return
    if source.is_symlink():
        raise RuntimeError("Generated Verge config is a symlink; preserve it")
    text = source.read_text()
    if text.count("\nrules:\n") != 1:
        raise RuntimeError("Unexpected generated Verge rule layout; preserve runtime")
    payload = re.sub(r"^- PROCESS-NAME,frpc,DIRECT\n", "", text, flags=re.M)
    payload = payload.replace("\nrules:\n", "\nrules:\n- PROCESS-NAME,frpc,DIRECT\n", 1)
    if re.search(r"^find-process-mode:", payload, re.M):
        payload = re.sub(r"^find-process-mode:.*$", "find-process-mode: strict", payload, flags=re.M)
    else:
        payload = "find-process-mode: strict\n" + payload
    if payload != text:
        backup = source.with_name("clash-verge.yaml.pre-axiom-files")
        if not backup.exists():
            with backup.open("x") as handle:
                os.chmod(backup, 0o600)
                handle.write(text)
        save(source, payload)
        text = payload

    def value(key):
        match = re.search(r"^" + re.escape(key) + r":\s*(.*)$", text, re.M)
        return match.group(1).strip().strip("\"'") if match else ""

    endpoint = Path(f"/var/run/clash-verge-service/users/{os.getuid()}/verge-mihomo.sock") if darwin else Path(value("external-controller-unix"))
    if not endpoint.is_socket():
        print("axiom-files-network: core unavailable; profile takes effect at next Verge start", file=sys.stderr)
        return

    class UnixHTTP(http.client.HTTPConnection):
        def connect(self):
            self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            self.sock.settimeout(10)
            self.sock.connect(str(endpoint))

    headers = {"Content-Type": "application/json"}
    if value("secret"):
        headers["Authorization"] = "Bearer " + value("secret")
    client = UnixHTTP("localhost", timeout=10)
    try:
        client.request("GET", "/rules", headers=headers)
        response = client.getresponse()
        rules = json.loads(response.read()).get("rules", []) if response.status == 200 else []
        if rules and rules[0].get("type") == "ProcessName" and rules[0].get("payload") == "frpc" and rules[0].get("proxy") == "DIRECT" and not rules[0].get("extra", {}).get("disabled", False):
            return
        client.request("PUT", "/configs?force=true", body=json.dumps({"payload": payload}), headers=headers)
        response = client.getresponse()
        response.read()
        if response.status != 204:
            raise RuntimeError(f"Mihomo reload status {response.status}")
        print("axiom-files-network: FRP DIRECT rule applied")
    finally:
        client.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--home", type=Path, required=True)
    args = parser.parse_args()
    try:
        apply(args.home)
    except (OSError, ValueError, RuntimeError, http.client.HTTPException) as error:
        print(f"axiom-files-network: {error}", file=sys.stderr)
        sys.exit(1)

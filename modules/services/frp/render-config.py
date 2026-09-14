"""Render exact TOML string placeholders without putting credentials in the store."""
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import sys
import tempfile
import tomllib


def render(template, secret_paths, output, age=None, identity=None):
    output = Path(output)
    parent = output.parent
    metadata = parent.lstat()
    if (not stat.S_ISDIR(metadata.st_mode) or metadata.st_uid != os.geteuid()
            or stat.S_IMODE(metadata.st_mode) != 0o700):
        raise ValueError("Runtime directory must be owned by the service user with mode 0700")
    text = Path(template).read_text()
    for name, path in json.loads(Path(secret_paths).read_text()).items():
        marker = json.dumps("@" + name + "@")
        if marker not in text:
            continue
        if age is None:
            data = Path(path).read_bytes()
        else:
            data = subprocess.run(
                [age, "--decrypt", "-i", identity, path], check=True,
                stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
            ).stdout
        value = data.decode("utf-8").removesuffix("\n")
        if not value or any(c in value for c in "\r\n\0"):
            raise ValueError("Secret must be a nonempty single line")
        text = text.replace(marker, json.dumps(value, ensure_ascii=True))
    # Only inspect placeholders before TOML parsing; never echo parser errors.
    if re.search(r'"@FRP_[A-Z0-9_]+@"', text):
        raise ValueError("Unresolved FRP placeholder")
    tomllib.loads(text)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", dir=parent, delete=False) as f:
            temporary = f.name
            f.write(text)
            f.flush()
            os.fsync(f.fileno())
        os.replace(temporary, output)
        temporary = None
    finally:
        if temporary is not None:
            os.unlink(temporary)


if __name__ == "__main__":
    try:
        render(*sys.argv[1:])
    except Exception:
        sys.exit("FRP configuration rendering failed; check secret availability and runtime directory permissions")

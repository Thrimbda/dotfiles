# Test Report

## Result

PASS

## Command

```bash
node -e 'const fs = require("fs"); const path = "/home/c1/.config/opencode/opencode.json"; const config = JSON.parse(fs.readFileSync(path, "utf8")); if (config.permission !== "allow") throw new Error(`expected permission=allow, got ${JSON.stringify(config.permission)}`); console.log(`${path}: permission=allow`);'
```

## Evidence

The command parsed `~/.config/opencode/opencode.json` as JSON and asserted `permission === "allow"`.

Observed output:

```text
/home/c1/.config/opencode/opencode.json: permission=allow
```

## Why This Check

The requested change is a user-level JSON config update. A direct parse-and-assert check proves both that the file remains valid JSON and that the intended permission value is present.

## Skipped

No full OpenCode runtime invocation was run because it could expose unrelated resolved provider or plugin configuration; direct file validation is sufficient for this scoped config edit.

## Summary

- Enable global OpenCode permission auto-accept for the current user.
- Preserve existing global OpenCode plugin and MCP configuration.
- Record verification and review evidence in the Legion task docs.

## Validation

- `node -e 'const fs = require("fs"); const path = "/home/c1/.config/opencode/opencode.json"; const config = JSON.parse(fs.readFileSync(path, "utf8")); if (config.permission !== "allow") throw new Error(`expected permission=allow, got ${JSON.stringify(config.permission)}`); console.log(`${path}: permission=allow`);'`

## Risk

- This intentionally allows future OpenCode actions without approval prompts unless project or agent rules override the global default.

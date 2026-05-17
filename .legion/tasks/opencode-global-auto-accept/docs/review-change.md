# Review Change

## Decision

PASS

## Scope Check

- In scope: `~/.config/opencode/opencode.json` now sets `permission` to `"allow"`.
- In scope: Legion task documentation was added under `.legion/tasks/opencode-global-auto-accept/`.
- No project-level `opencode.json` was changed.
- Existing global config keys for schema, plugin, and MCP were preserved.

## Verification Evidence

`docs/test-report.md` records a passing JSON parse-and-assert check for `permission === "allow"`.

## Security Lens

Applied because this change affects permission behavior.

The change intentionally weakens local approval prompts for future OpenCode sessions. This is not a hidden security regression because it is the requested behavior, is scoped to the current user's global OpenCode config, and is reversible by changing `permission` back to a narrower rule such as `{ "edit": "allow", "bash": "ask" }` or `"ask"`.

## Blocking Findings

None.

## Residual Risk

Project-level or agent-level permission rules can override this global default. Future OpenCode sessions may run edits and shell commands without prompts unless a more specific rule changes that behavior.

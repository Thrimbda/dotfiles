# Report Walkthrough

## Mode

implementation (configuration-only)

## Summary

- Updated the user-level OpenCode config at `~/.config/opencode/opencode.json`.
- Added `"permission": "allow"` so OpenCode permission prompts are auto-approved by default for this user.
- Preserved existing global config keys for schema, plugin, and MCP.

## Evidence

- Verification: `docs/test-report.md` confirms the JSON file parses and `permission === "allow"`.
- Review: `docs/review-change.md` passes the scoped change and records the permission-related security caveat.

## Residual Caveat

This globally reduces approval prompts for future OpenCode sessions. More specific project or agent permission rules can still override it.

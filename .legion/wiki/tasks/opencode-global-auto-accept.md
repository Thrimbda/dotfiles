# opencode-global-auto-accept

## Metadata

- `task-id`: `opencode-global-auto-accept`
- `status`: `completed`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

The user-level OpenCode config now defaults permissions to auto-allow via `"permission": "allow"` in `~/.config/opencode/opencode.json`.

Existing global OpenCode plugin and MCP configuration was preserved.

The effective caveat is that future OpenCode sessions may run edits and shell commands without prompts unless a project-level or agent-level permission rule overrides the global default.

## Reusable Decisions

- Use OpenCode's documented `permission` config for durable default approval behavior rather than relying on per-session UI toggles.
- For this host/user, global OpenCode auto-accept is intentional and should be treated as a local security trade-off.

## Related Raw Sources

- `plan`: `.legion/tasks/opencode-global-auto-accept/plan.md`
- `log`: `.legion/tasks/opencode-global-auto-accept/log.md`
- `tasks`: `.legion/tasks/opencode-global-auto-accept/tasks.md`
- `test-report`: `.legion/tasks/opencode-global-auto-accept/docs/test-report.md`
- `review`: `.legion/tasks/opencode-global-auto-accept/docs/review-change.md`
- `report`: `.legion/tasks/opencode-global-auto-accept/docs/report-walkthrough.md`

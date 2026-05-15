# SSH Foot Term Compatibility

## Metadata

- `task-id`: `ssh-foot-term-compat`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `2026-05-15-legion-workflow`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

This task fixes SSH sessions launched from Foot-backed hosts failing remote startup on machines that lack Foot terminfo. The current effective behavior is to keep Foot as the local/default terminal while the repository-managed `ssh` wrapper exports `TERM=xterm-256color` before invoking OpenSSH.

Generated wrapper validation confirmed Axiom's wrapped `bin/ssh` contains `export TERM='xterm-256color'`, while generated `bin/scp` remains unchanged. Axiom and Azar both evaluate `modules.xdg.ssh.enable = true`, so the shared wrapper path applies to the checked Foot-enabled hosts after rebuild.

The remaining runtime step is deployment plus a fresh SSH session; existing sessions and non-managed SSH binaries are not changed retroactively.

## Reusable Decisions

- Treat SSH as the terminal portability boundary for Foot terminfo compatibility; do not require every remote host to install Foot terminfo.
- Preserve local Foot and local tmux terminal behavior; only the wrapped interactive `ssh` binary should set the portable `TERM` value.
- Validate SSH wrapper changes by building the generated wrapper and inspecting `bin/ssh`, not only by reading source text.

## Related Raw Sources

- `plan`: `.legion/tasks/ssh-foot-term-compat/plan.md`
- `log`: `.legion/tasks/ssh-foot-term-compat/log.md`
- `tasks`: `.legion/tasks/ssh-foot-term-compat/tasks.md`
- `test-report`: `.legion/tasks/ssh-foot-term-compat/docs/test-report.md`
- `change-review`: `.legion/tasks/ssh-foot-term-compat/docs/review-change.md`
- `report`: `.legion/tasks/ssh-foot-term-compat/docs/report-walkthrough.md`

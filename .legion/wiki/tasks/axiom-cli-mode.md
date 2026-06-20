# axiom-cli-mode

## Metadata

- `task-id`: `axiom-cli-mode`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `legion-wiki`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

This task adds a host-local `axiom-mode` command for switching Axiom between its normal Hyprland desktop mode and an SSH-friendly CLI mode without invoking `hey`. CLI mode is represented by `axiom-cli.target`, which requires `multi-user.target`, wants `getty@tty1.service`, conflicts with `graphical.target`, and allows isolation. Remote access services remain available because `sshd`, reverse SSH, cloudflared, and opencode are still attached to `multi-user.target`.

## Reusable Decisions

- For Axiom SSH-only operation, use `axiom-mode cli` rather than disabling desktop modules or creating a second host configuration.
- For returning to the full desktop path, use `axiom-mode desktop`, which restores `graphical.target` as the default and lets greetd/UWSM start Hyprland.
- Host-local runtime mode switches should use fixed systemd target names and fixed `systemctl` operations; do not pass user-controlled target names into privileged commands.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-cli-mode/plan.md`
- `log`: `.legion/tasks/axiom-cli-mode/log.md`
- `tasks`: `.legion/tasks/axiom-cli-mode/tasks.md`
- `test-report`: `.legion/tasks/axiom-cli-mode/docs/test-report.md`
- `review`: `.legion/tasks/axiom-cli-mode/docs/review-change.md`
- `report`: `.legion/tasks/axiom-cli-mode/docs/report-walkthrough.md`

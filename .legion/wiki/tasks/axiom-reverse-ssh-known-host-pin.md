# Axiom Reverse SSH Known Host Pin

## Metadata

- `task-id`: `axiom-reverse-ssh-known-host-pin`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- Axiom no longer declares a system-wide SSH known-host pin for the remote server `8.159.128.125`.
- This prevents a remote OS reinstall from leaving a stale Nix-managed key in `/etc/ssh/ssh_known_hosts` that blocks normal login.
- The reusable `modules.services.reverse-ssh.remoteHostKey` option remains available for hosts that deliberately want declarative pinning.
- SSH host-key checking is not disabled; new remote keys still require normal user confirmation or user known-host cleanup.

## Reusable Decisions

- Do not declaratively pin mutable/reinstallable remote host keys on Axiom unless the task explicitly chooses that operational burden.
- Keep reverse endpoint identity checks separate from remote server host-key pinning: proving `127.0.0.1:2223` reaches Axiom is not the same as pinning the remote server's own host key forever.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-reverse-ssh-known-host-pin/plan.md`
- `log`: `.legion/tasks/axiom-reverse-ssh-known-host-pin/log.md`
- `tasks`: `.legion/tasks/axiom-reverse-ssh-known-host-pin/tasks.md`
- `test-report`: `.legion/tasks/axiom-reverse-ssh-known-host-pin/docs/test-report.md`
- `review-change`: `.legion/tasks/axiom-reverse-ssh-known-host-pin/docs/review-change.md`
- `report`: `.legion/tasks/axiom-reverse-ssh-known-host-pin/docs/report-walkthrough.md`

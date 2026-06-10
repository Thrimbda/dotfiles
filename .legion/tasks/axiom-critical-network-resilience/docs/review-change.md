# Review Change: Axiom Critical Network Resilience

## Result
PASS

## Security Lens
Applied because the change touches SSH host-key trust and root healthcheck services that restart privileged system units.

## Blocking Findings
None.

## Review Notes
- Scope compliance: changes are limited to `hosts/axiom/default.nix` plus Legion task artifacts and ledger entries, matching the approved RFC scope.
- Correctness: the implementation adds OOM/resource protection for `sshd`, `autossh-reverse-ssh`, `cloudflared`, `clash-verge`, user manager, and Clash GUI/user autostart as planned.
- Autossh healthcheck uses key comparison rather than a weak SSH banner check: it reads local `/etc/ssh/ssh_host_ed25519_key.pub`, runs bounded remote `ssh-keyscan` through strict SSH host-key checking, compares the remote endpoint key to the local key, and does not kill remote processes.
- SSH host-key pinning is declarative and system-wide through `/etc/ssh/ssh_known_hosts`, not a user `known_hosts` mutation.
- Cloudflared `/ready` healthcheck and explicit metrics endpoint are present.
- Healthcheck services are root oneshots with runtime state under `/run`, which is appropriate for restarting system services.
- Verification evidence is sufficient for pre-deployment review: build/eval, generated unit inspection, syntax checks, and safe live predicates are recorded in `docs/test-report.md`.

## Non-blocking Suggestions
- Consider adding explicit `StrictHostKeyChecking=yes` and `UpdateHostKeys=no` to the main autossh `ExecStart` in a follow-up or before deployment if desired; the healthcheck already uses these settings.
- Improve autossh healthcheck diagnostics to separately log remote SSH unreachable, remote host-key failure, no reverse listener, and wrong listener key.
- After deployment, run the healthcheck timer/services under systemd once and inspect journal output before relying on automatic recovery, since live restart-threshold behavior was intentionally not forced pre-deployment.

## Residual Risks
- If remote `127.0.0.1:2223` is held by a stale listener, this implementation detects/logs it but may still require manual remote cleanup.
- Root healthchecks intentionally restart critical services after repeated failures; transient network issues could still cause restarts despite thresholds.
- `ss -p` listener evidence may expose remote process names in local journal logs; no secrets or SSH private material are logged.

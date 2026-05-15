# Enable ToDesk service networking on axiom - log

## 2026-05-15

- Created task `axiom-todesk-service-network` as a follow-up to `axiom-install-todesk` because the previous task intentionally excluded daemon/service management.
- Opened isolated worktree `.worktrees/axiom-todesk-service-network` from latest `origin/master` on branch `legion/axiom-todesk-service-network`.
- Manual diagnosis before this task showed `todesk` failed until `/var/lib/todesk` existed, and later showed the GUI had no external sockets until `todesk service` was running.
- Added declarative tmpfiles state directory and a host-local systemd service for `todesk service`.
- Tightened the tmpfiles directory mode from the manual diagnostic's `0755` to `0700` because ToDesk writes auth/private state there and both GUI/service run as `c1`.
- Verified the axiom NixOS configuration evaluates with the expected tmpfiles rule and systemd service fields.
- Recorded live socket evidence showing `ToDesk_Service` owns the external HTTPS connection and the GUI connects to it over localhost.
- Completed readiness review with security lens applied for remote desktop service startup and private ToDesk state; no blocking findings remain.
- Created implementation walkthrough and PR body from the verification and review evidence.
- Completed wiki writeback with task summary, current decision, reusable pattern, maintenance smoke check, and a pointer from the original ToDesk install summary.

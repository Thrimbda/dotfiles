# Log: Axiom Critical Network Resilience

## 2026-06-10

- Created task after the OOM/reboot recovery incident exposed critical network services without explicit OOM priority and with active-but-broken failure modes.
- Decision: treat `sshd`, `autossh-reverse-ssh.service`, `cloudflared.service`, and `clash-verge.service` as Tier 0 critical network services; treat Clash Verge GUI/user autostart as Tier 1 because it is useful control surface but less critical than mihomo/service-mode core.
- Decision: require a focused RFC before implementation because the task spans kernel OOM selection, cgroup memory protection, generated user units, remote autossh health checks, and rollback behavior.
- Constraint: do not weaken SSH host-key policy or write persistent host keys as part of health checks without explicit approval.
- Design: wrote `docs/research.md` and `docs/rfc.md`; recommended tiered OOM/resource protection, bounded healthcheck timers, declarative SSH host-key pinning, and zram as a pressure buffer.
- Review: first RFC review failed on automatic remote cleanup safety and weak autossh banner verification.
- Design update: removed automatic remote process killing from enabled timer behavior; autossh health now compares the remote reverse endpoint host key against `axiom`'s local SSH host key and logs remote listener evidence for manual cleanup.
- Review: second RFC review passed. Implementation may begin inside the required `git-worktree-pr` envelope.
- Implementation: created worktree `.worktrees/axiom-critical-network-resilience` on branch `legion/axiom-critical-network-resilience-network-hardening` from `origin/master`.
- Implementation: updated `hosts/axiom/default.nix` with Tier 0 OOM/resource protection, Clash GUI user drop-in, declarative autossh remote host key pinning, cloudflared/autossh/Clash healthcheck timers, explicit cloudflared metrics endpoint, and capped zram swap.
- Implementation check: targeted `nix eval` confirmed autossh OOM score, timer config, pinned host key, zram fields, cloudflared/clash OOM fields, user manager OOM adjustment, and Clash GUI OOM adjustment.
- Verification: `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel` passed.
- Verification: generated systemd units/timers, cloudflared config, SSH known_hosts, zram config, and Clash GUI/user manager drop-ins match the RFC.
- Verification: `systemd-analyze verify` and `bash -n` passed for generated healthcheck units/scripts.
- Verification: safe live checks passed for cloudflared `/ready`, autossh remote endpoint host-key identity, and Clash service/core predicates.
- Verification note: direct script execution as unprivileged user fails as expected because healthcheck scripts are root systemd oneshots using `/run/axiom-healthchecks`.
- Review: `review-change` passed with security lens applied. No blocking findings. Residual risk remains that stale remote `2223` listeners may require manual cleanup because timers deliberately do not kill remote processes.
- Delivery: wrote implementation-mode `docs/report-walkthrough.md` and PR-ready `docs/pr-body.md` from existing RFC, verification, and review evidence.
- Wiki: added task summary and promoted reusable critical-network resilience decisions, validation pattern, and post-deploy maintenance checks.
- PR lifecycle: implementation PR `https://github.com/Thrimbda/dotfiles/pull/79` merged after auto-merge attempt. This closeout update records the terminal Legion task state; local worktree cleanup and main workspace refresh follow after closeout PR merge.

# Log: Axiom Autossh C1ctl Check

## 2026-07-05

- User decided the autossh endpoint timer is too low-value/noisy and asked to remove it, moving the diagnostic into `c1ctl` instead.
- Created isolated worktree `.worktrees/axiom-autossh-c1ctl-check` on branch `legion/axiom-autossh-c1ctl-check-c1ctl-diagnostic` from `origin/master`.
- Initial scope: remove only the Axiom autossh endpoint healthcheck instance, keep other healthchecks, and add an explicit operator-run `c1ctl autossh check` command.
- Removed the Axiom autossh healthcheck instance and deleted the now-unused autossh-specific predicate/options from the generic healthchecks module. Cloudflared and Clash healthchecks remain.
- Added built-in `c1ctl autossh check`, with Axiom autossh constants injected by Nix from the host reverse-ssh configuration.
- Validation passed for absence of autossh healthcheck service/timer, remaining healthcheck inventory, `c1ctl` package build, Axiom toplevel build, help/which output, and a live `c1ctl autossh check` against remote `127.0.0.1:2223`.

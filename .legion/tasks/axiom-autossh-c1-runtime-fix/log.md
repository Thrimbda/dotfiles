# Log: Axiom Autossh C1 Runtime Fix

## 2026-07-05

- User requested a Legion workflow repair for the current autossh runtime failure.
- Runtime diagnosis before implementation showed the live unit still used `root@8.159.128.125` and failed strict host-key verification against stale `/home/c1/.config/ssh/known_hosts:2`.
- Confirmed remote `c1@8.159.128.125` BatchMode SSH works when using a known-hosts source with the current remote ED25519 key, while `root@8.159.128.125` fails public-key authentication.
- Created isolated worktree `.worktrees/axiom-autossh-c1-runtime-fix` on branch `legion/axiom-autossh-c1-runtime-fix-c1-known-hosts` from `origin/master`.
- Implemented remote user `c1`, added a service-specific known-hosts file for `8.159.128.125`, and added a `UserKnownHostsFile=/dev/null` override for reverse SSH service/healthcheck invocations so stale `/home/c1/.config/ssh/known_hosts` cannot block the system service.
- Validation passed for service ExecStart eval, healthcheck runner readback, generated known-hosts attrs, full Axiom toplevel build, service-style `c1` SSH authentication, and a temporary reverse-tunnel endpoint identity smoke test.

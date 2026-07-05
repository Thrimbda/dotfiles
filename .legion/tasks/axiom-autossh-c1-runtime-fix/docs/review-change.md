# Review Change: Axiom Autossh C1 Runtime Fix

## Verdict

PASS with deployment handoff.

## Findings

None blocking.

## Scope Review

- The implementation changes only Axiom's reverse-ssh host wiring plus reusable reverse-ssh/healthcheck options needed to avoid stale user known-hosts state.
- The remote forward remains loopback-only: `127.0.0.1:2223:127.0.0.1:22`.
- `charlie`, `azar`, FRP, firewall exposure, Cloudflare, and local SSH daemon behavior are not changed.

## Correctness Review

- Generated autossh ExecStart now targets `c1@8.159.128.125` and adds `-o UserKnownHostsFile=/dev/null`.
- Axiom generates a service-specific known-hosts file for the current remote ED25519 key, so strict host-key validation does not depend on mutable `/home/c1/.config/ssh/known_hosts` or global `/etc/ssh/ssh_known_hosts` state.
- The autossh endpoint-key healthcheck inherits `reverseSsh.remoteUser` and `reverseSsh.userKnownHostsFile`, so it validates the same account and known-hosts behavior as the service.
- The generated healthcheck runner was read back after fixing shell line-continuation formatting.

## Security Lens

Applied because the change touches SSH identity, host-key trust, and remote authentication.

- Strict host-key validation is preserved; the fix does not use `StrictHostKeyChecking=no`.
- The remote account is narrowed to the intended `c1` account instead of continuing to attempt `root`.
- The service ignores stale user known-hosts only for the mutable user file; it still relies on the generated service-specific known-hosts file.
- No private keys, tokens, passwords, remote firewall openings, non-loopback binds, or new privileged command paths are introduced.

## Residual Risk

- The running system will keep the old unit until Axiom applies the new NixOS configuration and restarts `autossh-reverse-ssh.service`.
- Future remote redeploys require refreshing the pinned host key again.

# Review Change: Axiom Autossh C1ctl Check

## Verdict

PASS.

## Findings

None blocking.

## Scope Review

- The Axiom autossh endpoint healthcheck instance is removed; cloudflared and Clash healthchecks remain generated.
- The generic healthchecks module keeps HTTP and service-core support, while the unused autossh-specific systemd predicate/options are removed.
- `c1ctl` gains only an on-demand `autossh check` diagnostic. It does not add a timer, daemon, restart action, or background monitor.

## Correctness Review

- `c1ctl` receives autossh remote host/user/port/host-key values from Axiom's Nix configuration instead of duplicating separate literals in Rust.
- The command checks the remote endpoint by running remote `ssh-keyscan -p 2223 127.0.0.1` through SSH and comparing the ED25519 key with `/etc/ssh/ssh_host_ed25519_key.pub`.
- Generated NixOS config confirms `autossh-reverse-ssh-healthcheck` service/timer are absent and only `cloudflared-healthcheck` plus `clash-verge-healthcheck` remain.
- Build and live command smoke passed.

## Security Lens

Applied because the change touches SSH host identity and remote command execution.

- Strict remote host-key checking is preserved for the SSH connection to `8.159.128.125`.
- The command writes a temporary known-hosts file using atomic `create_new` rather than overwriting a predictable path, avoiding symlink/overwrite risk in `/tmp` fallback.
- Remote command content is fixed by the binary from Nix-injected constants; no user input enters the remote shell command.
- The command does not print secrets, does not handle private key material, and does not widen the tunnel bind address.

## Residual Risk

- Removing the timer removes automatic autossh restart based on endpoint identity. This is intentional per the updated operating model: run `c1ctl autossh check` when deploying or diagnosing the tunnel.

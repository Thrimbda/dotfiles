# Acorn Traffic Attribution Walkthrough

## Mode

Implementation

## Outcome

Acorn now retains five-minute local traffic-attribution samples. The samples identify cgroup ingress/egress for `frps`, `nginx`, `rustdesk-relay`, and `sshd`, plus byte totals per active FRP TCP proxy.

## Changed Configuration

- `hosts/acorn/default.nix` imports the new host-local traffic-accounting module.
- `hosts/acorn/modules/traffic-accounting.nix` explicitly retains IP accounting, installs a root-owned sampler timer, uses the existing loopback FRP dashboard, retains individual samples for 30 days, and installs `acorn-traffic-report`.

## Verification

- Targeted Acorn Nix evaluation resolved the sampler, five-minute timer, and `IPAccounting=true`.
- The required Axiom-built remote `nixos-rebuild switch` completed and started the timer.
- Acorn holds `root:root` mode `0640` samples and `acorn-traffic-report` produced measured deltas for all four services and current FRP proxies.
- Nginx, FRPS, RustDesk relay, and SSHD remained active.

See `docs/test-report.md` for commands and captured evidence, and `docs/review-change.md` for scope and security review.

## Operations

Run `sudo acorn-traffic-report` on Acorn after at least two samples exist. It compares the newest two samples and reports byte deltas without combining services that may observe the same local forwarded flow.

## Boundaries

- No network listener, firewall rule, external telemetry, packet capture, request path, client IP, SSH command, or token is collected.
- The report can identify `sshd` as the carrier, but not which remote SSH peer generated its bytes. Peer-level accounting remains a separately scoped privacy/security decision.
- FRP and service restarts reset their counters; the report labels the next interval as `counter-reset` rather than a negative transfer.

# RFC Review: Acorn Traffic Attribution

## Verdict

PASS

## Findings

No blocking findings.

- The core assumptions are observed on the deployed host: `IPAccounting=yes` and nonzero ingress/egress counters are available for all four target services, while the existing loopback FRP API exposes server and per-proxy traffic fields.
- The design keeps attribution bounded to daemon and proxy names. It does not imply that cgroup totals are independent or that it can identify SSH peers.
- Restart resets are represented as counter boundaries, not negative traffic; FRP unavailability is explicitly distinguishable from zero traffic.
- Rollout is constrained to the mandated Axiom build and remote activation path. Rollback removes only collector machinery and preserves production forwarding services.

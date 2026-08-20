# RFC Review

## Decision

PASS. The design is implementable, bounded, verifiable, and rollbackable.

## Blocking Findings

None.

## Review Notes

- A single service plus one active-model link prevents concurrent port and VRAM ownership.
- The command surface is limited to two fixed artifacts and one fixed systemd unit; it does not create an arbitrary privileged path.
- Atomic link replacement and health-gated automatic rollback address partial switch failures.
- Preserving an existing selection while seeding Q6 only when absent gives a stable operator-state boundary across NixOS rebuilds.
- Verification includes the highest-risk assumptions: Q6 full-GPU fit, Q6-Q4-Q6 round trip, lifecycle controls, and rollback.
- The direct Q4 selection remains a sufficient recovery path if Q6 fails after deployment.

## Non-Blocking Suggestion

Keep command output explicit about the selected artifact versus service health so a failed restart cannot be mistaken for a loaded selection.

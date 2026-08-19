# RFC Review: Axiom Single Idle Owner And Hotplug Recovery

## Decision

PASS

## Findings

No blocking design finding.

- The chosen Caelestia-only path preserves the user-required automatic DPMS and existing WlSessionLock while removing a concrete duplicate idle boundary.
- The rejected alternatives are meaningful: a Hypridle-only migration expands state/config risk, while retaining both owners or upgrading to 0.56.2 lacks supporting evidence.
- The socket-recovery change is bounded and independently reversible. It corrects an observed stale-signature failure without claiming to prevent the original compositor coredump.
- Verification distinguishes static proof from the required live overnight DPMS test, so it does not overstate confidence.

## Residual Risk

The XWayland/DRM coredump can recur after this change. That is not a design blocker because the RFC explicitly treats it as unresolved, preserves the evidence required for upstream escalation, and does not weaken locking, remote access, or DPMS behavior.

## Implementation Gate

Implementation may proceed only within the RFC boundary: Axiom's Hypridle service gate, the monitor watcher reconnect behavior, task evidence, and relevant durable documentation.

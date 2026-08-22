# RFC Review: Axiom Caelestia Lock DPMS Behavior

Result: PASS

Review type: adversarial standard-risk design gate.

## Decision Review

- The original Config-plugin closure repair remains necessary: QML schema and
  the loaded `Caelestia.Config` plugin must come from aligned derivations.
- Quickshell 0.3 does not notify `lockedChanged` when it creates a lock, while
  `secureChanged` is emitted after compositor confirmation. Arming on secure
  state is therefore safer than local request state or a static `locked`
  binding.
- Native Axiom key-press and pointer-motion DPMS wake is narrower and more
  reliable than adding lock-surface input plumbing. Its Axiom-wide effect was
  explicitly approved, and other hosts remain unchanged.
- Rollback requires an unlocked session before shell restart or policy change;
  the RFC records this ordering and verifies timer-owned DPMS cleanup.

## Blockers

None.

## Review History

The first revision was returned for treating local `locked` state as compositor
confirmation and for an incomplete active-lock rollback. The accepted design
uses `secureChanged` and an explicit unlocked-session rollback sequence. A later
review of native wake found no blockers and clarified that pointer movement, not
mouse-button input, is the relevant Hyprland event.

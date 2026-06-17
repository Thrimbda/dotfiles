# RFC Review

## Verdict

FAIL.

## Blocking Findings

1. Unknown display policy is underspecified.

The contract requires a newly inserted 4K120 display to use 4K120 under the native-resolution/highest-refresh policy. The RFC currently says unknown displays use dynamic policy only if an Axiom-level default enables it, but does not define that default. This makes the central hotplug behavior unverifiable.

2. Hotplug trigger is underspecified.

The RFC lists event-socket hotplug handling as optional. The user explicitly requested hotplug behavior, so relying only on startup/reload would not satisfy the contract. The design must specify a concrete low-risk watcher or service boundary, even if rollback can disable it.

## Required Changes

- Define Axiom unknown-output defaults: native-resolution/highest-refresh, auto position, conservative scale fallback.
- Define the event source and lifecycle for hotplug reconciliation, including rollback.

## Re-Review

PASS.

The RFC now defines Axiom unknown-output behavior as native-resolution/highest-refresh with auto positioning and scale fallback, and it specifies a Hyprland-session-scoped event watcher that listens for monitor lifecycle events and debounces reconciliation. Rollback can disable the watcher independently while keeping static monitor config.

# Implementation Review: C1ctl Hey Rust Migration

## Decision

PASS

## Security Lens

Applied.

This change adds Rust dynamic command resolution, process execution, and environment propagation. Review specifically checked the Rofi trust boundary, namespace validation, traversal behavior, delegated Janet command handling, and privileged mode-switching scope.

## Blocking Findings

None.

## Resolved Review Findings

- Exact `@rofi` boundary now delegates to Janet `hey`; malformed namespace forms such as `@@rofi` and `@rofi/bin/..` are rejected.
- Non-Rofi dynamic resolver traversal is blocked by rejecting `.`, `..`, `/`, and `\` in command segments, plus a canonical `config/rofi/**` resolved-path guard.
- Wiki current-truth pages now describe `c1ctl`, staged non-Rofi Rust migration, and exact `@rofi` delegation; the old `axiomctl` task summary is historical.
- Verification now covers computed `PATH`, exact `HEYSCRIPT`, delegated dry-run/debug behavior, and negative Rofi bypass/traversal checks.

## Residual Risks

- Live `c1ctl mode cli`, `c1ctl mode desktop`, `c1ctl status`, and `c1ctl reload` remain post-deploy Axiom smoke checks.
- High-impact `hey` commands such as `sync`, `gc`, `profile`, `pull`, `swap`, hooks, and vars are delegated in this slice, not ported or parity-tested as Rust implementations.
- Follow-up migration slices should keep command families scoped and include parity plus rollback evidence before removing Janet behavior.

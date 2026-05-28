# Report Walkthrough - Axiom Remove Default Keep Awake

Mode: implementation.

## Summary

- Removed Axiom's default Caelestia Keep Awake / `idleInhibitor` startup enablement.
- Preserved manual Caelestia Keep Awake commands and UI semantics.
- Preserved the aligned 900 second lock and 1800 second DPMS idle policy with no automatic idle sleep.

## Why

Default Keep Awake suppresses idle handling, which conflicts with the current desired Axiom default: automatic 15 minute lock and 30 minute DPMS should work without restoring automatic sleep. Keep Awake should remain a manual temporary no-idle toggle rather than a startup default.

## Implementation Walkthrough

`hosts/axiom/default.nix`

- Deleted `caelestiaKeepAwake`, the generated helper that retried `caelestia-shell ipc call idleInhibitor enable`.
- Deleted `hey.hooks.startup."07-caelestia-keep-awake"`, so session startup no longer forces Keep Awake on.
- Left the Caelestia session runner, shell config migration, and 900/1800 `general.idle` settings intact.

`hosts/axiom/README.org`

- Reworded Keep Awake docs so Axiom explicitly does not enable it by default.
- Kept manual `idleInhibitor` commands documented.
- Clarified that the shell config migration owns launcher favorites and `general.idle` only.

`.legion/wiki/**`

- Updated current decisions, patterns, maintenance, and task summaries so Keep Awake is manual and historical default-enable tasks are marked superseded.

## Verification Evidence

- `docs/test-report.md`: PASS.
- Targeted Nix assertions: PASS for no startup hook, no default `idleInhibitor enable`, no helper name, and unchanged 900/1800 idle settings.
- Focused active config search: PASS with only the expected manual README command remaining.
- Current-truth wiki search: PASS with only a warning not to restore default `idleInhibitor enable` startup wiring.
- `git diff --check`: PASS.
- `nix build --no-link .#nixosConfigurations.axiom.config.system.build.toplevel`: PASS.

## Review Evidence

- `docs/review-change.md`: PASS with no blocking findings.
- Security lens was applied because the change touches session idle and power behavior; no blocker was found.

## Post-Deploy Smoke

- Start a new Hyprland/Caelestia session after switching to the new generation.
- Confirm Axiom does not force `caelestia shell idleInhibitor isEnabled` back to enabled.
- If a previous session persisted Keep Awake enabled, turn it off manually once and then confirm 15/30 idle behavior.

# Review Change

## Verdict

PASS. No blocking findings.

## Findings

No blocking correctness or security findings were identified in the scoped diff.

## Review Notes

- The lock path is consistently routed through Caelestia IPC: generated keybinds, Hypridle, and the `hey .lock` compatibility wrapper all call `caelestia shell lock lock`.
- Hyprlock is removed from active NixOS package/PAM wiring and its repository-owned config/helpers are deleted.
- `hypridle.service.path` explicitly includes both `caelestia-cli` and `caelestia-shell`, which is necessary because the Python CLI shells out to `caelestia-shell`.
- The change does not widen polkit/logind permissions and avoids the previously unstable `loginctl lock-session` path.
- Legacy `hey .lock` styling flags are now ignored. This is acceptable for the requested Caelestia-only lock path because Caelestia owns lock presentation.

## Security Lens

Security-sensitive area: session lock/authentication behavior.

Result: no blocker. The change removes a separate lock client rather than granting new privileges. Authentication is delegated to Caelestia/Quickshell's existing PAM integration inside the pinned Caelestia shell package. The remaining risk is live runtime correctness, not privilege expansion.

## Residual Risks

- Live WlSessionLock and PAM unlock behavior must be smoke-tested in the actual graphical session.
- There is no fallback lock client if Caelestia is not running or IPC is unavailable.

# Review Change - Axiom Remove Default Keep Awake

## Result

PASS.

## Blocking Findings

None.

## Scope Review

- In scope: removed the Axiom-local `axiom-caelestia-keep-awake` helper from `hosts/axiom/default.nix`.
- In scope: removed startup hook `07-caelestia-keep-awake`, so Axiom no longer runs `idleInhibitor enable` by default.
- In scope: updated README and wiki current truth to describe Keep Awake as manual while preserving the 15 minute lock / 30 minute DPMS policy.
- No out-of-scope changes to lock implementation, Hypridle timing, automatic sleep, polkit/logind permissions, or Caelestia shell startup were introduced.

## Correctness Review

- The implementation removes the exact default-enable path: the generated helper and the startup hook that invoked it.
- Manual `caelestia shell idleInhibitor enable|disable|toggle` commands remain documented and available.
- The recently aligned Caelestia idle timer settings remain unchanged: 900 second `lock`, 1800 second `dpms off` / `dpms on`, and no 600 second sleep action.
- The task correctly records the residual runtime caveat: if a previous session persisted Keep Awake enabled, the user may need to toggle it off once after deployment.

## Verification Review

- `docs/test-report.md` includes targeted Nix assertions proving no evaluated startup hook or pre-start script runs `idleInhibitor enable`, the old helper name is absent, and the 900/1800 idle policy remains.
- Focused search evidence distinguishes the expected manual README command from removed default startup wiring.
- `git diff --check` and the Axiom toplevel build both passed.

## Security Lens

Security lens applied because the change touches session idle and power behavior.

No blocker found. The change removes a default idle inhibitor and does not add privileged commands, broaden polkit/logind permissions, expose secrets, change authentication, or create a new trust boundary. Manual Keep Awake remains a user-session action.

## Residual Risk

- Live idle timing was not tested to avoid disrupting the desktop session. Post-deploy smoke should confirm Axiom does not force Keep Awake back on and that the 15/30 idle policy behaves as expected.

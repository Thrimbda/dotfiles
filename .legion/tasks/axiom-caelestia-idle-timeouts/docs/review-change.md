# Review Change - Axiom Caelestia Idle Timeouts

## Result

PASS.

## Blocking Findings

None.

## Scope Review

- In scope: `hosts/axiom/default.nix` now declares Axiom-owned Caelestia `general.idle` settings with 900 second lock and 1800 second DPMS only.
- In scope: the existing Axiom Caelestia pre-start migration now updates the persisted mutable `shell.json` for launcher favorites and `general.idle`, preserving unrelated settings.
- In scope: active README and wiki current-truth entries now explain aligned Caelestia/Hypridle idle timing and absence of automatic idle sleep.
- No out-of-scope Hypridle timing, polkit/logind permission, lock-client, or sleep-inhibitor redesign was introduced.

## Correctness Review

- The implementation addresses the reported behavior directly: Caelestia's upstream 180 second lock can no longer remain the active default for Axiom because both generated settings and the persisted config migration set `general.idle.timeouts` to 900/1800.
- The 600 second `systemctl suspend-then-hibernate` default is removed from Axiom-owned Caelestia settings by replacing the timeout list with exactly two entries.
- The helper uses `--argjson idle` for the generated JSON object instead of stringifying the idle policy, and a representative jq syntax check passed.
- The migration remains narrow: it updates `.general.idle` and normalizes launcher favorites, without replacing the entire shell config.

## Verification Review

- `docs/test-report.md` includes targeted Nix assertions for Caelestia idle settings, migration helper text, Hypridle values, and absence of sleep/hibernate strings.
- `git diff --check`, focused automatic-sleep searches, jq filter validation, and the Axiom toplevel build all passed.
- Live idle timing and suspend tests were appropriately skipped because they would disrupt the active graphical session; a post-deploy smoke check is recorded.

## Security Lens

Security lens applied because the change touches session idle behavior and power actions.

No blocker found. The change removes an automatic idle sleep path and does not broaden polkit/logind permissions, add privileged commands, change authentication, expose secrets, or introduce a new trust boundary. The config migration writes only to the user's existing Caelestia shell config path during the user's desktop session.

## Residual Risk

- Caelestia and Hypridle now have aligned duplicate lock/DPMS thresholds. This is intentional and documented, but live session smoke should confirm there is no surprising UX after deployment.

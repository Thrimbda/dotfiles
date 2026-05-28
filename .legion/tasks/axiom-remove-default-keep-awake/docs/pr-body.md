## Summary

- Remove Axiom's startup helper/hook that default-enabled Caelestia Keep Awake / `idleInhibitor`.
- Keep manual Keep Awake commands available while preserving 15 minute lock and 30 minute DPMS idle timing.
- Update README and Legion wiki current truth so Keep Awake is manual, not default-on.

## Verification

- Targeted `nix eval --impure --json --expr '...'` assertions for startup hooks, helper absence, and unchanged 900/1800 idle settings
- Focused active config and wiki current-truth searches
- `git diff --check`
- `nix build --no-link .#nixosConfigurations.axiom.config.system.build.toplevel`

## Notes

- Live idle timing was not tested to avoid disrupting the active desktop.
- If the previous session persisted Keep Awake enabled, toggle it off manually once after deploying this generation.

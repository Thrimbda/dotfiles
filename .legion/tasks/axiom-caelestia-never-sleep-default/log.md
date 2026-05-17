# Axiom Caelestia Never Sleep Default - Log

## 2026-05-17

- Entry: User reported Axiom still sleeps and requested Caelestia be adjusted so the default is never sleep.
- Brainstorm: Created follow-up contract scoped to Axiom Caelestia session behavior. Current hypothesis is that `idleInhibitor enable` alone is insufficient; implementation should keep that UI state but add a graphical-session sleep inhibitor.
- Design: Wrote and reviewed standard RFC. Decision is to keep Caelestia `idleInhibitor enable` as visible UI state and add an Axiom-local `systemd-inhibit --what=sleep --mode=block` service tied to `hyprland-session.target`.
- Engineer: Added `axiom-caelestia-never-sleep.service`, backed by an `axiom-caelestia-never-sleep` script that runs `systemd-inhibit --what=sleep --mode=block`. Updated Axiom README live checks and escape hatch. `git diff --check` passed.
- Verify: Targeted Nix assertions passed, `git diff --check` passed, Axiom toplevel build passed, and post-build script assertions proved both Caelestia `idleInhibitor enable` and `systemd-inhibit --what=sleep --mode=block` wiring.
- Review: PASS. No blocking findings. Scope remains Axiom-local, security lens found no privilege expansion, and residual risk is limited to post-deploy live session smoke.
- Walkthrough: Wrote implementation walkthrough and PR body summarizing session sleep inhibitor behavior, validation, review result, and post-deploy smoke.
- Wiki: Added task summary and updated current Axiom power decisions, Keep Awake validation pattern, and post-deploy maintenance smoke for the session sleep inhibitor.

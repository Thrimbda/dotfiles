# Change Review: Axiom Caelestia Keep Awake Default

## Verdict

PASS

## Findings

No blocking findings.

## Scope Review

- Production changes are scoped to `hosts/axiom/default.nix` and `hosts/axiom/README.org`.
- The change removes the custom `axiom-sleep-mode` package, power-mode launcher entries, direct Axiom Hypridle override, and custom sleep-inhibitor user services.
- The replacement uses a single Axiom user service that enables Caelestia `idleInhibitor` at Hyprland/Caelestia session start.
- No global `config/hypr/hypridle.conf` behavior, unrelated hosts, or Caelestia upstream QML files were modified.

## Correctness Review

- `axiom-caelestia-keep-awake.service` is wanted by `hyprland-session.target`, wants `caelestia-shell.service`, and orders itself after `caelestia-shell.service`.
- The helper script retries `caelestia shell idleInhibitor enable`, which handles shell IPC startup latency without adding another persistent mode state.
- README now points users to Caelestia's own `idleInhibitor` shell entrypoints and states the graphical-session boundary.
- Verification proves old wrapper services/packages/direct Hypridle override are absent in the evaluated Axiom config.

## Security Lens

Applied because the change affects power/session behavior.

- This change removes a custom `systemd-inhibit --what=sleep --mode=block` user service rather than adding one.
- It does not widen polkit power action allowlists, does not grant logind `ignore-inhibit`, and does not add sudo/system management paths.
- The remaining behavior is session-scoped Caelestia IPC. A local `c1` process can already control the user's Caelestia shell state; this does not introduce a new privilege boundary.

## Verification Review

Verification evidence is adequate for static readiness:

- Targeted Nix assertions passed.
- Host-level stale wrapper grep passed.
- `git diff --check` passed.
- Axiom toplevel build passed and built the new `axiom-caelestia-keep-awake` script and user service.

## Residual Risks

- Live Axiom session smoke is still needed to confirm Caelestia's Keep Awake UI shows enabled after login.
- This is not a headless/system-wide no-sleep policy. If the graphical session or Caelestia shell does not start, the inhibitor will not be active.

## Conclusion

The change is ready for walkthrough, wiki writeback, and PR delivery.

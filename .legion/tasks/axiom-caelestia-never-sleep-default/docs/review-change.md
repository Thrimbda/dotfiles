# Change Review: Axiom Caelestia Never Sleep Default

## Verdict

PASS

## Blocking Findings

None.

## Scope Review

- Production changes are limited to `hosts/axiom/default.nix` and `hosts/axiom/README.org`.
- The implementation keeps the existing Caelestia `idleInhibitor enable` helper and adds one Axiom-local user service, `axiom-caelestia-never-sleep.service`.
- No global `config/hypr/hypridle.conf`, other hosts, upstream Caelestia QML, polkit allowlist, or `axiom-sleep-mode` launcher/toggle system was modified.
- Legion evidence is scoped to `.legion/tasks/axiom-caelestia-never-sleep-default/**`.

## Correctness Review

- `axiom-caelestia-never-sleep` executes `systemd-inhibit --what=sleep --who="Axiom Caelestia" --why="Axiom Caelestia session defaults to never sleep" --mode=block` with a long-running `tail -f /dev/null` child.
- `axiom-caelestia-never-sleep.service` is wanted by, ordered after, and `PartOf=` `hyprland-session.target`, matching the RFC's graphical-session boundary.
- `Restart=always` and `RestartSec=5s` reestablish the inhibitor if the child process exits unexpectedly while the session remains active.
- The existing `07-caelestia-keep-awake` hook remains backgrounded through `nohup`, so the new enforcement layer does not make the ordered startup hook chain wait for Caelestia IPC.
- README now documents both runtime checks and the current-session escape hatch.

## Security Lens

Applied because the change affects session power behavior and login1 sleep inhibition.

- The change does not grant new suspend/shutdown permissions, does not widen polkit, and does not grant `ignore-inhibit` behavior.
- The new inhibitor is a local user-session process that blocks sleep; it does not expose a privileged command path or accept user-controlled input.
- The operational escape hatch is `systemctl --user stop axiom-caelestia-never-sleep.service`, which is scoped to the user's own session.

## Verification Review

Verification evidence is adequate for static readiness:

- Targeted Nix shape assertions passed.
- `git diff --check` passed.
- Axiom toplevel build passed and built `axiom-caelestia-never-sleep.drv`, `unit-axiom-caelestia-never-sleep.service.drv`, and the Axiom system derivation.
- Post-build script assertions passed and prove both Caelestia Keep Awake IPC wiring and the new sleep blocker script contents.

## Residual Risks

- Live Axiom session smoke is still needed after deployment to confirm `systemd-inhibit --list` shows the blocker and Caelestia reports Keep Awake enabled.
- Manual suspend from the active graphical session is intentionally blocked by default until the inhibitor service/session is stopped.
- The change is not a pre-login or headless no-sleep policy.

## Conclusion

The change is ready for walkthrough, wiki writeback, and PR delivery.

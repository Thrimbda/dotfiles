# RFC Review: Axiom Caelestia Never Sleep Default

## Verdict

PASS

## Blocking Findings

None.

## Review Lenses

### Scope

The RFC keeps production scope to `hosts/axiom/default.nix` and `hosts/axiom/README.org`. It explicitly avoids global Hypridle changes, other hosts, upstream Caelestia QML, polkit widening, and the older `axiom-sleep-mode` launcher/toggle system.

### Complexity

The selected design is smaller than restoring the old power-mode state machine and more complete than only editing Hypridle. A single `systemd-inhibit` user service tied to `hyprland-session.target` is an appropriate enforcement layer for the stronger default.

### Assumptions

The RFC correctly makes the key behavior explicit: manual suspend from the active graphical session is blocked by default. That matches the user's "never sleep" request and is not hidden as an implementation detail.

### Verification

Verification is concrete and implementable. The proposed Nix/static checks can prove the service exists, is session-scoped, uses `systemd-inhibit --what=sleep --mode=block`, keeps the Caelestia Keep Awake helper backgrounded, and does not reintroduce `axiom-sleep-mode`. The live smoke checks are appropriately deferred because running suspend tests from this tooling session is disruptive.

### Rollback

Rollback is clear. A git revert removes the declarative service, and `systemctl --user stop axiom-caelestia-never-sleep.service` provides an operational current-session escape hatch.

## Suggestions

- In implementation, prefer a long-running child command with a deterministic store path, such as `${pkgs.coreutils}/bin/tail -f /dev/null`, rather than relying on shell built-ins.
- Include `Restart=always` or equivalent so the inhibitor is restored if the child process exits unexpectedly during the session.

## Conclusion

The RFC is sufficiently bounded, verifiable, and rollbackable. Implementation may proceed.

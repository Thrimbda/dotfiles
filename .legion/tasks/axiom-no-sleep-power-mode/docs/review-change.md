# Change Review: Axiom No-Sleep Power Mode

## Verdict

PASS

## Findings

No blocking findings.

## Scope Review

- Production changes are limited to `hosts/axiom/default.nix`.
- The repository global `config/hypr/hypridle.conf` remains unchanged, so other hosts keep their existing Hypridle behavior.
- The implementation matches the reviewed Option D: Axiom-local mode command, desktop launcher entries, Axiom Hypridle override, no-sleep inhibitor service, and Hyprland-session apply service.
- No unrelated CPU/GPU power tuning, Caelestia UI redesign, or global suspend/hibernate masking was introduced.

## Correctness Review

- Missing mode state defaults to `no-sleep`, satisfying the default behavior.
- `axiom-sleep-mode maybe-suspend` only calls suspend when mode is `allow-sleep`; otherwise it returns successfully after a best-effort notification.
- `axiom-no-sleep-inhibit.service` uses `systemd-inhibit --what=sleep --mode=block` with `sleep infinity`, which blocks accidental direct sleep requests while active.
- `axiom-sleep-mode-apply.service` is tied to `hyprland-session.target`, applying the selected mode at desktop-session start without making the inhibitor a global boot service.
- The desktop toggle path is present as fixed launcher entries plus the `axiom-sleep-mode` command.

## Security Lens

Applied because the change affects power/session behavior and user service control.

- The change does not widen the existing polkit allowlist and does not add `ignore-inhibit`, generic `login1.*`, sudo, or system unit management rights.
- The new mode command is user-owned session tooling. A process running as `c1` can switch the user's desktop sleep mode, but that is not a new privilege boundary for this single-user workstation configuration.
- Direct forced suspend while the inhibitor is active still requires bypassing logind inhibitors; this change does not grant that capability.
- Best-effort notifications do not carry secrets and failure to notify does not change power behavior.

## Verification Review

Verification evidence is adequate for static readiness:

- Targeted Nix assertions passed for generated Hypridle text, unchanged global Hypridle source, inhibitor service, apply service, script package, and launcher package count.
- `git diff --check` passed.
- Axiom toplevel build passed and built the relevant script, launcher, Hypridle, and user-service derivations.

## Residual Risks

- Live long-idle behavior still needs post-deploy smoke testing in the real Axiom Hyprland session.
- If the user intentionally selects `allow-sleep`, that state persists until changed back; this is documented in the RFC and should be understood as an explicit desktop mode override.

## Conclusion

The change is ready for reviewer-facing walkthrough and PR delivery.

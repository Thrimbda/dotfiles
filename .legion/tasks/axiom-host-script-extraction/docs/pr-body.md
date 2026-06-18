## Summary
- reduce `hosts/axiom/default.nix` from 667 to 451 lines by moving remaining inline scripts/policy into focused modules
- add focused modules for HDMI audio readiness, ToDesk service setup, and libvirt/virt-manager policy
- extend Caelestia and healthchecks modules so Axiom host declares facts instead of script bodies

## Verification
- `git diff --check`
- focused `nix eval` for Caelestia mutable config/polkit, HDMI audio, ToDesk, libvirt/virt-manager, and healthcheck runners
- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel`

## Notes
- Polkit action set is unchanged; it moved from Axiom host inline JS to opt-in Caelestia local controls.
- No live deployment/session/audio/ToDesk smoke was performed.

Legion evidence:
- `.legion/tasks/axiom-host-script-extraction/docs/test-report.md`
- `.legion/tasks/axiom-host-script-extraction/docs/review-change.md`
- `.legion/tasks/axiom-host-script-extraction/docs/report-walkthrough.md`

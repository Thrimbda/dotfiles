## Summary
- shrink `hosts/axiom/default.nix` from 451 to 387 lines by moving remaining host-local policy into owning modules
- add focused options for Gatus endpoint inventory, Cloudflared/SSH/Clash service policy, Clash GUI autostart, workstation zram/logrotate/NM policy, and LAN firewall allows
- preserve endpoint inventory, ingress, resource/OOM values, firewall CIDR/ports, zram, and NetworkManager facts

## Verification
- `git diff --check`
- focused `nix eval` for Gatus endpoints, Cloudflared ingress, service resource policy, firewall, NetworkManager, zram, and logrotate facts
- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel`

## Notes
- Security/operability review passed; no public exposure, permission, or firewall expansion was found.
- No live deployment or runtime smoke was performed.

Legion evidence:
- `.legion/tasks/axiom-host-policy-extraction/docs/test-report.md`
- `.legion/tasks/axiom-host-policy-extraction/docs/review-change.md`
- `.legion/tasks/axiom-host-policy-extraction/docs/report-walkthrough.md`

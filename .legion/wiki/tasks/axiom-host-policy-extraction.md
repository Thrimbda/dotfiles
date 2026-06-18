# Axiom Host Policy Extraction

## Status
Implementation verified; PR pending.

## Summary
Third Axiom host slimming pass. After `axiom-host-script-extraction` removed large inline script bodies, this task moved remaining host-local policy blocks into owning modules.

`hosts/axiom/default.nix` changed from 451 lines to 387 lines.

## Outputs
- `modules/services/gatus.nix` now owns common labels, public endpoint helpers, self endpoint generation, and status-page Cloudflared ingress contribution.
- `modules/services/cloudflared.nix` now owns connector restart/OOM/resource policy via `servicePolicy`.
- `modules/services/ssh.nix` now owns SSHD service policy via `serviceConfig`.
- `modules/desktop/apps/clash-verge.nix` now owns Clash daemon resource policy and GUI autostart drop-in policy.
- `modules/profiles/role/workstation.nix` now owns workstation zram, logrotate check suppression, user manager OOM normalization, and standard NetworkManager ethernet profile generation.
- `modules/system/firewall.nix` now owns typed LAN-only TCP allow rules.

## Verification
- `git diff --check` passed.
- Focused Nix facts eval confirmed rendered Gatus endpoints, Cloudflared ingress, service resource policy, firewall rule, NetworkManager profile, zram, and logrotate facts.
- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel` passed.

## Review
`docs/review-change.md` passed. Security/operability lens was applied because firewall, remote-access, restart, and OOM policy moved. No exposure, permission, or resource-priority weakening was found.

## Follow-Up
Runtime validation remains post-deploy: check Cloudflared/Gatus reachability, firewall behavior, Clash service and GUI autostart, NetworkManager profile activation, zram/logrotate state, and critical service OOM/resource settings.

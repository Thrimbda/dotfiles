# Report Walkthrough: Axiom Host Policy Extraction

## Mode
implementation

## Reviewer Summary
This is the third Axiom host slimming pass. After PR #94 moved inline scripts out of `hosts/axiom/default.nix`, this pass moves remaining host-local policy blocks into owning modules.

Host size changed from 451 lines to 387 lines.

## What Changed
- Extended `modules.services.gatus` with common labels, typed public endpoints, self endpoint, and Cloudflared public-hostname contribution.
- Extended `modules.services.cloudflared` with `servicePolicy` for restart/OOM/resource behavior.
- Extended `modules.services.ssh` with SSHD service policy ownership.
- Extended `modules.desktop.apps.clash-verge` with daemon service policy and GUI autostart drop-in ownership.
- Extended `modules.profiles.workstation` with zram, logrotate, user manager OOM, and NetworkManager ethernet profile options.
- Added `modules.system.firewall.lanTcpAllows` for typed LAN-only TCP firewall allowances.
- Updated `hosts/axiom/default.nix` to pass facts and enablement instead of maintaining full policy blocks.

## Behavior Preserved
- Gatus endpoints remain `opencode-axiom`, `vaultwarden-web`, and `status-page` with the same conditions and labels.
- Cloudflared ingress still exposes opencode and status page and keeps fallback `http_status:404`.
- Critical services retain previous restart, memory, and OOM settings.
- Clash GUI autostart keeps `Restart=on-failure`, `MemoryLow=256M`, and `OOMScoreAdjust=0`.
- LAN research workbench allow remains limited to `192.168.50.0/24` TCP ports `5173,8765`.
- `enp14s0` NetworkManager profile, zram settings, and logrotate check behavior remain equivalent.

## Verification
See `docs/test-report.md`.

Passed:
- `git diff --check`
- focused Nix facts eval
- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel`

## Review
See `docs/review-change.md`.

Decision: PASS.

Security/operability lens was applied because firewall, remote-access, restart, and OOM policy moved. No exposure or permission expansion was found.

## Residual Risk
Runtime validation was not performed. After deployment, check systemd service status, Gatus/Cloudflared reachability, firewall behavior, Clash GUI/service behavior, and NetworkManager profile activation.

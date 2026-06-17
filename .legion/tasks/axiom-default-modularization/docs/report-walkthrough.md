# Walkthrough: Axiom Default Modularization

Mode: implementation

## What Changed
- Split Axiom's inline service mechanics into focused modules:
  - `modules/services/reverse-ssh.nix` owns autossh reverse tunnel systemd wiring and known-host registration.
  - `modules/services/opencode-server.nix` owns the local opencode server plus optional Gatus and Cloudflared public integration.
  - `modules/services/healthchecks.nix` owns the repeated systemd timer/service, failure counter, threshold, and restart-target pattern.
- Simplified `hosts/axiom/default.nix` so it now declares host facts and module inputs instead of embedding whole service implementations.
- Removed clear Axiom duplication/no-op config: Caelestia-unused wallpaper mode, duplicated workstation/profile defaults, duplicate NetworkManager enable, duplicate opencode endpoint facts, inline autossh service, inline healthcheck timer blocks, and broad Axiom firewall ranges.
- Cleaned small shared-module debt: Calibre now uses configurable user/group defaults, Cloudflared has a first-class `ingress` option, and Gnome Keyring drops an unused binding.

## Preserved Behavior
- Cloudflared public ingress still resolves to `opencode-axiom`, `status-axiom`, then `http_status:404`.
- Gatus still checks `opencode-axiom`, `vaultwarden-web`, and `status-page`.
- Reverse SSH still forwards `127.0.0.1:2223` on `8.159.128.125` to local SSH port `22`.
- Opencode still serves on `127.0.0.1:4096` from `/home/c1/.opencode/bin/opencode`.
- Caelestia idle migration and the Hyprland 0.53.x color-management workaround remain intact.

## Verification
- `nix eval .#nixosConfigurations.axiom.config.networking.hostName --json` passed.
- Final facts eval confirmed Cloudflared ingress, Gatus endpoint names, reverse SSH command, opencode command, healthcheck timers, and narrower firewall output.
- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel` passed.

Evidence: `docs/test-report.md`.

## Review
- `docs/review-change.md` verdict: PASS.
- Security lens was applied because the change touches SSH, Cloudflared ingress, and firewall policy.
- No blocking findings.

## Residual Follow-Up
- `modules/desktop/hyprland.nix` still has broader Axiom-flavored desktop policy. It should be a separate desktop/keybinding cleanup, not part of this service/host modularization.

## Summary
- modularize Axiom reverse SSH, opencode server, and healthcheck wiring into focused service modules
- simplify `hosts/axiom/default.nix` by deleting duplicate/no-op defaults and moving repeated service mechanics behind module inputs
- add first-class Cloudflared ingress support and clean small shared-module hardcoding/unused bindings

## Validation
- `nix eval .#nixosConfigurations.axiom.config.networking.hostName --json`
- key facts eval for Cloudflared ingress, Gatus endpoints, reverse SSH, opencode, healthcheck timers, and firewall output
- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel`

## Notes
- Caelestia idle migration and the Hyprland 0.53.x color-management workaround are intentionally preserved.
- No live deploy, suspend/hibernate, Cloudflare API, or real remote autossh test was run.

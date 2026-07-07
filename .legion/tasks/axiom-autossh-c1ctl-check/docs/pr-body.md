# Summary

- Remove the periodic Axiom autossh endpoint systemd healthcheck/timer.
- Move the endpoint identity diagnostic to `c1ctl autossh check`.
- Keep cloudflared and Clash healthchecks intact.

# Validation

- `nix eval --impure --json .#nixosConfigurations.axiom.config.systemd.services --apply 'services: builtins.hasAttr "autossh-reverse-ssh-healthcheck" services'`
- `nix eval --impure --json .#nixosConfigurations.axiom.config.systemd.timers --apply 'timers: builtins.hasAttr "autossh-reverse-ssh-healthcheck" timers'`
- `nix eval --impure --json .#nixosConfigurations.axiom.config.modules.services.healthchecks.checks --apply 'checks: builtins.attrNames checks'`
- `nix build .#c1ctl --no-link --print-out-paths --show-trace --impure`
- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --no-link --print-out-paths --show-trace --impure`
- `c1ctl help autossh`
- `c1ctl which autossh`
- `c1ctl autossh check`

# Usage

After deployment, run on demand:

```bash
c1ctl autossh check
```

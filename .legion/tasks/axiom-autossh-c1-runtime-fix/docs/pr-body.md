# Summary

- Change Axiom autossh from `root@8.159.128.125` to `c1@8.159.128.125`.
- Add a service-specific known-hosts file for the redeployed remote host.
- Make autossh service and endpoint-key healthcheck ignore stale user known-hosts state while preserving strict host-key validation.

# Validation

- `nix eval --raw --impure .#nixosConfigurations.axiom.config.systemd.services.autossh-reverse-ssh.serviceConfig.ExecStart`
- `nix eval --raw --impure .#nixosConfigurations.axiom.config.systemd.services.autossh-reverse-ssh-healthcheck.serviceConfig.ExecStart`
- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --no-link --print-out-paths --show-trace --impure`
- Service-style `ssh` smoke using the generated service-specific known-hosts file to `c1@8.159.128.125`
- Temporary reverse tunnel identity smoke for remote `127.0.0.1:2223`

# Deployment

After merge, apply on Axiom:

```bash
sudo nixos-rebuild switch --flake .#axiom --show-trace --impure
sudo systemctl restart autossh-reverse-ssh.service
```

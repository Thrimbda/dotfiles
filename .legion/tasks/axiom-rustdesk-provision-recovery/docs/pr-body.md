## Summary

- Recover canonical interrupted Axiom RustDesk provisioning attempts instead of
  permanently failing later `nixos-rebuild` runs with `attempt-used`.
- Preserve a valid pending `ready-to-finalize` state without rerunning the
  password or bypassing manual remote-auth confirmation.
- Trigger the updated provision script on the next NixOS switch without bumping
  the persistent revision and replaying valid final stamps.

## Validation

- `git diff --check`
- `nix eval --impure --raw .#nixosConfigurations.axiom.config.system.build.toplevel.drvPath`
- `nix build --impure --dry-run .#nixosConfigurations.axiom.config.system.build.toplevel`
- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel`
- Generated script `bash -n` and generated unit `systemd-analyze verify`

See `.legion/tasks/axiom-rustdesk-provision-recovery/docs/test-report.md` for
the exact artifacts and evidence boundary.

## Security

The root-owned secret path, password input, operation lock, canonical state
checks, and explicit finalizer are unchanged. The only new mutation removes a
validated root-owned current attempt after the lock is acquired. The design and
change reviews passed with the secret/state security lens applied.

## Required Post-Merge Check

Run the normal privileged Axiom `nixos-rebuild switch --flake .#axiom` flow and
confirm `rustdesk-provision.service` no longer fails with `attempt-used`.

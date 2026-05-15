## Summary

- Create `/var/lib/todesk` declaratively for `axiom` with `0700 c1 users` permissions.
- Add a host-local `todesk` systemd service that starts `todesk service` as `c1` after network is online.
- Keep the change scoped to ToDesk runtime support; no firewall or package-version changes.

## Verification

- `nix eval` confirmed the expected tmpfiles rule and `systemd.services.todesk` values.
- `ss -tunp | rg -i 'todesk|ToDesk'` confirmed `ToDesk_Service` owns the external HTTPS connection and the GUI connects over localhost.

## Notes

- `nixos-rebuild switch` was intentionally not run.
- Security review tightened the state directory from the manual diagnostic's `0755` to `0700` because ToDesk writes auth/private state there.

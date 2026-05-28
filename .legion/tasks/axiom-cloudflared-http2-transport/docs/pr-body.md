## Summary

- Force axiom's cloudflared tunnel connector to use HTTP/2 transport by adding `protocol = "http2"` to its host-level `extraConfig`.
- Preserve the existing tunnel id, credentials path, hostname, ingress origin, opencode service, and Cloudflare Access setup.
- Add Legion task evidence for design-lite, verification, review, and delivery.

## Verification

- PASS: `nix eval .#nixosConfigurations.axiom.config.environment.etc.\"cloudflared/config.yml\".text --raw`
- PASS: `nix eval .#nixosConfigurations.axiom.config.systemd.services.cloudflared.serviceConfig.ExecStart --raw`
- PASS: `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --dry-run`
- Known unrelated failure: `nix flake check --no-build` still fails on existing `apps.x86_64-linux.install` / `mkApp` path-vs-string shape.

## Notes

- Runtime deploy/restart was not performed from this session because passwordless sudo is unavailable.
- A temporary user-level HTTP/2 connector is currently keeping the hostname reachable; stop it after the system service is deployed and healthy.

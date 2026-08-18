## Summary

- Deploy the 1Ex portfolio Custom Account Source adapter on Acorn behind `https://1ex-portfolio.0xc1.wang`.
- Build the pinned Rust source locally, run it as a hardened loopback-only systemd service, and proxy it through nginx with ACME TLS.
- Keep the runtime identity in an Acorn-only age secret and use the adapter's existing 43-character HMAC-derived Bearer authentication.
- Apply the measured 5.8-second upstream read timeout through a narrow Nix build-time patch.

## Verification

- `nix build .#nixosConfigurations.acorn.config.system.build.toplevel -L`
- Required local-build remote activation command completed successfully.
- Adapter and nginx active; port 8090 listens only on `127.0.0.1`.
- ACME succeeded; Cloudflare and Google DoH resolve the hostname to `8.159.128.125`.
- Public unauthenticated request returns `401`; authenticated accounts and positions requests return `200` with five live positions.
- Vendor `Cargo.toml`, `Cargo.lock`, and `src/main.rs` exactly match upstream `8dcf21f9a2549212bff4b380dc5daf3f5c1236f9` before the derivation patch.

## Operational Note

The upstream auth and Fund endpoints can fail transiently. The adapter intentionally returns `502` rather than a partial portfolio response; callers should retry when availability matters.

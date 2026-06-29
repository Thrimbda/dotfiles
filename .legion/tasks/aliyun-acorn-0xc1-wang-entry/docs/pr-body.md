## Summary

- Add `status-axiom.0xc1.wang` nginx HTTPS endpoint on `aliyun-acorn`, protected by Basic Auth.
- Add `axiom-gatus-http` frp proxy from Axiom Gatus `127.0.0.1:8080` to Acorn remote TCP `18080`.
- Add encrypted agenix secrets for the status Basic Auth htpasswd/password material.

## Safety

- Keeps existing `0xc1.space` cloudflared routes unchanged.
- Does not expose `opencode-axiom.0xc1.wang`.
- Does not open `18080` in the NixOS firewall.
- Does not commit plaintext Basic Auth credentials.

## Validation

- `nix eval --raw ...aliyun-acorn...system.build.toplevel.drvPath`
- `nix eval --raw ...axiom...system.build.toplevel.drvPath`
- `nix build --dry-run ...aliyun-acorn...system.build.toplevel`
- `nix build --dry-run ...axiom...system.build.toplevel`
- `frpc verify -c /nix/store/zx5qfd4c7bmyic52520999vhb84vl91k-frpc.toml`
- `frps verify -c /nix/store/2lwaih24bp28g774jhvm4z3nikcc2yb0-frps.toml`
- Secret shape checks with `agenix -d -i /home/c1/.ssh/id_ed25519`, without printing secret contents.

## Post-deploy

- Add DNS-only Cloudflare records: `status-axiom.0xc1.wang -> 8.159.128.125`, `axiom.0xc1.wang -> 8.159.128.125`.
- Verify ACME, Basic Auth, live frp backend, external `18080` blocking, and SSH via `-p 2225`.

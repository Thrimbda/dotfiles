# Implementation Plan: Const X Azar Public Deployment

## 1. Source configuration

1. Add `hosts/acorn/modules/constx.nix`; import it from `hosts/acorn/default.nix`.
2. Add the `constx` gateway instance and only the two optional per-instance proxy extension hooks to `hosts/acorn/modules/auth-mini.nix`.
3. Preserve all existing instances byte-for-byte in their effective defaults; no allowlist or age secret changes.
4. Run parse, Nix evaluation, toplevel build and generated systemd/Nginx inspection before any remote switch.

## 2. Release staging

1. Use `git archive 45c21f0a2f437cb11cb5e316c29d5ff08cbef471` to transfer a clean source tree to an Azar `c1` staging directory; do not transfer local untracked work.
2. Invoke an ephemeral Nix shell with Node 22, Cargo/Rust and compiler prerequisites; set `CARGO_BUILD_JOBS=1`.
3. Build `constxd`, run `doctor` in an isolated temporary XDG state, calculate SHA-256, and place the executable at `/home/c1/.local/share/constx/releases/45c21f0a2f437cb11cb5e316c29d5ff08cbef471/constxd`.
4. Keep prior release artifacts but create no `current` symlink: the matching NixOS generation, not a mutable link, owns activation and rollback.

## 3. Switch order

1. Confirm the exact staged binary is executable and port 3210 remains unused.
2. Run the reviewed NixOS switch for `acorn` from the merged dotfiles tree with `axiom-tunnel` as `--build-host`, `azar` as `--target-host`, and both `--ask-sudo-password` and `--sudo`; password input comes only from the owner-only local file.
3. Verify local service, Nginx, Auth Mini gateway and ACME before changing public DNS.
4. Query Cloudflare by exact hostname; create only the absent DNS-only A record with `ttl: 1`, `proxied: false` and target `8.159.128.125`.

## 4. Canary and rollback

1. Check loopback health/ready and direct TLS via `curl --resolve`.
2. Check an anonymous request redirects to Auth Mini, not to Const X; then use an existing authorized account for browser workbench, SSE and attachment smoke.
3. If any failure occurs, stop/remove the new service or roll back the Nix generation before removing only the record created by this task. Preserve `/var/lib/constx` throughout; do not mutate a release symlink.

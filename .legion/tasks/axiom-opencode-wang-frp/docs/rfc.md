# RFC: Axiom OpenCode 0xc1.wang FRP Entry

## Decision

Create a new parallel `opencode-axiom.0xc1.wang` route:

- Cloudflare DNS proxied `A` record to `8.159.128.125`.
- Cloudflare Access self-hosted app/policy matching the existing `opencode-axiom.0xc1.space` allowlist intent.
- `aliyun-acorn` nginx HTTPS vhost with Cloudflare DNS-01 ACME.
- nginx origin Basic Auth for direct-origin bypass protection.
- nginx proxies to local frps backend `127.0.0.1:18081`.
- `axiom` frpc publishes local OpenCode `127.0.0.1:4096` as remote TCP `18081` on Acorn.

The existing `opencode-axiom.0xc1.space` Cloudflared route stays unchanged.

## Why This Shape

The user selected a new `.wang` parallel route after the ambiguity was called out: the same `.space` hostname cannot simultaneously remain a Cloudflare Tunnel route and become an Acorn `A` record without replacing the route.

OpenCode is sensitive. Cloudflare Access protects normal proxied traffic, but anyone who knows Acorn's IP could otherwise send a matching Host/SNI request directly to origin. Origin Basic Auth is therefore required as a second boundary unless a future task restricts origin access to Cloudflare IP ranges.

## Alternatives

### Replace `opencode-axiom.0xc1.space`

Rejected. This would mutate an existing working Cloudflared/Access route and risks downtime or auth drift for the current public OpenCode entrypoint.

### New `.wang` DNS-only A record without Cloudflare Access

Rejected. DNS-only would make nginx Basic Auth the only public auth layer and would not match the existing opencode Access security posture.

### New `.wang` proxied A with Cloudflare Access only

Rejected as insufficient. Direct origin access by IP + Host/SNI would bypass Access unless Acorn also restricts Cloudflare source IPs. Basic Auth is the smaller safe origin-side guard.

## Security Boundary

- Edge: Cloudflare Access app for `opencode-axiom.0xc1.wang`.
- Origin: nginx Basic Auth using agenix-managed htpasswd material.
- Transport: frp token auth remains host-local and unchanged.
- Backend: remote TCP `18081` is an nginx backend only; do not add it to Acorn NixOS firewall or Aliyun security group.
- No plaintext secrets in Nix store, Git, docs, PR body, or logs.

## Rollout

1. Update Nix config for Axiom frpc and Acorn nginx/ACME.
2. Create/update Cloudflare DNS and Access state.
3. Validate Nix evaluation/build and Cloudflare state.
4. Merge through PR.
5. Switch Axiom and Acorn live configs when privileged access is available.
6. Verify final public behavior: Access challenge first, then origin Basic Auth after Access login; direct origin with `--resolve` returns `401 Basic Auth`.

## Rollback

- Remove the Axiom frpc proxy and Acorn nginx/ACME vhost from Nix config.
- Delete or disable the Cloudflare DNS record and Access app/policy for `opencode-axiom.0xc1.wang`.
- Restart/reload `frpc`, `frps`, and nginx through normal NixOS switch or service reload.
- Existing `.space` route remains untouched throughout rollback.

## Verification

- Nix eval for Axiom frpc proxy includes `axiom-opencode-http` on remote port `18081`.
- Nix eval for Acorn nginx vhost uses ACME host `opencode-axiom.0xc1.wang` and proxies to `127.0.0.1:18081`.
- Nix eval for Acorn ACME cert uses Cloudflare DNS provider.
- Dry-run or build both affected NixOS toplevels.
- Cloudflare API verifies proxied `A` record and Access app/policy shape.
- Live deployment verifies `frpc` registers the proxy and the origin returns expected auth status.

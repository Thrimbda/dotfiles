# RFC: Acorn frps Dashboard Via Nginx

## Decision

Expose the frps dashboard as `frps-acorn.0xc1.wang` through Acorn nginx, while keeping the frps dashboard listener bound to `127.0.0.1:7500`. Create a DNS-only Cloudflare `A` record for the hostname pointing at Acorn `8.159.128.125`.

Use nginx Basic Auth as the user-facing authentication boundary for this task. Do not configure Cloudflare Access or native frps dashboard username/password in this change.

## Why This Shape

The frps dashboard is an HTTP service, unlike the frps control port. It can safely sit behind nginx as long as the dashboard listener stays loopback-only and the raw dashboard port is not opened publicly.

Using the existing nginx Basic Auth secret keeps the change minimal and avoids introducing a new plaintext frps dashboard password into Nix-generated TOML. A future task can add Cloudflare Access or a dedicated dashboard credential if needed.

## Alternatives

### Bind dashboard publicly

Rejected. Binding `webServer.addr = "0.0.0.0"` or opening TCP `7500` would expose operational metadata without the existing nginx authentication boundary.

### Use frps native dashboard credentials

Deferred. frps supports `webServer.user` and `webServer.password`, but this repo's frp module currently renders only the frp token from agenix. Adding another secret rendering path is larger than this task and unnecessary when nginx Basic Auth is the chosen boundary.

### Add Cloudflare Access now

Rejected for this task by user choice. The current task should only use nginx Basic Auth. A future task can add Cloudflare Access if the dashboard should get edge identity protection.

## Security Boundary

- Browser-facing auth: nginx Basic Auth from the existing agenix-managed htpasswd file.
- DNS: Cloudflare DNS-only `A` record; no Cloudflare Access app in this task.
- Dashboard listener: `127.0.0.1:7500` only.
- Public firewall: do not add TCP `7500`.
- frps control port: unchanged on TCP `7000`; this task does not proxy control traffic through nginx.
- Secrets: no plaintext frp token, dashboard password, Basic Auth password, or Cloudflare token in Git or Nix store templates.

## Rollback

- Remove `modules.services.frp.server.extraConfig.webServer` from Acorn.
- Remove the `frps-acorn.0xc1.wang` nginx vhost and ACME cert from Acorn.
- Delete or disable the Cloudflare DNS record for `frps-acorn.0xc1.wang` if the hostname should no longer resolve.
- Switch Acorn config and reload/restart frps/nginx through normal NixOS activation.
- Existing frp tunnels and public status/OpenCode routes remain unchanged.

## Verification

- Targeted Nix eval shows frps `webServer.addr = "127.0.0.1"` and `port = 7500`.
- Targeted Nix eval shows nginx vhost `frps-acorn.0xc1.wang` proxies to `http://127.0.0.1:7500` and has Basic Auth configured.
- Targeted Nix eval shows ACME cert for `frps-acorn.0xc1.wang` uses Cloudflare DNS-01.
- Targeted Nix eval shows TCP `7500` is not in Acorn `networking.firewall.allowedTCPPorts`.
- Cloudflare API verifies DNS-only `A frps-acorn.0xc1.wang -> 8.159.128.125`.
- Acorn toplevel dry-run/build succeeds.
- After live deployment and DNS availability, public HTTPS should challenge for Basic Auth and direct public TCP `7500` should be unreachable.

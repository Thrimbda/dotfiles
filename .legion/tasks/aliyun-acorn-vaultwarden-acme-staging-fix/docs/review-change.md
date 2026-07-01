# Review Change: Aliyun Acorn Low-Resource Rebuild Fix

## Decision

PASS

## Security Lens

Applied. This change affects auth-bearing HTTP/TLS exposure for Vaultwarden and the status vhost, plus OpenSSH service behavior.

## Blocking Findings

None.

## Confirmed

- The prior blocker is resolved: `status-axiom.0xc1.wang` and `vault.0xc1.space` bind only to `127.0.0.1:80` while ACME/TLS are staged off.
- Public `80/443` are removed from `networking.firewall.allowedTCPPorts` with `lib.mkForce`, overriding the nginx module default.
- Generated systemd units contain no ACME units and no Docker units.
- Docker service enablement and boot enablement both evaluate to `false`.
- Vaultwarden remains enabled and its local nginx reverse proxy locations remain configured.
- Low-resource slimming is in scope: dev runtimes, media tooling, Docker, host `nix-ld`, and local documentation outputs are removed for `aliyun-acorn`.
- OpenSSH daemon mode is appropriate for a low-resource public host that was timing out during socket-activated banner handling.

## Non-Blocking Notes

- Remote `nixos-rebuild switch` remains unproven because SSH to `8.159.128.125` still times out during banner exchange.

## Result

Ready to proceed to reviewer-facing walkthrough and PR lifecycle.

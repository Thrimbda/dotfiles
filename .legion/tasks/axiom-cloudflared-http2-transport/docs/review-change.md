# Review Change: Axiom Cloudflared HTTP2 Transport Fix

## Verdict

PASS.

## Blocking Findings

None.

## Scope Review

- In scope: `hosts/axiom/default.nix` now adds `protocol = "http2"` inside axiom cloudflared `extraConfig`.
- In scope: task-local Legion evidence under `.legion/tasks/axiom-cloudflared-http2-transport/**`.
- Not changed: opencode server, hostname, ingress origin, tunnel id, credential path, Cloudflare Access policy, Clash/DNS settings.

## Correctness Review

- The implementation matches the design-lite decision: set cloudflared edge transport to HTTP/2 at the generated config layer.
- Targeted Nix eval confirms the generated `/etc/cloudflared/config.yml` contains `"protocol":"http2"` while preserving the existing ingress and tunnel values.
- Targeted Nix eval confirms systemd `ExecStart` still uses `--config /etc/cloudflared/config.yml`, so the new field is consumed by the existing service path.
- Axiom toplevel dry-run evaluates successfully.

## Security Lens

Applied because this changes a tunnel transport/protocol boundary.

- No new public listener is introduced; opencode remains behind the existing loopback origin and Cloudflare Access path.
- No secret, token, credential path, route, or Access policy is changed.
- Switching cloudflared from QUIC to HTTP/2 preserves encrypted connector transport to Cloudflare and reduces failure exposure caused by the current fake-ip/UDP path.
- The temporary user-level connector is documented as an operational follow-up; it is not committed as a durable service or secret-bearing artifact.

## Non-blocking Notes

- `nix flake check --no-build` still fails on an existing `mkApp` path/string issue in `apps.x86_64-linux.install`; targeted axiom validation passes and the failure is outside this task's scope.
- Runtime service restart remains a deploy-time step because the current session lacks passwordless sudo.

## Residual Risk

- Permanent runtime recovery depends on deploying the NixOS change and restarting `cloudflared.service` on axiom.
- The temporary HTTP/2 connector should be stopped after the system service is healthy to avoid keeping an extra connector process around.

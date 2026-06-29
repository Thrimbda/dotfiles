# Change Review: Axiom FRPC Direct Route

Decision: PASS

## Blocking Findings

None.

## Scope Review

- The implementation only changes `hosts/axiom/default.nix` plus task-local Legion docs.
- The change is host-local to `axiom`; it does not alter the generic frp module or Clash Verge module.
- No Cloudflare, Aliyun security-group, nginx, frp token, Basic Auth secret, or firewall port changes are included.

## Correctness Review

- `frpc-aliyun-acorn-direct-route.service` installs `priority=8500 to 8.159.128.125/32 lookup main`, which should win over observed Clash/Meta policy rules at `9001/9002`.
- `frpc.service` has `After=`, `Wants=`, and `Requires=` on the route service, so normal start/boot activation runs the direct-route setup before frpc dials frps.
- The service uses a fixed destination IP already used by reverse SSH and frp config, now shared through `aliyunAcornPublicIp`.

## Security Lens

Applied because this changes routing/trust-boundary behavior for a remote access path.

- The route bypass is limited to `8.159.128.125/32`.
- It does not disable Clash/Meta globally.
- It does not open inbound ports.
- It does not expose `18080` publicly.
- It does not weaken frp token auth or nginx Basic Auth.

## Residual Risks

- Runtime validation requires deploying the new Axiom generation or local sudo access.
- If Clash/Meta later installs policy rules with priority lower than `8500`, this rule may stop winning; post-deploy `ip route get` validation should catch that.

## Verdict

Ready for PR. No implementation, scope, or security blockers found.

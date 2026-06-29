# Change Review: Aliyun Acorn 0xc1.wang Entry

Decision: PASS

## Blocking Findings

None.

## Scope Review

- The implementation only touches the approved surfaces: `hosts/axiom/default.nix`, `hosts/aliyun-acorn/default.nix`, `hosts/aliyun-acorn/secrets/secrets.nix`, encrypted Basic Auth secret files, and task-local Legion docs.
- Existing `0xc1.space` cloudflared hostnames remain unchanged.
- `opencode-axiom.0xc1.wang` is not exposed.
- Cloudflare DNS automation is not added.

## Security Lens

Applied because the change crosses auth, secrets, and public ingress boundaries.

- `status-axiom.0xc1.wang` has nginx `basicAuthFile` configured before public rollout.
- Basic Auth material is committed only as `.age` files; plaintext was not written into docs or Nix code.
- The nginx htpasswd secret is owned by `nginx:nginx`, matching the reader process.
- The frp backend port `18080` is not in `networking.firewall.allowedTCPPorts`.
- Existing Cloudflare Access posture for OpenCode is preserved by leaving OpenCode out of scope.

## Residual Risks

- Live DNS, ACME issuance, Aliyun security-group rules, and public auth behavior still need post-deploy verification.
- Basic Auth is an acceptable first-slice guard for status, but it is not a replacement for Cloudflare Access on sensitive services such as OpenCode.

## Verdict

Ready for PR. No implementation, scope, or security blockers found in local review.

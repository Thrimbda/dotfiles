# Review Change: FRP Agenix Deploy

Decision: PASS

Security lens applied: yes. This change touches token authentication, agenix secrets, public ports, and runtime secret exposure.

## Blocking Findings

None.

## Review Notes

- Scope matches `plan.md`: the change adds the frp service module, host wiring for `aliyun-acorn` and `axiom`, host-local age secrets, and task-local Legion evidence.
- The change also adds `.gitattributes` with `*.age binary` so encrypted age payloads are not treated as text by Git whitespace checks.
- `aliyun-acorn` enables `frps` and opens TCP `7000` and `2225` as required.
- `axiom` enables `frpc`, connects to `8.159.128.125:7000`, and maps local SSH to remote TCP `2225`.
- Final review confirmed the new frp remote port `2225` avoids the existing `hosts/azar` autossh reservation on remote loopback `2224`.
- Secret handling is acceptable: the token is generated as a 96-character hex string, encrypted in host-local age files, and only rendered from `/run/agenix/frp-token` at service start.
- Runtime TOML templates contain only `@FRP_TOKEN@`; the inspected render scripts contain only the agenix path and do not embed plaintext token material.
- Initial independent review noted an ineffective dependency on `age-secrets-frp-token.service`. Follow-up eval confirmed no such unit exists, so the dependency was removed and both host configs were revalidated.

## Non-blocking Suggestions

- Consider adding an `frps` `allowPorts` restriction later if more proxies are introduced; the current scope only needs remote `2225`.
- A future hardening pass could run frp under a dedicated system user instead of `c1`.

## Residual Risks

- Runtime service health and real network reachability still require deployment-time checks on the target hosts.
- Public exposure of `7000` and `2225` is intentional; operational security depends on token secrecy and SSH key-only access behind the proxy.

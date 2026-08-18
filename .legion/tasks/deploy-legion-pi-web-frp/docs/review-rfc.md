# RFC Re-Review

## Findings

No blocking findings.

## Reviewer Identity

- agentType: `review-rfc`
- displayName: `review-rfc-brisk-marten`

## Gate Assessment

- Security correctness: `plan.md:16,27` and `docs/rfc.md:52,78` define an exact PI WebSocket Origin allowlist and require foreign, including sibling-origin, and missing Origin requests to return `403` before Auth Mini or PI WEB. The decision is independent of Cookie contents and closes the prior cross-site WebSocket hijacking path.
- Nginx implementability and isolation: Acorn already supports HTTP-context `map` declarations (`modules/services/nginx.nix:34-46`), while `mkNodeProxyVhost` exposes per-vhost location configuration before proxying (`hosts/acorn/modules/auth-mini.nix:108-140`). A map result consumed only by the PI vhost can reject PI WebSocket upgrades without changing ordinary PI HTTP/API traffic or the status/OpenCode vhosts.
- Fail-closed verification: `docs/rfc.md:106` pairs foreign- and missing-Origin handshake denial using a non-secret sentinel Cookie with an authenticated exact-origin operator WebSocket check. This exercises both deny and allow branches without recording a real Cookie or token, and the configured edge `return 403` establishes that rejected requests do not reach the gateway or PI WEB.
- Legitimate behavior and rollback: same-origin browser WebSockets remain allowed, while long-lived HTTP/API behavior is outside the Origin condition. The existing staged deployment and full task-increment removal rollback (`docs/rfc.md:81-96,109-115`) remain executable and fail closed rather than requiring an authentication bypass.

## Verdict

The revised Standard RFC fully addresses the prior HIGH finding and is ready to return to implementation and verification.

**Exact verdict: PASS**

# Change Review

## Blocking Findings

No blocking findings.

The prior HIGH cross-site WebSocket hijacking finding is closed. This review supersedes the prior **FAIL** in this file.

## Closed Security Finding

### Exact PI WebSocket Origin enforcement

References: `hosts/acorn/modules/auth-mini.nix:244-274`, generated nginx config `/nix/store/4jq0vinh5rv75i90ghy7f7ipp8pwwrmc-nginx.conf:52-56,259-294`, `.legion/tasks/deploy-legion-pi-web-frp/docs/test-report.md:23-33`

- The nginx HTTP `map` evaluates its regular expressions in declaration order. The anchored exact-origin allow branch precedes the generic WebSocket reject branch, so `Origin: https://pi-axiom.0xc1.wang` is allowed while sibling, foreign, path/port-suffixed, and other origins are rejected. `~*` permits only case variation in the scheme/host, which is the same origin semantically.
- A missing Origin produces the map key `websocket:` and matches the reject branch. The PI location's `return 403` runs before proxy content handling, so rejected handshakes do not reach FRP, Auth Mini, or PI WEB.
- Requests without `Upgrade: websocket` take `default 0`; ordinary PI HTTP/API and long-lived non-WebSocket traffic are not gated. The map variable is consumed only in the PI vhost. Generated OpenCode and status locations contain no guard.
- Live differential probes support the static result: sibling, foreign, and missing-Origin handshakes with a non-secret sentinel Cookie returned `403`; the exact PI Origin reached normal unauthenticated Auth Mini behavior and returned `302`. Because the edge decision does not inspect Cookie contents, a sentinel Cookie is sufficient negative evidence. Authenticated operator evidence separately confirms the PI page, session stream, and terminal still work.

## Accepted Residuals

### Established WebSockets outlive authentication changes

Auth Mini authorizes the handshake, but logout or later session expiry does not terminate an established connection. The 24-hour nginx timeouts support the approved long-connection requirement. Operators must disconnect active sockets during suspected session compromise. This is explicitly accepted by the revised RFC.

### FRP server identity is not verified

FRP uses token authentication and transport encryption without pinned frps certificate identity (`modules/services/frp.nix:24-33`). Active MITM remains outside the approved task threat model. This is pre-existing accepted security debt, not a regression introduced by this change.

### Runtime and disruptive rollback evidence remain limited

PI WEB, `node-pty`, and the upstream user units remain persistent but imperative rather than Nix-reproducible. The final verifier did not perform a reboot, logout, restart, or rollback, and the authenticated positive UI/WebSocket gate is operator-supplied. Enabled units, `Linger=yes`, persistent paths, retained generations, exact evaluated/deployed configuration, and live end-to-end behavior make these evidence limits non-blocking.

## Security And Boundary Review

- The public path remains PI WEB `127.0.0.1:8504` -> Auth Mini gateway `127.0.0.1:7782` -> FRP `18082` -> Acorn nginx `443`. FRP maps the authenticated gateway, never PI WEB directly (`hosts/axiom/default.nix:1794-1800,1843-1849`).
- Axiom keeps `7782` and `8504` out of its firewall and configures both services for loopback; Acorn keeps wildcard-bound `18082` out of its forced firewall allowlist and adds an assertion against opening it (`hosts/axiom/default.nix:1571-1579,1673-1676`; `hosts/acorn/default.nix:87-95,140-146`). Runtime evidence confirms both Axiom listeners are loopback-only and public `18082` times out while `443` is reachable.
- The gateway remains a restricted system user with a `0700` state directory, `0400` encrypted environment reference, no capabilities, and systemd filesystem hardening (`hosts/axiom/default.nix:172-220,1679-1691`). PI WEB intentionally retains `c1` authority behind that boundary.
- The nginx proxy fixes Host and forwarded host/scheme, forwards Cookie only to Auth Mini, targets loopback, disables retries, and applies the Origin denial before proxying (`hosts/acorn/modules/auth-mini.nix:108-140,244-274`). No alternate public or header-based authentication bypass was found.
- The implementation diff introduces no plaintext secret, credential, token, private key, or decrypted age material. It only reuses existing encrypted secret references.

## Base, Scope, And Regression

- Independent `git ls-remote` confirms remote `master`, local `origin/master`, `HEAD`, and merge-base all equal `0270c93870c0e616625d7ec2abdcb21a3ff33b8b`; the review base is current.
- The tracked worktree diff against that base is limited to `hosts/acorn/default.nix`, `hosts/acorn/modules/auth-mini.nix`, and `hosts/axiom/default.nix`, with 71 insertions and 7 deletions. `git diff --check origin/master` passes. The base advance since the prior review changes only the completed 1Ex task/wiki artifacts and does not overlap this implementation.
- Generated nginx configuration confirms the guard is PI-only and preserves status/OpenCode proxy behavior. Live ordinary PI HTTP/API, status, OpenCode, Auth Mini, and 1Ex checks all returned their expected authenticated or unauthenticated behavior.
- Removing either host's task increment breaks the PI chain closed rather than exposing `8504`: Acorn rollback removes the public route while `18082` remains firewall-closed; Axiom rollback removes the gateway/FRP mapping while PI WEB remains loopback-only. Retained generations and the prescribed Acorn command make the documented rollback executable, although it was not disruptively exercised.

## Evidence Assessment

The final independent verification is credible and internally consistent. It ties current-base evaluation to a realized nginx configuration, checks live deny and allow branches without secrets, differentiates PI edge denial from normal Auth Mini redirects, and covers firewall, TLS, FRP, runtime, authenticated operator behavior, and existing-service regressions. The deployment-supplied Acorn generation identity and operator-supplied authenticated browser result remain disclosed limitations, but live policy behavior independently demonstrates that the corrected edge configuration is active.

## Reviewer Identity

- agentType: `review-change`
- displayName: `review-change-cheery-lynx`
- reviewed base: current remote `origin/master` at `0270c93870c0e616625d7ec2abdcb21a3ff33b8b`
- security lens applied: **Yes**
- verdict: **PASS**

## Delivery Readiness

The implementation matches the approved revised Standard RFC, closes the prior HIGH finding, and has no unresolved correctness, scope, regression, or security blocker.

**Exact verdict: PASS**

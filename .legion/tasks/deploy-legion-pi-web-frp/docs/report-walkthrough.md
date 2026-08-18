# Delivery Walkthrough: Axiom Legion Pi Web via Acorn FRP

> **Mode**: `implementation`
> **Evidence status**: Approved revised Standard RFC, deployed implementation, final independent verification PASS, and final independent security review PASS.

## Objective

Provide `https://pi-axiom.0xc1.wang` as an authenticated HTTPS entry to the Axiom PI WEB runtime by reusing Auth Mini, FRP, Acorn nginx, and ACME. PI WEB is not exposed directly, and the implementation adds no new authentication protocol.

The tracked implementation is limited to `hosts/axiom/default.nix`, `hosts/acorn/default.nix`, and `hosts/acorn/modules/auth-mini.nix` (71 insertions, 7 deletions). No secrets are committed.

## Implementation

### Axiom Pi and PI WEB runtime

- Pins the Legion Pi runtime environment to the persistent profile and PI WEB data directories through the managed login-shell environment.
- Sets `PI_WEB_HOST=127.0.0.1` and `PI_WEB_PORT=8504`; PI WEB remains managed by its upstream per-user units rather than duplicated as a Nix service.
- Enables user lingering so `pi-web.service` and `pi-web-sessiond.service` can remain active independently of an interactive login.

### Auth Mini and frpc

- Adds `auth-mini-gateway-pi-axiom`, bound to `127.0.0.1:7782`, with PI WEB at `127.0.0.1:8504` as its upstream.
- Adds the `axiom-pi-web-http` FRP proxy from the authenticated gateway to Acorn remote port `18082`; FRP never maps PI WEB directly.
- Orders frpc after the new gateway while preserving the existing SSH, Gatus, and OpenCode proxies.

### Acorn nginx and ACME

- Adds the `pi-axiom.0xc1.wang` Cloudflare DNS ACME certificate and nginx virtual host.
- Reuses the existing node proxy behavior for forwarded headers, WebSocket upgrades, disabled buffering/retries, and 24-hour long-connection timeouts.
- Proxies only from nginx to `127.0.0.1:18082`; the shared FRPS listener remains wildcard-bound, as required by the existing server-wide FRPS configuration.

## Security Boundaries

The enforced path is:

```text
Browser :443
  -> Acorn nginx
  -> Acorn FRPS :18082
  -> Axiom frpc
  -> Auth Mini gateway 127.0.0.1:7782
  -> PI WEB 127.0.0.1:8504
```

- Axiom keeps `7782` and `8504` loopback-only and outside its firewall allowlist.
- Acorn keeps wildcard-bound `18082` outside its firewall allowlist and adds a Nix assertion preventing it from being opened. Live probing found `443` reachable and public `18082` closed.
- The nginx HTTP map permits PI WebSocket upgrades only for the exact semantic Origin `https://pi-axiom.0xc1.wang`. Sibling, foreign, and missing Origin upgrades return `403` before FRP, Auth Mini, or PI WEB.
- The guard is consumed only by the PI virtual host. Ordinary PI HTTP/API traffic and the status/OpenCode virtual hosts retain their existing behavior.
- PI WEB intentionally retains `c1` authority behind Auth Mini; it is not presented as a sandboxed service.

## Deployment Evidence

- Legion Pi `0.84.2` installed successfully, its idempotent reinstall skipped the existing payload, and verification returned `READY`.
- PI WEB `1.202608.1` and its native dependency installed successfully. `doctor`, `status`, and `version` evidence was healthy; both user units were active with zero restarts.
- Runtime checks showed PI WEB returning `200` on loopback `8504`, Auth Mini returning its unauthenticated redirect on loopback `7782`, and all four FRP proxies starting successfully.
- Axiom activation completed before Acorn. Acorn was built, transferred, and activated from Axiom through the required remote deployment path; no build ran on Acorn.
- Public evidence showed a trusted certificate for `pi-axiom.0xc1.wang`, unauthenticated requests entering Auth Mini rather than PI WEB, exact-Origin WebSocket traffic passing the edge guard, and foreign/missing-Origin upgrades receiving `403`.
- The authenticated operator browser gate passed after a transient refresh/reconnect: PI WEB loaded in the already-authenticated browser, session real-time output was normal, and the terminal connected normally. This positive gate is operator-supplied evidence, not an independently automated claim.

## Verification And Review

| Gate | Identity | Result |
| --- | --- | --- |
| Revised Standard RFC re-review | `review-rfc-brisk-marten` (`review-rfc`) | **PASS**, no blocking findings |
| Final independent verification | `verify-change-merry-badger` (`verify-change`) | **PASS**, 2026-08-19 CST |
| Final independent security/change review | `review-change-cheery-lynx` (`review-change`) | **PASS**, security lens applied, no unresolved blocker |

The authoritative reports are `docs/test-report.md` and `docs/review-change.md`; both supersede their earlier pre-correction conclusions.

## Base Integration Note

During finalization, `origin/master` advanced with the completed 1Ex work, which temporarily made earlier base wording stale. The branch was rebased onto the current base; the 1Ex changes did not overlap this three-file implementation. Final integrated regression probes for 1Ex, status, OpenCode, Auth Mini, and the existing FRP path all passed.

## Existing Verification Coverage

No new tests were run for this walkthrough. The final report records these commands and categories:

- `git diff --check origin/master` and current-base/scope checks.
- Targeted Nix evaluations for the host configuration, plus inspection of the generated nginx configuration obtained from evaluated nginx `ExecStart`.
- `pi-web status`, `pi-web version`, user-unit `systemctl --user show`, local HTTP checks, and targeted listener inspection.
- `node build/websocket-handshake-probe.mjs pi-axiom.0xc1.wang 8.159.128.125 <origin|->` for exact, sibling, foreign, and missing Origin behavior.
- TLS/SNI, unauthenticated redirect, ordinary HTTP/API, FRP service/log, and `nc -vz -w 5 8.159.128.125 18082` firewall-boundary checks.
- Existing status, OpenCode, Auth Mini, FRP, and integrated 1Ex regression probes.

## Accepted Residuals

- An established WebSocket is not terminated automatically by later logout or session expiry; operators must disconnect active sockets during suspected session compromise.
- FRP transport is encrypted and token-authenticated but does not verify the frps certificate identity. Active MITM remains outside the approved threat model.
- PI WEB installation and upstream user units are persistent but imperative rather than Nix-reproducible. The final verifier did not perform a disruptive reboot, logout, restart, or rollback.
- The authenticated browser gate is operator-supplied, and the active Acorn generation identity is deployment-supplied; live policy behavior independently confirms the corrected edge configuration is active.

## Rollback

- PI WEB failure: run `pi-web uninstall` to remove its user units while retaining runtime state for diagnosis.
- Axiom failure: return to the previous Nix generation, removing the new environment, lingering, gateway, and FRP increment.
- Acorn entry failure after activation: revert this task's certificate, virtual-host, Origin-guard, and firewall-assertion increment, then redeploy from Axiom using the prescribed Acorn command. Do not build on Acorn or use a fallback deployment route.
- Removing either host increment fails closed: Acorn loses the public route while `18082` remains firewall-closed, or Axiom loses the gateway/FRP mapping while PI WEB remains loopback-only.

## Evidence Sources

- `.legion/tasks/deploy-legion-pi-web-frp/docs/rfc.md`
- `.legion/tasks/deploy-legion-pi-web-frp/docs/review-rfc.md`
- `.legion/tasks/deploy-legion-pi-web-frp/docs/test-report.md`
- `.legion/tasks/deploy-legion-pi-web-frp/docs/review-change.md`
- `.legion/tasks/deploy-legion-pi-web-frp/log.md`
- Final diff for the three tracked implementation files listed above

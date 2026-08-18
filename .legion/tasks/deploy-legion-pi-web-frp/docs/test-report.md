# Verification Report

This report supersedes the pre-correction verification report and all earlier stale-base wording.

## Reviewer

- agentType: `verify-change`
- displayName: `verify-change-merry-badger`
- verified: `2026-08-19` (CST)

## Revision and Contract

- Worktree: `/home/c1/dotfiles/.worktrees/deploy-legion-pi-web-frp`
- Tested `HEAD` and current `origin/master`: `0270c938` (`docs(oneex): close private portfolio rollout (#164)`); the branch is current.
- `git diff --check origin/master` passed. The tracked implementation diff is limited to `hosts/axiom/default.nix`, `hosts/acorn/default.nix`, and `hosts/acorn/modules/auth-mini.nix`: 71 insertions and 7 deletions.
- The revised `plan.md` and approved Standard `docs/rfc.md` require an exact PI WebSocket Origin boundary. Independent re-review by `review-rfc-brisk-marten` returned PASS with no blocking finding.
- No build, deployment, restart, logout, rollback, credential use, or persistent runtime mutation was performed during this verification.

## Results

| Category | Commands / evidence | Outcome |
| --- | --- | --- |
| Nginx evaluation | Selected-attribute `nix eval --json .#nixosConfigurations.acorn.config --apply ...` for `commonHttpConfig`, PI/status/OpenCode location configs, proxy targets, firewall, nginx `ExecStart`, and toplevel | PASS. The map returns allow for ordinary requests and exact `websocket:https://pi-axiom.0xc1.wang`, and reject for every other or missing-Origin WebSocket upgrade. Only the PI location consumes the result with `return 403`; status and OpenCode contain no guard. PI/status/OpenCode still proxy to loopback ports 18082/18080/18081, and 18082 remains absent from the firewall allowlist. |
| Generated nginx config | Read `/nix/store/4jq0vinh5rv75i90ghy7f7ipp8pwwrmc-nginx.conf`, obtained from evaluated nginx `ExecStart` | PASS. The realized HTTP map is present at lines 52-56. The PI-only guard is present at lines 262-289; OpenCode lines 229-254 and status lines 298-323 have no guard. The generated config preserves WebSocket headers, no buffering, and 24-hour timeouts. |
| Acorn generation | Current Acorn toplevel and derivation evaluation | PASS. The evaluated output is `/nix/store/nhpsfnjkmzcn7chrqvh8jg7ll5jrcmsi-nixos-system-acorn-26.05.7813.0dd31db7e6db`, exactly matching the deployment-supplied live generation; derivation evaluation returned `/nix/store/wb4garcsxj7813mmisp9ga05199q7v9a-...drv`. No build ran. |
| PI WebSocket Origin boundary | `node build/websocket-handshake-probe.mjs pi-axiom.0xc1.wang 8.159.128.125 <origin|->`; the probe sends standard upgrade headers and only the non-secret `origin_probe=sentinel` Cookie | PASS. Sibling origin `https://status-axiom.0xc1.wang`, foreign origin `https://example.com`, and missing Origin each returned `HTTP/1.1 403 Forbidden`. Exact origin `https://pi-axiom.0xc1.wang` returned `HTTP/1.1 302 Found`, proving it was not edge-rejected and reached normal unauthenticated Auth Mini behavior. No real session material was used. |
| Guard isolation and ordinary traffic | Foreign-origin upgrade probes against status/OpenCode; ordinary PI root/API probes | PASS. Foreign-origin upgrade requests to status and OpenCode returned their normal unauthenticated 302 rather than PI's 403. Ordinary PI HTTPS and `/api/events` without an upgrade returned Auth Mini 302, proving HTTP/API traffic is unaffected. |
| TLS and authentication | Direct-IP SNI probe to `8.159.128.125:443`; sanitized redirects | PASS. PI serves a trusted Let's Encrypt certificate with SAN `DNS:pi-axiom.0xc1.wang`, valid through `2026-11-16`, and unauthenticated HTTP returns Auth Mini 302 rather than PI content. Redirect query data was removed before output. |
| PI runtime | `pi-web status`; `pi-web version`; user-unit `systemctl --user show`; local HTTP and targeted `ss` | PASS. PI WEB `1.202608.1`, `pi-web.service`, and `pi-web-sessiond.service` are current, active, and at zero restarts. Local PI returns 200 on `127.0.0.1:8504`; the gateway returns 302 on `127.0.0.1:7782`; both listeners remain loopback-only. |
| FRP and firewall boundary | System-unit `systemctl show`; filtered `journalctl -u frpc.service`; `nc -vz -w 5 8.159.128.125 18082` | PASS. PI gateway and FRPC remain active with zero restarts. Logs retain `start proxy success` for SSH, Gatus, OpenCode, and PI WEB. Public 18082 timed out while verified PI TLS on the same host's 443 succeeded. |
| Existing regressions | Local status/OpenCode probes and public status/OpenCode/Auth/1Ex probes | PASS. Local status and OpenCode returned 200; their public gateways returned Auth Mini 302; Auth Mini root returned its web redirect; `1ex-portfolio` returned the expected unauthenticated JSON 401. |

The selected checks prove both declarative placement and live enforcement. The differential sentinel-Cookie handshakes distinguish nginx edge denial from ordinary gateway authentication without requiring or exposing an authenticated Cookie.

## Operator Browser Gate

Operator-supplied post-fix evidence, not an independently automated claim: after a transient refresh/reconnect, the already-authenticated Zen private window loaded PI WEB, and the operator confirmed session real-time output and terminal connection are normal. No credential, cookie, token, or session content was requested or stored.

## Residual Risks and Gaps

- The Acorn `/run/current-system` value is deployment-supplied rather than independently read through a remote shell. Current evaluation matches it exactly, and live 403/302 behavior proves the corrected nginx policy is active.
- No disruptive restart, logout, reboot, or rollback was exercised. Previously established unit enablement, linger, persistent paths, and retained generations remain the non-disruptive persistence/rollback evidence.
- The authenticated positive WebSocket/UI result is operator evidence. Automated negative and pass-through tests deliberately used only a non-secret sentinel Cookie.
- Established WebSockets remain authorized until disconnected even after later logout/session expiry. Authenticated PI WEB still carries `c1` authority, and FRP still does not verify frps certificate identity, as accepted by the revised RFC.
- An initial evaluation requested the nonexistent `services.nginx.configFile` attribute and produced no evidence; the corrected evaluation obtained the realized config path from nginx `ExecStart` and passed.

## Verdict

**PASS** - the prior HIGH cross-site WebSocket hijacking blocker is corrected, and no acceptance or security blocker remains.

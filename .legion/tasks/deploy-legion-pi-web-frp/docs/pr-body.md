## Summary

- Implementation mode: expose Axiom PI WEB at `https://pi-axiom.0xc1.wang` through the existing authenticated Auth Mini -> FRP -> Acorn nginx path.
- Configure the persistent Legion Pi/PI WEB environment, user lingering, loopback PI WEB `:8504`, loopback Auth Mini gateway `:7782`, and FRP remote port `18082` on Axiom.
- Add the Acorn ACME certificate, nginx virtual host, firewall-closure assertion, and PI-only exact-Origin WebSocket guard.
- The branch was rebased after the unrelated 1Ex base advance; the final integrated regressions passed. No secrets are committed.

## Verification

- `git diff --check origin/master` and current-base/scope checks: PASS.
- Targeted host `nix eval --json` checks and generated nginx configuration inspection: PASS; no build was run during final verification.
- `pi-web status`, `pi-web version`, user-unit, local HTTP, listener, FRP, TLS, authentication, and firewall-boundary checks: PASS.
- Exact/sibling/foreign/missing-Origin WebSocket probes and ordinary PI HTTP/API isolation checks: PASS.
- Existing status, OpenCode, Auth Mini, FRP, and integrated 1Ex regressions: PASS.
- Authenticated operator browser gate for PI page, real-time session output, and terminal connectivity: PASS (operator-supplied evidence).
- Revised RFC re-review: `review-rfc-brisk-marten` PASS. Independent verification: `verify-change-merry-badger` PASS. Independent security review: `review-change-cheery-lynx` PASS.

## Security/Residuals

- PI WEB and its Auth Mini gateway remain loopback-only; Acorn `18082` remains firewall-closed and is consumed locally by nginx.
- WebSocket upgrades allow only `Origin: https://pi-axiom.0xc1.wang`; sibling, foreign, and missing Origin requests fail at nginx with `403`. Ordinary HTTP/API and other virtual hosts are unaffected.
- Accepted residuals: established WebSockets outlive later auth changes, FRP does not verify server certificate identity, PI WEB retains `c1` authority, and final verification did not exercise disruptive reboot/logout/rollback paths.

## Rollback

- Uninstall the upstream PI WEB user units if the runtime fails.
- Roll Axiom back to its previous Nix generation to remove the environment, gateway, FRP, and lingering increment.
- Revert the Acorn certificate/vhost/guard increment and redeploy only from Axiom through the prescribed Acorn deployment command. Either host rollback fails closed rather than exposing PI WEB directly.

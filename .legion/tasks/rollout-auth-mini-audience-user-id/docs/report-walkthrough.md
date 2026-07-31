# Report Walkthrough: Rollout Audience-Bound Gateway User IDs

> **Mode:** implementation
> **Date:** 2026-07-31
> **Task:** `rollout-auth-mini-audience-user-id`

## Reviewer Entry Point

Read `plan.md` for scope, `docs/test-report.md` for repository and live evidence, and `docs/review-change.md` for the final security/correctness decision.

## Delivered State

- The dotfiles gateway package now pins upstream `e1ea3e77fc39612b7418a3a44db5e2cc2b8618d4`.
- Axiom and Acorn encrypted gateway environments now contain the supplied exact user ID as the only authorization allowlist entry; existing cookie secrets were preserved and `ALLOW_EMAILS` was removed.
- Axiom cleartext proxy gateways explicitly use `UPSTREAM_PROTOCOL=http1`.
- PR #157 merged the package and encrypted-env migration; PR #158 merged the protocol fix.

## Live Rollout Evidence

- Axiom status/opencode gateways are active on the new package, pass local health checks, read the migrated env, and produce correct public auth-mini login redirects.
- Acorn auth-gateway/frps gateways are active on the new package, pass local health checks, read the migrated env, and produce correct auth-mini login redirects.
- Acorn was deployed from Axiom with the mandated `--build-host localhost --sudo --ask-sudo-password` path; no Nix build or rebuild ran on Acorn.
- Startup and smoke logs contain fixed events only, with no gateway secret, token, cookie, callback body, or plaintext user ID exposure.

## Important Incident and Resolution

The first Axiom switch exposed `upstream_protocol_cleartext_auto` because the new gateway correctly rejects cleartext proxy mode with implicit `auto`. PR #158 added `UPSTREAM_PROTOCOL=http1`; the second switch started both gateway services. The remaining switch warning was unrelated `rustdesk-provision.service` reporting `attempt-used` and is tracked as out of scope.

## Remaining Smoke

Automation did not modify production auth-mini data or use real credentials. The user should now complete one fresh browser login for `opencode-axiom.0xc1.wang`, then optionally spot-check `status-axiom.0xc1.wang` and `frps-acorn.0xc1.wang`.

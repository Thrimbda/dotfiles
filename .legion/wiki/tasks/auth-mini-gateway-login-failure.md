# Auth Mini Gateway Login Failure

## Metadata

- `task-id`: `auth-mini-gateway-login-failure`
- `status`: `ready for PR; live post-switch browser smoke pending`
- `risk`: `medium`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `gateway-owned Passkey/amr authorization from auth-mini-acorn-gateway`
- `superseded-by`: `auth-mini-node-gateway-migration for package pin and host placement only; exact-identity authorization remains current`

## Outcome Summary

An allowlisted user completed auth-mini login with Email OTP but auth-mini-gateway returned `403` because `REQUIRE_PASSKEY=true`; the callback bridge hid that policy decision behind a generic login-failed message. Upstream auth-mini-gateway PR #4 removed gateway-owned authentication-method policy, and dotfiles now pins its merge commit while removing the obsolete encrypted env entry. Gateway authorization remains deny-by-default on exact email/user-id allowlists. Repository, build, integration, and security review evidence passes; only the live post-switch browser smoke remains.

## Reusable Decisions

- Auth-mini owns authentication-method selection. Auth-mini-gateway verifies the auth-mini session and authorizes only exact `ALLOW_EMAILS` or `ALLOW_USER_IDS` identity; it does not impose a separate Passkey/`amr` policy.
- Preserve plaintext allowlists and gateway secrets only in agenix-managed environment state. Reviewer artifacts may record invariants and sanitized counts, not secret values.
- A generic callback failure may mask a gateway policy `403`; diagnose the callback/session response and authorization decision before changing redirects, cookies, or per-origin topology.

## Related Raw Sources

- `plan`: `.legion/tasks/auth-mini-gateway-login-failure/plan.md`
- `log`: `.legion/tasks/auth-mini-gateway-login-failure/log.md`
- `tasks`: `.legion/tasks/auth-mini-gateway-login-failure/tasks.md`
- `test-report`: `.legion/tasks/auth-mini-gateway-login-failure/docs/test-report.md`
- `change-review`: `.legion/tasks/auth-mini-gateway-login-failure/docs/review-change.md`
- `report`: `.legion/tasks/auth-mini-gateway-login-failure/docs/report-walkthrough.md`
- `pr-body`: `.legion/tasks/auth-mini-gateway-login-failure/docs/pr-body.md`

## Notes

- Upstream auth-mini-gateway PR #4 merged at `f0519d1fcfbf49be43602f7a25ad2373434366fe`.
- The package pin and four-Acorn-instance rollout context are superseded by `auth-mini-node-gateway-migration`; the exact email/user-id authorization decision remains current. After migration rollout, browser-smoke Email OTP, denied-user, logout, and per-origin behavior across the retained Acorn gateways and the Axiom status/OpenCode gateways.

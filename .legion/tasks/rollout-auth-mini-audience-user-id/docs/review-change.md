# Review Change: Rollout Audience-Bound Gateway User IDs

> **Review stage:** `review-change`
> **Date:** 2026-07-31
> **Reviewed:** `plan.md`, `docs/test-report.md`, merged configuration changes, and live Axiom/Acorn deployment evidence
> **Security lens:** Applied (authentication authorization, identity allowlist, encrypted secrets, production deployment boundary)

## Verdict

**PASS.**

The rollout is ready for user browser smoke. The merged configuration is narrowly scoped, both production hosts activated the intended audience-bound gateway package, and all four gateway services are healthy with user-ID-only authorization. The first Axiom activation exposed one configuration gap (`UPSTREAM_PROTOCOL` missing); that gap was fixed, merged as PR #158, and verified by the second Axiom switch.

## Blocking Findings

None.

## Security and Correctness Review

| Boundary | Result |
|---|---|
| Package provenance | `packages/auth-mini-gateway/default.nix` pins merged upstream `e1ea3e77fc39612b7418a3a44db5e2cc2b8618d4` with explicit fixed-output source and Cargo hashes. All four live services execute the resulting `0.1.0-unstable-2026-07-30` package. |
| Authorization migration | Both encrypted env files were transformed and re-decrypted successfully. Runtime assertions on both hosts prove the previous cookie secret was preserved, the supplied exact user ID is the only allowlist entry, and no nonempty `ALLOW_EMAILS` remains. |
| Secret handling | No plaintext gateway secret or supplied user ID appears in Nix, task docs, PR evidence, or the worktree. Runtime checks are non-printing and agenix files remain `auth-mini-gateway:auth-mini-gateway` mode `0400`. |
| Cleartext proxy startup | Axiom gateway units explicitly set `UPSTREAM_PROTOCOL=http1`; both evaluate `http1`, build, and now run without `upstream_protocol_cleartext_auto`. |
| Axiom rollout | Status and OpenCode gateways are active, return local `204` health checks, and produce correct public auth-mini login redirects through the Acorn/nginx/FRP path. |
| Acorn rollout | The mandated Axiom `--build-host localhost` command completed and activated Acorn. Auth-gateway and frps gateways are active, return local `204` health checks, and produce correct auth-mini login redirects. No Nix build or rebuild ran on Acorn. |
| Scope | No unrelated auth-mini, nginx, FRP, Cloudflare, firewall, protected-upstream, or session-database changes were made. The unrelated `rustdesk-provision.service` `attempt-used` failure is explicitly outside this task. |
| Rollback | Rollback is a normal dotfiles revert plus host switches. Existing sessions may still require bounded re-login under the upstream audience contract; this is documented and expected. |

## Non-blocking Residuals

1. Credential-bearing browser login, callback, refresh, and upstream access remain the user's final smoke check. Automation did not modify production auth-mini data or use real credentials.
2. Existing sessions can remain usable only until their recorded refresh boundary; legacy audience rejection then requires re-login.
3. `rustdesk-provision.service` still reports `attempt-used` and should be tracked separately; it did not affect gateway health.

## Evidence

`docs/test-report.md` records package build and upstream tests, secret decrypt/transform/re-encrypt/decrypt assertions, Axiom protocol-fix evaluation and toplevel build, Axiom live service checks, Acorn mandated deployment, runtime env assertions, local/public login redirects, and secret-boundary scans.

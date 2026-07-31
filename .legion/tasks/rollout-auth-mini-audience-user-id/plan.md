# Rollout Audience-Bound Gateway User IDs

## 目标

Deploy the merged audience-bound auth-mini-gateway to every protected gateway instance and migrate all host-local authorization environments to the user-supplied exact auth-mini user ID.

## 问题陈述

The repository fix for current auth-mini audience-bound login is merged, but production gateways still run the old package and email-based environment. Fresh logins fail because the old gateway calls self-audience-only /me with a downstream token.

## 验收标准

- [ ] The dotfiles gateway package pins the merged audience-bound upstream commit and builds successfully.
- [ ] Axiom and Acorn encrypted gateway environments decrypt successfully, preserve the existing cookie secret, contain the user-supplied exact ALLOW_USER_IDS value, and contain no nonempty ALLOW_EMAILS value.
- [ ] The dotfiles change is reviewed, merged, and the main workspace is refreshed before deployment.
- [ ] Axiom switches successfully and both status/opencode gateway services run the new package with healthy logs.
- [ ] Acorn switches successfully using only the mandated Axiom build-host deployment path, and both retained gateway services run the new package with healthy logs.
- [ ] Each protected public hostname returns an auth-mini login redirect with the matching HTTPS redirect_uri and no explicit aud parameter.
- [ ] Startup and smoke logs contain no allow_emails_unsupported error, token, cookie, callback body, or secret value.

## 假设 / 约束 / 风险

- **假设**: The user-supplied auth-mini user ID identifies the only identity that should be allowed during this rollout.
- **假设**: The existing gateway cookie secrets must be preserved so current sessions are not needlessly invalidated by secret rotation.
- **假设**: Auth Mini remains external and unchanged.
- **约束**: Never build or evaluate the Acorn system closure on Acorn; Acorn deployment must use the mandated nixos-rebuild command from Axiom with --build-host localhost.
- **约束**: Do not print gateway cookie secrets, access tokens, refresh tokens, callback bodies, or plaintext secret env contents.
- **约束**: Do not write the supplied user ID into plaintext Nix, task docs, PR bodies, or logs; it belongs only in the encrypted env and runtime checks that avoid printing it.
- **约束**: Do not touch unrelated untracked files in the dotfiles main workspace or the stale existing worktree.
- **约束**: Do not modify production auth-mini data or seed credentials to simulate login.
- **风险**: An incorrect user ID would deny all fresh logins and eventually deny existing sessions at refresh.
- **风险**: Secret re-encryption mistakes can discard the cookie secret or leave ALLOW_EMAILS active and block startup.
- **风险**: Axiom and Acorn share the package pin, so deploying only one host would leave the other host broken on its next switch.
- **风险**: Production switches may be blocked by unrelated host configuration or network/substituter failures.

## 要点

- Package pin: advance only the gateway source revision and fixed-output hash to the reviewed merged commit.
- Secret migration: decrypt, transform without printing, remove email allowlist, set exact user-ID allowlist, re-encrypt per host recipient, and verify decryptability.
- Rollout: merge configuration first, then switch Axiom and Acorn from the refreshed main workspace.
- Smoke: compare service package paths, health/login redirects, startup events, and no-secret log boundaries for all four gateway instances.

## 范围

- packages/auth-mini-gateway/default.nix - gateway source pin and hashes.
- hosts/axiom/secrets/auth-mini-gateway-env.age - encrypted user-ID migration for status/opencode gateways.
- hosts/acorn/secrets/auth-mini-gateway-env.age - encrypted user-ID migration for auth-gateway/frps gateways.
- .legion/tasks/rollout-auth-mini-audience-user-id/ - rollout evidence and reports.
- .legion/wiki/ - final current-truth writeback after deployment.

## 非目标

- Do not modify auth-mini, its production database, or its issuer/RP/admin configuration.
- Do not broaden authorization beyond the single user-supplied exact auth-mini user ID.
- Do not change nginx, FRP, Cloudflare, firewall, protected-upstream, or cookie topology.
- Do not rotate gateway cookie secrets or rewrite existing session databases.
- Do not run a Nix build, evaluation, or `nixos-rebuild` on Acorn.
- Do not seed credentials or simulate an interactive production login; credential-bearing browser smoke remains with the user.

## 设计索引 (Design Index)

> **Design Source of Truth**: /home/c1/Work/auth-mini-gateway/.legion/tasks/diagnose-login-callback-failure/docs/rfc.md

**摘要**:
- Approved design: validate the exact gateway-host JWT audience, establish sessions from signed claims without downstream /me, and authorize exact user IDs only.
- This rollout applies that design without changing it: package pin plus per-host encrypted ALLOW_USER_IDS migration, followed by Axiom and Acorn switches and secret-safe smoke checks.

## 阶段概览

1. **Configuration and review** - Create a clean worktree, update the gateway pin and both encrypted environments, build/evaluate, review, merge, and refresh main.
2. **Axiom deployment** - Switch Axiom from refreshed origin/master and verify both gateway services and login redirects.
3. **Acorn deployment** - Switch Acorn using the mandated Axiom build-host command and verify both retained gateway services and login redirects.
4. **Closeout** - Record verification, review, walkthrough, wiki writeback, PR/deploy evidence, and remaining user browser smoke.

---

*创建于: 2026-07-31 | 最后更新: 2026-07-31*

# Test Report: Rollout Audience-Bound Gateway User IDs

> **Date:** 2026-07-31
> **Scope:** Repository configuration, Axiom deployment, Acorn deployment, and post-deployment smoke for all auth-mini gateway instances.

## Result

**PASS for rollout.** All four gateway services run the merged audience-bound package, read their host-local user-ID-only encrypted environment, and return the expected auth-mini login redirects. Credential-bearing browser login remains the user's final smoke check because production auth-mini data and credentials were intentionally not modified.

## Repository and Secret Checks

| Check | Result | Evidence |
|---|---|---|
| `nix store prefetch-file --unpack --json <merged gateway archive>` | PASS | Produced fixed-output source hash for upstream `e1ea3e77fc39612b7418a3a44db5e2cc2b8618d4`. |
| `nix build --no-link -L .#packages.x86_64-linux.auth-mini-gateway` | PASS | Package built and upstream tests ran: 119 library tests + 50 proxy integration tests, 0 failed. |
| Axiom secret decrypt/transform/re-encrypt/decrypt cycle | PASS | Existing cookie secret was preserved; `ALLOW_USER_IDS` exactly matched the supplied value; `ALLOW_EMAILS` was absent or empty. No plaintext was printed. |
| Acorn secret decrypt/transform/re-encrypt/decrypt cycle | PASS | Existing cookie secret was preserved; `ALLOW_USER_IDS` exactly matched the supplied value; `ALLOW_EMAILS` was absent or empty. No plaintext was printed. |
| Axiom/Acorn agenix mode and owner evaluation | PASS | Both evaluate to mode `0400` and owner `auth-mini-gateway`. |
| Repository plaintext scan for the supplied user ID | PASS | No repository file contains the value; it exists only inside encrypted age payloads and runtime secret paths. |
| Axiom `UPSTREAM_PROTOCOL` evaluation for both gateway units | PASS | Both return `"http1"`, closing the live `upstream_protocol_cleartext_auto` startup failure observed in the first switch. |
| `nix build --impure --no-link -L .#nixosConfigurations.axiom.config.system.build.toplevel` | PASS | Axiom toplevel builds with the explicit protocol fix. Existing unrelated xorg rename warnings remain. |
| `git diff --check` | PASS | No patch-format or whitespace errors. |

## Axiom Live Deployment

| Check | Result | Evidence |
|---|---|---|
| First `sudo nixos-rebuild switch --flake .#axiom` | EXPECTED FAILURE | Gateway activation failed with sanitized `upstream_protocol_cleartext_auto`; the switch exposed the missing cleartext protocol selection. |
| `hosts/axiom/default.nix` protocol fix | PASS | Both gateway units now evaluate `UPSTREAM_PROTOCOL="http1"`; PR #158 merged as `fb78aea6a97e3a2b388972cbdfbcf540ed8cfcc2`. |
| Second `sudo nixos-rebuild switch --flake .#axiom` | GATEWAY PASS | Both gateway services started. The command still returned nonzero because unrelated `rustdesk-provision.service` reported pre-existing `attempt-used`; no gateway unit failed. |
| `systemctl is-active auth-mini-gateway-opencode-axiom.service auth-mini-gateway-status-axiom.service` | PASS | Both `active`. |
| Gateway package paths | PASS | Both ExecStart paths use `auth-mini-gateway-0.1.0-unstable-2026-07-30`. |
| Local health checks | PASS | `127.0.0.1:7780/healthz` and `127.0.0.1:7779/healthz` both return `204`. |
| Runtime env permission and content assertion | PASS | `/run/agenix/auth-mini-gateway-env` is `auth-mini-gateway:auth-mini-gateway` mode `0400`; non-printing assertion verified the exact supplied user ID, no nonempty email allowlist, and a present cookie secret. |
| Local login redirects | PASS | Both gateway login routes return auth-mini redirects with the matching HTTPS `redirect_uri`, a one-time state, and no explicit `aud`. |
| Public login redirects | PASS | `https://opencode-axiom.0xc1.wang/` and `https://status-axiom.0xc1.wang/` both return the expected auth-mini login redirect. |
| Gateway startup logs after protocol fix | PASS | Schema migration and proxy-mode startup events only; no `allow_emails_unsupported`, `upstream_protocol_cleartext_auto`, token, cookie, callback body, or secret value. |

## Acorn Live Deployment

| Check | Result | Evidence |
|---|---|---|
| `nixos-rebuild switch --flake .#acorn --target-host c1@8.159.128.125 --build-host localhost --sudo --ask-sudo-password --use-substitutes -L` | PASS | Ran from Axiom with `--build-host localhost`; closure copied to Acorn and activated. No Nix build or rebuild ran on Acorn. |
| `systemctl is-active auth-mini-gateway-auth-gateway.service auth-mini-gateway-frps-acorn.service` | PASS | Both `active`. |
| Gateway package paths | PASS | Both ExecStart paths use `auth-mini-gateway-0.1.0-unstable-2026-07-30`. |
| Local health checks | PASS | `127.0.0.1:7778/healthz` and `127.0.0.1:7781/healthz` both return `204`. |
| Runtime env permission and content assertion | PASS | `/run/agenix/auth-mini-gateway-env` is `auth-mini-gateway:auth-mini-gateway` mode `0400`; non-printing assertion verified the exact supplied user ID, no nonempty email allowlist, and a present cookie secret. |
| Local login redirects | PASS | Both gateway login routes return auth-mini redirects with the matching HTTPS `redirect_uri`, a one-time state, and no explicit `aud`. |
| Public login redirects | PASS | `https://auth-gateway.0xc1.wang/login` and `https://frps-acorn.0xc1.wang/` both return the expected auth-mini login redirect. The adapter-only auth-gateway root remains an intentional `404`. |
| Gateway startup logs | PASS | Schema migration and adapter-mode startup events only; no `allow_emails_unsupported`, token, cookie, callback body, or secret value. |

## Changed Files

- `packages/auth-mini-gateway/default.nix`: pins upstream `e1ea3e77fc39612b7418a3a44db5e2cc2b8618d4` with verified source and Cargo hashes.
- `hosts/axiom/default.nix`: sets `UPSTREAM_PROTOCOL=http1` for cleartext proxy-mode gateway units required by the new gateway startup contract.
- `hosts/axiom/secrets/auth-mini-gateway-env.age`: re-encrypted for the Axiom recipient after user-ID migration.
- `hosts/acorn/secrets/auth-mini-gateway-env.age`: re-encrypted for the Acorn recipient after user-ID migration.
- `.legion/tasks/rollout-auth-mini-audience-user-id/**`: task evidence only; no plaintext user ID or gateway secret.

## Not Proven by Automation

- Credential-bearing browser login, callback, refresh, and upstream access. The unauthenticated public redirects and all service/config boundaries are proven; the user must complete the real browser login once.

## Secret Boundary

The supplied user ID and existing cookie secrets were handled only through encrypted age files, local temporary files removed after assertion, and non-printing runtime checks. Repository docs intentionally do not record the supplied user ID.

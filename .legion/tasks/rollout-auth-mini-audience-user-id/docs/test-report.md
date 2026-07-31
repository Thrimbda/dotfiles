# Test Report: Rollout Audience-Bound Gateway User IDs

> **Date:** 2026-07-31
> **Scope:** Repository configuration and pre-deployment evidence for the four auth-mini gateway instances.

## Result

**PASS for repository configuration.** The gateway package builds with the merged audience-bound upstream revision, and both host-local encrypted environments were migrated without exposing plaintext secret material or the supplied user ID in repository files.

## Commands and Checks

| Check | Result | Evidence |
|---|---|---|
| `nix store prefetch-file --unpack --json <merged gateway archive>` | PASS | Produced fixed-output source hash for upstream `e1ea3e77fc39612b7418a3a44db5e2cc2b8618d4`. |
| `nix build --no-link -L .#packages.x86_64-linux.auth-mini-gateway` | PASS | Package built and upstream tests ran: 119 library tests + 50 proxy integration tests, 0 failed. |
| Axiom secret decrypt/transform/re-encrypt/decrypt cycle | PASS | Existing cookie secret was preserved; `ALLOW_USER_IDS` exactly matched the supplied value; `ALLOW_EMAILS` was absent or empty. No plaintext was printed. |
| Acorn secret decrypt/transform/re-encrypt/decrypt cycle | PASS | Existing cookie secret was preserved; `ALLOW_USER_IDS` exactly matched the supplied value; `ALLOW_EMAILS` was absent or empty. No plaintext was printed. |
| `nix eval --impure --json .#nixosConfigurations.axiom.config.age.secrets.auth-mini-gateway-env.mode` | PASS | Returned `"0400"`. |
| `nix eval --impure --json .#nixosConfigurations.axiom.config.age.secrets.auth-mini-gateway-env.owner` | PASS | Returned `"auth-mini-gateway"`. |
| `nix eval --impure --json .#nixosConfigurations.acorn.config.age.secrets.auth-mini-gateway-env.mode` | PASS | Returned `"0400"`. |
| `nix eval --impure --json .#nixosConfigurations.acorn.config.age.secrets.auth-mini-gateway-env.owner` | PASS | Returned `"auth-mini-gateway"`. |
| Repository plaintext scan for the supplied user ID | PASS | No file in the worktree contains the value; it exists only inside encrypted age payloads and the runtime secret path after deployment. |
| `git diff --check` | PASS | No patch-format or whitespace errors. |
| Axiom `UPSTREAM_PROTOCOL` evaluation for both gateway units | PASS | Both return `"http1"`, addressing the live `upstream_protocol_cleartext_auto` startup failure observed during the first Axiom switch. |
| `nix build --impure --no-link -L .#nixosConfigurations.axiom.config.system.build.toplevel` | PASS | Axiom toplevel builds with the explicit protocol fix. Existing unrelated xorg rename warnings remain. |

## Changed Files

- `packages/auth-mini-gateway/default.nix`: pins upstream `e1ea3e77fc39612b7418a3a44db5e2cc2b8618d4` with verified source and Cargo hashes.
- `hosts/axiom/default.nix`: sets `UPSTREAM_PROTOCOL=http1` for cleartext proxy-mode gateway units required by the new gateway startup contract.
- `hosts/axiom/secrets/auth-mini-gateway-env.age`: re-encrypted for the Axiom recipient after user-ID migration.
- `hosts/acorn/secrets/auth-mini-gateway-env.age`: re-encrypted for the Acorn recipient after user-ID migration.
- `.legion/tasks/rollout-auth-mini-audience-user-id/**`: task evidence only; no plaintext user ID or gateway secret.

## Not Yet Proven

- Axiom `nixos-rebuild switch` and live status/opencode gateway smoke.
- Acorn `nixos-rebuild switch` through the mandated Axiom build-host path and live auth-gateway/frps smoke.
- Credential-bearing browser login. This remains a user smoke check because production auth-mini data and credentials are outside this task.

## Secret Boundary

The supplied user ID and existing cookie secrets were handled only through encrypted age files, local temporary files removed after assertion, and non-printing runtime checks. Repository docs intentionally do not record the supplied user ID.

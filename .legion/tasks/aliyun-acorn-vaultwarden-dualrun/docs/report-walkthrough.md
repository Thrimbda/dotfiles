# Report Walkthrough: Aliyun Acorn Vaultwarden Dual Run

**Mode**: implementation
**Reviewer result**: ready for PR review; verification and change review both passed.

## What changed

- Added Vaultwarden to `aliyun-acorn` for a staged dual-run migration while keeping the existing `acorn` deployment in place.
- Imported a new host-local `hosts/aliyun-acorn/modules/vaultwarden.nix` from `hosts/aliyun-acorn/default.nix`.
- Added the `aliyun-acorn` Vaultwarden service/vhost shape for `vault.0xc1.space`, including agenix environment file ownership, backup path, websocket routes, nginx behavior, and fail2ban integration confirmed by Nix eval.
- Added `hosts/aliyun-acorn/secrets/secrets.nix` rule for `vaultwarden-env.age` using the `aliyunAcorn` recipient.
- Added `hosts/aliyun-acorn/secrets/vaultwarden-env.age` as a new encrypted secret artifact for the target host.

## Why

The task enables `aliyun-acorn` to run Vaultwarden before any cutover, without removing or altering `acorn`. The RFC chose a minimal host-local duplicate over shared-module refactoring to reduce risk during a secret-sensitive migration. Copying the old `acorn` `.age` file was explicitly rejected because it could evaluate but fail to decrypt on `aliyun-acorn`.

## Files touched

Staged diff summary before this walkthrough:

- Production config:
  - `hosts/aliyun-acorn/default.nix`
  - `hosts/aliyun-acorn/modules/vaultwarden.nix`
  - `hosts/aliyun-acorn/secrets/secrets.nix`
  - `hosts/aliyun-acorn/secrets/vaultwarden-env.age`
- Legion evidence/docs under `.legion/tasks/aliyun-acorn-vaultwarden-dualrun/`
- Summary: 12 files changed, 547 insertions, plus one new encrypted binary secret.

`hosts/acorn` has no staged changes, and the shared `modules/services/vaultwarden.nix` remains unchanged.

## Validation evidence

From `docs/test-report.md`:

- PASS: `agenix -d vaultwarden-env.age -i /home/c1/.ssh/id_ed25519 > /dev/null` from `hosts/aliyun-acorn/secrets`, confirming target decryptability without printing plaintext.
- PASS: targeted Nix eval of the live working tree confirmed the `aliyun-acorn` service, vhost, secret metadata, fail2ban shape, and that `acorn` remains enabled.
- PASS after staging: `nix eval --impure .#nixosConfigurations.aliyun-acorn.config.services.vaultwarden.enable` returned `true`.
- PASS after staging: secret owner eval returned `"vaultwarden"`.
- PASS after staging: nginx websocket proxy eval returned `"http://127.0.0.1:3012"`.
- PASS after staging: `nix build --impure --no-link .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel` built successfully.

The earlier plain `.#` eval/build failures were recorded as a pre-staging Git flake source caveat and were resolved by staging the intended files.

## Review and security result

- RFC review: PASS; implementation was allowed to begin.
- Change review: PASS; no blocking findings.
- Security review found no staged private key file or plaintext secret file.
- A staged-content scan found no private-key or env-secret markers in changed files.
- The encrypted `vaultwarden-env.age` was validated only by decrypting to `/dev/null`; secret plaintext was not printed or inspected.

## Residual risks

- No live deployment checks were run. `vaultwarden.service`, `nginx.service`, `fail2ban.service`, ACME issuance, and `/run/agenix/vaultwarden-env` ownership remain post-deploy checks.
- Dual-running the same `vault.0xc1.space` service can diverge Vaultwarden data if traffic is split without an explicit migration or data ownership plan.
- ACME may fail on `aliyun-acorn` until DNS or routing points the domain at that host.
- Decryptability proves the target key can open the file, but the secret contents were intentionally not inspected.

## Rollback

Rollback is to revert this PR or remove:

- `hosts/aliyun-acorn/modules/vaultwarden.nix`
- the import from `hosts/aliyun-acorn/default.nix`
- `hosts/aliyun-acorn/secrets/vaultwarden-env.age`
- the `vaultwarden-env.age` rule in `hosts/aliyun-acorn/secrets/secrets.nix`

No `acorn` rollback is required because `acorn` remains unchanged. Operationally, keep traffic on `acorn` or avoid routing `vault.0xc1.space` to `aliyun-acorn`.

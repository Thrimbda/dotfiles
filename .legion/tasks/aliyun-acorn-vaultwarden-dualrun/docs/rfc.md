# RFC: Aliyun Acorn Vaultwarden Dual Run

**Profile**: High-risk focused RFC
**Status**: Draft
**Owners**: OpenCode / user
**Created**: 2026-06-30
**Last Updated**: 2026-06-30

## Executive Summary

- Problem: Vaultwarden is configured only on `acorn`; `aliyun-acorn` needs a staged dual-run deployment before any cutover.
- Decision: Add a host-local Vaultwarden module to `aliyun-acorn`, keep `acorn` unchanged, and re-encrypt `vaultwarden-env.age` for the `aliyunAcorn` recipient.
- Impact: `aliyun-acorn` will have the same service/vhost shape as `acorn`, including websocket routes and fail2ban integration.
- Primary risk: secret mishandling or generating an `.age` file that evaluates but cannot decrypt at activation.
- Rollout: merge declarative config and secret; deploy later on `aliyun-acorn` when DNS/ACME routing is ready.
- Rollback: revert the new `aliyun-acorn` module/import/secret declaration/file; `acorn` stays unchanged throughout.

## Goals

- Enable `modules.services.vaultwarden` on `aliyun-acorn` via host-local configuration.
- Configure `services.vaultwarden` with the existing domain, ports, websocket behavior, backup path, and runtime secret file.
- Add `vault.0xc1.space` nginx vhost to `aliyun-acorn` with the same upstream routing as `acorn`.
- Create `hosts/aliyun-acorn/secrets/vaultwarden-env.age` encrypted to the `aliyunAcorn` recipient using the old acorn key only for transient decryption.
- Validate Nix configuration shape without leaking secret plaintext.

## Non-goals

- Remove or alter the `acorn` deployment.
- Change public DNS, ACME settings, Vaultwarden credentials, tokens, SMTP, database configuration, or user data.
- Migrate Vaultwarden database/files or solve dual-write/data synchronization.
- Deploy to the target machine in this task.

## Constraints

- Keep the production change minimal and auditable.
- Do not commit private keys or plaintext secret material.
- Use `./acorn_id_ed25519` only to decrypt the existing `acorn` secret and `/home/c1/.ssh/id_ed25519` only as the target `aliyunAcorn` encryption identity.
- Preserve current shared module behavior unless validation exposes a direct blocker.

## Proposed Design

### Host Configuration

- Add `hosts/aliyun-acorn/modules/vaultwarden.nix` based on `hosts/acorn/modules/vaultwarden.nix`.
- Import it from `hosts/aliyun-acorn/default.nix` alongside the qemu guest profile.
- Preserve these service settings:
  - `modules.services.vaultwarden.enable = true`
  - `age.secrets.vaultwarden-env.owner = "vaultwarden"`
  - `age.secrets.vaultwarden-env.group = "vaultwarden"`
  - `age.secrets.vaultwarden-env.mode = "0400"`
  - `services.vaultwarden.backupDir = "/backup/vaultwarden"`
  - `environmentFile = config.age.secrets.vaultwarden-env.path`
  - `domain = "https://vault.0xc1.space"`
  - `rocketPort = 8000`
  - `websocketEnabled = true`
  - nginx routes for `/notifications/hub/negotiate`, `/notifications/hub`, and `/`

### Secret Re-encryption

- Add `"vaultwarden-env.age".publicKeys = [ aliyunAcorn ];` to `hosts/aliyun-acorn/secrets/secrets.nix`.
- Stream decrypt from `hosts/acorn/secrets/vaultwarden-env.age` using `./acorn_id_ed25519` directly into `agenix -e hosts/aliyun-acorn/secrets/vaultwarden-env.age` with the `aliyun-acorn` rules file.
- Do not write decrypted content to repo files, task docs, shell history, or chat.
- Verify the new encrypted file decrypts with `/home/c1/.ssh/id_ed25519` by sending output to `/dev/null` only.

## Alternatives Considered

### Option A: Duplicate host-local config and re-encrypt secret for `aliyun-acorn`

- Pros: Minimal, preserves `acorn`, matches current host-local convention, easy rollback.
- Cons: Two host modules can drift until final cutover removes one.

### Option B: Move `hosts/acorn/modules/vaultwarden.nix` into a shared host parameterized module

- Pros: Less duplication over time.
- Cons: Larger refactor during a secret-sensitive deployment migration; adds abstraction before the cutover behavior is proven.

### Option C: Copy the existing `acorn` `.age` file to `aliyun-acorn`

- Pros: Fastest file operation.
- Cons: Wrong recipient; likely activation failure and hidden runtime risk.

### Decision

- Choose Option A.
- It is the smallest safe dual-run change, preserves rollback, and avoids broad module churn while handling the secret correctly.
- Explicitly reject Option C because it can produce a misleading repository state.

## Migration / Rollout / Rollback

### Migration Plan

- No Vaultwarden data migration in this task.
- Add the `aliyun-acorn` service declaration and re-encrypted environment secret.
- Later operational cutover must handle DNS/ACME readiness and data migration or backup/restore outside this PR.

### Rollout Plan

- Merge PR after Nix evaluation/build, secret decryptability check, review, walkthrough, and wiki writeback.
- Deploy manually to `aliyun-acorn` after reviewing DNS routing for `vault.0xc1.space`.
- Keep `acorn` available as rollback while dual-run is being tested.

### Rollback Plan

- Revert the PR or remove:
  - `hosts/aliyun-acorn/modules/vaultwarden.nix`
  - the import from `hosts/aliyun-acorn/default.nix`
  - `hosts/aliyun-acorn/secrets/vaultwarden-env.age`
  - the `vaultwarden-env.age` entry in `hosts/aliyun-acorn/secrets/secrets.nix`
- No data rollback is required for this config-only PR because `acorn` remains unchanged.

## Observability

- Runtime checks after deploy should inspect `vaultwarden.service`, `nginx.service`, `fail2ban.service`, ACME certificate status, and `/run/agenix/vaultwarden-env` ownership.
- Repository verification will not perform live checks on `aliyun-acorn` unless separately requested.

## Security & Privacy

- Secret plaintext must never be logged or written to committed files.
- The old acorn private key is an input only, not a repository artifact.
- The new `vaultwarden-env.age` must decrypt with the `aliyunAcorn` identity and should not be decryptable only by the old acorn recipient.
- Keeping two deployments with one domain can create operational confusion; traffic routing and data ownership must be managed explicitly during real cutover.

## Testing Strategy

- `agenix -d hosts/aliyun-acorn/secrets/vaultwarden-env.age -i /home/c1/.ssh/id_ed25519 > /dev/null`
- `nix eval --impure .#nixosConfigurations.aliyun-acorn.config.services.vaultwarden.enable`
- `nix eval --impure .#nixosConfigurations.aliyun-acorn.config.services.nginx.virtualHosts."vault.0xc1.space".locations."/notifications/hub".proxyPass`
- `nix eval --impure .#nixosConfigurations.aliyun-acorn.config.age.secrets.vaultwarden-env.owner`
- `nix build --impure --no-link .#nixosConfigurations.aliyun-acorn.config.system.build.toplevel`

## Milestones

- Milestone 1: Add config and secret.
  - Acceptance: files exist, `acorn` remains unchanged, new secret decrypts with target identity.
  - Rollback impact: revert the PR.
- Milestone 2: Verify and review.
  - Acceptance: Nix checks pass or blockers are documented; review-change passes.
  - Rollback impact: no deployed state changed by this task.

## Open Questions

- None blocking implementation.

## Implementation Notes

- Expected changed files:
  - `hosts/aliyun-acorn/default.nix`
  - `hosts/aliyun-acorn/modules/vaultwarden.nix`
  - `hosts/aliyun-acorn/secrets/secrets.nix`
  - `hosts/aliyun-acorn/secrets/vaultwarden-env.age`
  - `.legion/tasks/aliyun-acorn-vaultwarden-dualrun/**`

## References

- Plan: `.legion/tasks/aliyun-acorn-vaultwarden-dualrun/plan.md`
- Research: `.legion/tasks/aliyun-acorn-vaultwarden-dualrun/docs/research.md`
- Existing source config: `hosts/acorn/modules/vaultwarden.nix`
- Target host: `hosts/aliyun-acorn/default.nix`

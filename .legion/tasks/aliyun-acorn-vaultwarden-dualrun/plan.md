# Aliyun Acorn Vaultwarden Dual Run

## Task ID
`aliyun-acorn-vaultwarden-dualrun`

## Goal
Add a Vaultwarden deployment to `aliyun-acorn` while keeping the existing `acorn` deployment in place for a staged dual-run migration.

## Problem
Vaultwarden currently exists only under `hosts/acorn`. The user wants `aliyun-acorn` to be able to run the same service before removing or cutting over from `acorn`. The service depends on host-local NixOS imports, nginx vhost wiring, fail2ban integration, and an agenix environment secret. The agenix secret must be re-encrypted because `hosts/acorn/secrets/vaultwarden-env.age` is encrypted for the old acorn key while `aliyun-acorn` should decrypt with the current `/home/c1/.ssh/id_ed25519` key.

## Acceptance
- `acorn` keeps its current Vaultwarden configuration and secret declarations.
- `aliyun-acorn` has a host-local Vaultwarden module or import that enables `modules.services.vaultwarden`, configures `services.vaultwarden`, and exposes the existing `vault.0xc1.space` nginx vhost shape.
- `aliyun-acorn` declares `age.secrets.vaultwarden-env` with `vaultwarden:vaultwarden` ownership and `0400` mode.
- `hosts/aliyun-acorn/secrets/secrets.nix` includes a `vaultwarden-env.age` rule encrypted to the `aliyunAcorn` recipient.
- The encrypted `hosts/aliyun-acorn/secrets/vaultwarden-env.age` file is created only when valid secret material is available; do not add a misleading encrypted copy that `aliyun-acorn` cannot decrypt.
- Nix evaluation/build checks cover `.#nixosConfigurations.aliyun-acorn` and confirm the service/vhost/secret shape.
- Secret re-encryption uses the user-provided old acorn private key only as a transient decrypt identity and writes a new `aliyun-acorn` `.age` file encrypted to the `aliyunAcorn` recipient.

## Scope
- Add `hosts/aliyun-acorn/modules/vaultwarden.nix` or equivalent host-local config based on the existing `hosts/acorn/modules/vaultwarden.nix` shape.
- Import the new `aliyun-acorn` Vaultwarden config from `hosts/aliyun-acorn/default.nix`.
- Update `hosts/aliyun-acorn/secrets/secrets.nix` for `vaultwarden-env.age` when the encrypted file can also be produced correctly.
- Preserve `modules/services/vaultwarden.nix` unless validation shows a host-agnostic bug directly blocking this task.
- Write Legion verification, review, walkthrough, and wiki artifacts for the task.

## Non-goals
- Do not remove Vaultwarden from `acorn` in this task.
- Do not change the public Vaultwarden domain away from `vault.0xc1.space` unless explicitly requested later.
- Do not change DNS, ACME account settings, or deploy with `nixos-rebuild switch`.
- Do not rotate Vaultwarden admin tokens, SMTP credentials, database credentials, or user data.
- Do not expose or persist Vaultwarden secret plaintext in repository files, logs, or chat output.

## Assumptions
- Dual-run means both hosts may have the same declarative Vaultwarden vhost; traffic cutover is handled outside this repository, typically by DNS or proxy routing.
- `aliyun-acorn` should use `/home/c1/.ssh/id_ed25519`, whose public key matches the `aliyunAcorn` recipient already declared in `hosts/aliyun-acorn/secrets/secrets.nix`.
- The user-provided `./acorn_id_ed25519` private key matches the old `hosts/acorn/secrets/secrets.nix` recipient and can be used to decrypt the existing secret.
- The current `/home/c1/.ssh/id_ed25519` public key matches the `aliyunAcorn` recipient already declared in `hosts/aliyun-acorn/secrets/secrets.nix`.

## Constraints
- Follow Legion workflow end to end.
- Production configuration changes must happen inside the required `git-worktree-pr` envelope after this contract is stable.
- Keep the change minimal and host-local where possible.
- Do not revert or modify unrelated user/agent changes.
- Do not leak secret values during validation or documentation.

## Risks
- A copied `.age` file encrypted to the wrong recipient would make Nix build appear healthy while `aliyun-acorn` fails to activate the secret at runtime.
- Running the same `vault.0xc1.space` vhost on two hosts is operationally safe only if external routing is controlled; simultaneous public traffic without data replication planning could diverge state.
- The current Vaultwarden data directory/database location is not explicitly migrated by this task; config dual-run alone does not synchronize user vault data.
- ACME issuance can fail if DNS is not routed to `aliyun-acorn` when that host first activates the vhost.

## Design Summary
- Treat this as a staged dual-run enablement, not a cutover.
- Copy the current host-local Vaultwarden shape from `acorn` to `aliyun-acorn`, preserving service ports, nginx websocket routes, backup directory, and fail2ban behavior through the shared module.
- Keep `acorn` unchanged so rollback is simply not routing traffic to `aliyun-acorn` or reverting the new host-local config.
- Gate final implementation on producing a correctly encrypted `aliyun-acorn` `vaultwarden-env.age` using the old acorn key for decryption and the current `aliyunAcorn` key for encryption.

## Phases
1. Materialize this Legion task contract and checklist.
2. Enter the required `git-worktree-pr` envelope for production config edits.
3. Implement the `aliyun-acorn` Vaultwarden host config and secret declaration only when the encrypted secret file can be made valid.
4. Run Nix eval/build and targeted config-shape verification.
5. Review the implementation for deployment safety and secret-handling regressions.
6. Produce walkthrough/PR artifacts and update the Legion wiki.

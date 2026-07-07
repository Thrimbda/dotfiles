# Change Review: Acorn Aliyun Host Profile Rename

## Decision

PASS

## Blocking Findings

None.

## Scope Review

- The old Azure/development-oriented `hosts/acorn` active profile is removed.
- The former `hosts/aliyun-acorn` profile now occupies `hosts/acorn` and exposes `networking.hostName = "acorn"`.
- Active Nix references to `nixosConfigurations.aliyun-acorn`, `aliyunAcorn`, `frpc-aliyun-acorn-*`, and `hosts/aliyun-acorn` were updated or removed.
- Historical `.legion` records were not bulk rewritten; the new task docs record the current cutover instead.
- No out-of-scope remote deploy, DNS, Terraform, Aliyun API, data migration, or key rotation was performed.

## Security Lens

Applied, because the change moves encrypted age secret files and recipient metadata.

Result: no blocking security finding.

- Encrypted `.age` files were moved with the host profile; their contents were not decrypted or edited.
- Public key strings in `secrets.nix` were preserved while local variable names changed from `aliyunAcorn` to `acorn`.
- The root-level `acorn_id_ed25519` material was not touched.
- No new recipient, secret path outside the renamed host profile, or plaintext secret was introduced.

## Verification Reviewed

- `nix eval --json --no-write-lock-file --apply 'configs: { acorn = builtins.hasAttr "acorn" configs; aliyunAcorn = builtins.hasAttr "aliyun-acorn" configs; }' .#nixosConfigurations` returned `{"acorn":true,"aliyunAcorn":false}`.
- `nix eval --raw --no-write-lock-file .#nixosConfigurations.acorn.config.networking.hostName` returned `acorn`.
- `nix eval --raw --no-write-lock-file './hosts/acorn/image#aliyun-image.system'` returned `x86_64-linux`.
- `nix build --dry-run --no-write-lock-file './hosts/acorn/image#aliyun-image'` planned the image derivation successfully.
- `git diff --check` passed.
- Active host source/docs stale-reference search passed with no matches.

## Residual Risks

- Live ECS boot, SSH reachability, ACME issuance, and service health remain unproven until a separate deploy/validation task runs against the remote host.
- Any external automation outside this repository that still invokes `nixosConfigurations.aliyun-acorn` or `./hosts/aliyun-acorn/image` must be updated separately; no compatibility alias was intentionally kept.

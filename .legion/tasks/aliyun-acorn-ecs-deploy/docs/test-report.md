# Test Report: Aliyun Acorn ECS Deploy

## Summary

PASS for repository-side validation. The nested image flake now evaluates, the Alibaba Cloud QCOW2 image builds successfully on this Linux host, README changes pass whitespace checks, and sensitive-pattern review found only policy text rather than secrets.

Live Aliyun upload/import/instance operations were not run because they create or depend on cloud-side resources and still require explicit confirmation of bucket, network, security group, instance type, SSH source CIDR, and cleanup policy.

## Commands And Results

| Check | Command | Result |
|---|---|---|
| Image flake system eval | `nix eval --raw './hosts/aliyun-acorn/image#aliyun-image.system'` | PASS. Returned `x86_64-linux`. |
| Image build dry-run | `nix build --dry-run './hosts/aliyun-acorn/image#aliyun-image'` | PASS. Planned the image build through `nixos-disk-image.drv`. |
| Actual image build | `nix build --no-link './hosts/aliyun-acorn/image#aliyun-image'` | PASS. Built without creating a repository `result` symlink. |
| Image output path | `nix build --print-out-paths --no-link './hosts/aliyun-acorn/image#aliyun-image'` | PASS. Output: `/nix/store/3q240pib2zgaxpjijgb0inb77fkglhg5-nixos-disk-image`. |
| Output contents | Read `/nix/store/3q240pib2zgaxpjijgb0inb77fkglhg5-nixos-disk-image` | PASS. Contains `nixos-aliyun-acorn.qcow2` and `nix-support/`. |
| Output size | `nix path-info -S '/nix/store/3q240pib2zgaxpjijgb0inb77fkglhg5-nixos-disk-image'` | PASS. Store path size is `13396763488` bytes. |
| Whitespace | `git diff --check` | PASS. No whitespace errors. |
| Sensitive pattern scan | Grep changed markdown for `AccessKeys`, `tfvars`, `private key`, `PRIVATE KEY`, `ALIYUN_ACCESS`, `AccessKeySecret`, `AccessKeyId` | PASS. Matches are policy/runbook text warning not to commit secrets; no secret value or private key material found. |

## Why These Checks

- `nix eval` directly proves the stale nested `flake.lock` blocker is fixed.
- `nix build --dry-run` proves Nix can plan the ECS image derivation.
- The actual `nix build --no-link` is stronger evidence than dry-run and proves the QCOW2 artifact can be produced on this host without committing it.
- `git diff --check` and the sensitive-pattern scan address the main documentation risks: whitespace errors and accidental credential/state leakage.

## Skipped Checks

- `aliyun --profile prod sts GetCallerIdentity`: skipped because live account identity is not required to validate repository changes and may expose account metadata in task evidence.
- `ossutil cp` / `ossutil stat`: skipped because no staging bucket/object has been confirmed and upload writes cloud-side state.
- `aliyun ecs ImportImage`: skipped because it imports a custom image into Alibaba Cloud and depends on confirmed OSS bucket, object, import role, and paid-resource intent.
- `aliyun ecs RunInstances --DryRun true` and live `RunInstances`: skipped because image ID, VPC/vSwitch/security group, instance type, SSH ingress, and auto-release policy require explicit confirmation.

## Residual Risks

- ECS first boot remains unvalidated until the built QCOW2 is uploaded, imported with `BootMode=UEFI`, and started as an ECS instance.
- The Aliyun account may lack the default image-import role or required OSS/ECS permissions.
- The chosen validation network/security group may still block SSH or metadata/cloud-init behavior even though the image builds successfully.

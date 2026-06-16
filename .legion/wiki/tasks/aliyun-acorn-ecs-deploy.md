# Aliyun Acorn ECS Deploy

## Metadata

- `task-id`: `aliyun-acorn-ecs-deploy`
- `status`: `completed`
- `risk`: `high`
- `schema-version`: `current`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- Restored `hosts/aliyun-acorn/image#aliyun-image` by updating the nested image flake lock to the current dotfiles input graph.
- Added a guarded Alibaba Cloud ECS custom-image runbook to `hosts/aliyun-acorn/README.md` for build, OSS upload, `ImportImage`, first-boot SSH access, `RunInstances`, validation, and cleanup.
- Repository-side validation passed, including full QCOW2 image build on Linux and whitespace/sensitive-pattern checks.
- Live Aliyun upload, image import, and validation instance creation remain intentionally unrun until cloud resource choices, cost, SSH ingress, and cleanup policy are confirmed.

## Reusable Decisions

- Dotfiles owns the `aliyun-acorn` NixOS host/image target and runbook; durable ECS/VPC/security-group ownership should move to `~/Work/aliyun-ops` Terraform if the host becomes long-lived.
- `aliyun-acorn` ECS imports must use explicit `BootMode=UEFI` with `Architecture=x86_64`, `OSType=linux`, and `Format=qcow2`; relying on the ECS `ImportImage` BIOS default is unsafe for this EFI/systemd-boot image.
- First-boot access should be injected at runtime through cloud-init `UserData` built from local public-key material, not committed authorized keys, passwords, or private keys.
- Paid Aliyun writes remain gated on confirmed bucket, same-region OSS object, image-import role, VPC/vSwitch/security group, instance type, SSH CIDR, dry-run/cost review, and cleanup path.

## Evidence

- `nix eval --raw './hosts/aliyun-acorn/image#aliyun-image.system'` returned `x86_64-linux`.
- `nix build --dry-run './hosts/aliyun-acorn/image#aliyun-image'` planned the image derivation.
- `nix build --no-link './hosts/aliyun-acorn/image#aliyun-image'` built `/nix/store/3q240pib2zgaxpjijgb0inb77fkglhg5-nixos-disk-image/nixos-aliyun-acorn.qcow2`.
- `git diff --check` passed.
- Sensitive-pattern review found policy/runbook mentions only, not secret values or key material.
- `docs/review-change.md` recorded PASS with no blocking findings.
- Implementation PR #88 merged as `0a5e6f0e391a9a52b9ca650551162dd19a49985b`, followed by worktree cleanup and main checkout refresh.

## Follow-Up

- Confirm the live validation inputs before cloud writes: OSS bucket/object, import role, VPC/vSwitch/security group, instance type, operator SSH CIDR, auto-release time, cost/dry-run result, and cleanup owner.
- If confirmed, upload the QCOW2, import it as an ECS custom image, start a temporary validation instance, validate serial console/cloud-init/SSH/root partition growth, then clean up or record retained resources.
- If `aliyun-acorn` becomes durable infrastructure, create a separate `~/Work/aliyun-ops` Terraform task rather than keeping one-off CLI state as the long-term source of truth.

## Related Raw Sources

- `plan`: `.legion/tasks/aliyun-acorn-ecs-deploy/plan.md`
- `log`: `.legion/tasks/aliyun-acorn-ecs-deploy/log.md`
- `tasks`: `.legion/tasks/aliyun-acorn-ecs-deploy/tasks.md`
- `research`: `.legion/tasks/aliyun-acorn-ecs-deploy/docs/research.md`
- `rfc`: `.legion/tasks/aliyun-acorn-ecs-deploy/docs/rfc.md`
- `rfc-review`: `.legion/tasks/aliyun-acorn-ecs-deploy/docs/review-rfc.md`
- `test-report`: `.legion/tasks/aliyun-acorn-ecs-deploy/docs/test-report.md`
- `change-review`: `.legion/tasks/aliyun-acorn-ecs-deploy/docs/review-change.md`
- `report`: `.legion/tasks/aliyun-acorn-ecs-deploy/docs/report-walkthrough.md`

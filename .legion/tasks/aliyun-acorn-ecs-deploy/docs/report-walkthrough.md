# Report Walkthrough: Aliyun Acorn ECS Deploy

Mode: implementation

## Summary

- Restored the `hosts/aliyun-acorn/image#aliyun-image` nested flake by updating its lock file to include the current dotfiles root input graph.
- Expanded `hosts/aliyun-acorn/README.md` from import notes into a guarded Alibaba Cloud ECS deployment runbook.
- Built the QCOW2 image locally and recorded explicit boundaries for live Aliyun upload/import/instance creation.

## Changed Files

- `hosts/aliyun-acorn/image/flake.lock`
  - Adds current root inputs needed by the nested image flake, including `caelestia-shell`, `qtengine`, and `sidra`.
  - Fixes the previous `attribute 'qtengine' missing` image-evaluation failure.
- `hosts/aliyun-acorn/README.md`
  - Documents the Aliyun ops shell handoff via `~/Work/aliyun-ops`.
  - Adds build, OSS upload, image-import, first-boot user-data, `RunInstances` dry-run/live gate, validation, and cleanup steps.
  - Keeps paid cloud writes behind explicit bucket/network/security/cost/cleanup confirmation.
- `.legion/tasks/aliyun-acorn-ecs-deploy/**`
  - Records contract, research, RFC, RFC review, verification, change review, and delivery evidence.

## Design Evidence

- Research: `.legion/tasks/aliyun-acorn-ecs-deploy/docs/research.md`
- RFC: `.legion/tasks/aliyun-acorn-ecs-deploy/docs/rfc.md`
- RFC review: `.legion/tasks/aliyun-acorn-ecs-deploy/docs/review-rfc.md`

The RFC chose the smallest current path: dotfiles owns the Nix image and runbook, while durable Aliyun infrastructure remains a follow-up in `~/Work/aliyun-ops` if the host becomes long-lived.

## Verification Evidence

From `.legion/tasks/aliyun-acorn-ecs-deploy/docs/test-report.md`:

- PASS: `nix eval --raw './hosts/aliyun-acorn/image#aliyun-image.system'` returned `x86_64-linux`.
- PASS: `nix build --dry-run './hosts/aliyun-acorn/image#aliyun-image'` planned the image derivation.
- PASS: `nix build --no-link './hosts/aliyun-acorn/image#aliyun-image'` built the QCOW2 image.
- PASS: output path is `/nix/store/3q240pib2zgaxpjijgb0inb77fkglhg5-nixos-disk-image`, containing `nixos-aliyun-acorn.qcow2`.
- PASS: `git diff --check`.
- PASS: sensitive-pattern scan found only policy/runbook text, not secret values.

## Review Status

`docs/review-change.md` verdict: PASS.

- Scope stayed within the approved files and Legion evidence.
- Security lens was applied because the change documents cloud credentials, identity, OSS upload, custom image import, ECS instance creation, and SSH access.
- No blocking findings.

## Not Done

- No Aliyun OSS upload was run.
- No ECS custom image was imported.
- No ECS validation instance was created.

Those steps are intentionally gated because they write cloud-side state and require explicit confirmation of bucket, VPC/vSwitch/security group, instance type, SSH source CIDR, cost/dry-run result, and cleanup policy.

## Residual Risks

- Actual ECS first boot remains unvalidated until a confirmed live run imports and starts the image with `BootMode=UEFI`.
- The target Aliyun account may need image-import role or permission setup.
- A durable long-lived `aliyun-acorn` host should get a follow-up `aliyun-ops` Terraform task instead of relying on one-off CLI state.

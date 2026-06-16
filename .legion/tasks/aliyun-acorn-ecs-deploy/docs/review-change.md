# Review Change: Aliyun Acorn ECS Deploy

## Verdict

PASS

## Scope Review

- In scope: `hosts/aliyun-acorn/image/flake.lock` updates the nested image flake input graph so the image target can evaluate/build again.
- In scope: `hosts/aliyun-acorn/README.md` adds the approved guarded runbook for build, Aliyun ops shell, OSS upload, `ImportImage`, `RunInstances` dry-run/live gate, first-boot validation, and cleanup.
- In scope: `.legion/tasks/aliyun-acorn-ecs-deploy/**` records contract, research, RFC, review, verification, and task evidence.
- Out of scope avoided: no changes to `~/Work/aliyun-ops`, no new Terraform module, no helper scripts, no cloud credentials, no cloud state, no image artifacts in Git.

## Security Lens

Security lens applied because the change documents cloud credentials, identity, OSS upload, image import, ECS instance creation, SSH access, and cleanup.

- No AccessKey, CLI profile, private key, Terraform state, `tfvars`, password, account export, or QCOW2 artifact is committed.
- README explicitly keeps credentials local to `aliyun configure` and warns not to commit or paste AccessKeys into shell history or repo files.
- SSH access is injected at runtime from a local public key through cloud-init `UserData`; no password SSH or committed authorized key is introduced.
- Paid-resource operations are gated behind explicit confirmation of bucket, VPC/vSwitch/security group, instance type, SSH CIDR, cost/dry-run result, and cleanup path.
- The runbook calls out `BootMode=UEFI`, same-region OSS object, import role preflight, and cleanup ordering to reduce non-booting image and orphan-resource risk.

## Verification Review

- `docs/test-report.md` records direct evidence that the stale lock blocker is fixed and the image builds.
- Actual image build passed with output `/nix/store/44yiwbiq8qipv1hnsl75lh8kid8k4g4z-nixos-disk-image/nixos-aliyun-acorn.qcow2`.
- `git diff --check` passed.
- Sensitive-pattern scan found only policy/runbook mentions, not secret values.
- Live Aliyun validation was correctly skipped because it requires explicit cloud resource confirmation.

## Blocking Findings

None.

## Residual Risks

- ECS first boot is not proven until the QCOW2 is uploaded, imported with `BootMode=UEFI`, and started on Aliyun.
- The target account may lack `AliyunECSImageImportDefaultRole`, OSS permissions, ECS inventory, or suitable network/security-group configuration.
- If `aliyun-acorn` should become a durable long-lived host, a follow-up task should put ECS/VPC/security-group ownership into `~/Work/aliyun-ops` Terraform rather than relying on one-off CLI state.

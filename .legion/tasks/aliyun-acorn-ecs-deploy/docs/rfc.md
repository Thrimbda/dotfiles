# RFC: Aliyun Acorn ECS Deployment Path

> **Profile**: RFC Heavy
> **Status**: Draft
> **Owners**: OpenCode / c1
> **Created**: 2026-06-16
> **Last Updated**: 2026-06-16

## Executive Summary

- **Problem**: `aliyun-acorn` has a NixOS ECS image target, but the nested image flake is stale and no controlled Aliyun upload/import/first-boot path exists yet.
- **Decision**: Fix the image target first, then add a minimal deployment runbook under `hosts/aliyun-acorn/README.md`; do not create durable Aliyun infrastructure in dotfiles or run paid cloud writes without explicit authorization.
- **Why now**: The user wants to move `/home/c1/dotfiles/hosts/aliyun-acorn` to Aliyun and explicitly asked to reuse `~/Work/aliyun-ops` operation methods.
- **Impact**: Dotfiles becomes capable of producing and documenting an ECS-importable QCOW2 workflow; Aliyun account state remains operator-controlled.
- **Risks**: Image lock drift, UEFI/BIOS mismatch, OSS import permissions, SSH/cloud-init first-boot failure, and leftover paid resources.
- **Rollout**: Implement the local fix/runbook in a PR worktree, verify local Nix image evaluation/build shape, then optionally run Aliyun preflight/live commands after user confirmation.
- **Rollback**: Revert dotfiles changes; for live cloud state, delete validation ECS instance, custom image, and staging OSS object/bucket according to recorded IDs.

## 1. Background / Motivation

The previous `aliyun-nixos-image-host` work created the NixOS host and image target but explicitly left full image realization, Aliyun ECS import, and first boot validation as external follow-up. Current local checks show root `nixosConfigurations.aliyun-acorn` still evaluates, but `hosts/aliyun-acorn/image#aliyun-image` fails before image realization because the nested `flake.lock` is missing current root inputs such as `qtengine`.

`~/Work/aliyun-ops` already defines the operating style for Alibaba Cloud: enter `nix-shell`, use local `aliyun configure` credentials, keep AccessKeys/profiles/state out of Git, use Terraform for durable infra, and record live CLI verification only when real cloud changes are explicitly in scope.

## 2. Goals

- Restore `hosts/aliyun-acorn/image#aliyun-image` evaluation/buildability for the current root flake input graph.
- Document a concrete ECS custom-image deployment flow for `aliyun-acorn`: build QCOW2, upload to OSS, import image with UEFI, create a validation ECS instance, verify first boot, and clean up.
- Reuse `aliyun-ops` conventions: local `prod` profile, `cn-shanghai` default, no committed secrets/state, and explicit confirmation before paid cloud writes.
- Keep repository changes minimal and reviewable.

## 3. Non-goals

- Do not create or modify Aliyun paid resources until the user explicitly confirms the target region/resources and cleanup path.
- Do not move Aliyun Terraform ownership into dotfiles.
- Do not refactor or modify `~/Work/aliyun-ops` in this task.
- Do not configure application workloads beyond proving `aliyun-acorn` reaches first boot and SSH/cloud-init basics.
- Do not commit QCOW2 outputs, Terraform state, `tfvars`, Aliyun CLI profiles, AccessKeys, or cloud account exports.

## 4. Constraints

- **Compatibility**: The ECS image import must use `Architecture=x86_64`, `OSType=linux`, `Format=qcow2`, and `BootMode=UEFI` to match the current Nix image definition.
- **Security**: SSH ingress should be restricted to an operator CIDR by default; broad `0.0.0.0/0` access requires explicit acceptance.
- **Operations**: Live commands run from `~/Work/aliyun-ops` or an equivalent shell that provides Aliyun CLI, ossutil, and Terraform.
- **State**: Dotfiles may record command templates and non-sensitive decisions, but cloud resource IDs from real runs should be recorded in task evidence only when safe to disclose.
- **Image import**: The QCOW2 object must be in an OSS bucket in the same region as `ImportImage`, and the account must have an ECS image-import role/permission available before live import.
- **First-boot access**: SSH access must be injected at runtime through non-secret public-key material; do not rely on passwords or committed authorized keys.
- **Workflow**: Production repository changes happen inside `git-worktree-pr` after RFC review passes.

## 5. Proposed Design

### 5.1 Repository Changes

- Update `hosts/aliyun-acorn/image/flake.lock` so the nested image flake tracks the current root input graph, including inputs introduced after the old lock was written.
- Update `hosts/aliyun-acorn/README.md` with an operator runbook:
  - local build command and expected output shape;
  - Aliyun ops shell prerequisites;
  - OSS staging bucket/object naming guidance;
  - `ImportImage` command template with `BootMode=UEFI` and `DetectionStrategy=Standard`;
  - instance preflight/live command template using `DryRun=true` first;
  - first-boot validation and cleanup checklist.
- Do not add helper scripts unless README command templates become too error-prone after implementation review.

### 5.2 Operator Flow

1. Build the image from dotfiles:

   ```bash
   nix build ./hosts/aliyun-acorn/image#aliyun-image
   ```

2. Enter the Aliyun ops environment and confirm local identity without printing secrets:

   ```bash
   cd ~/Work/aliyun-ops
   nix-shell
   aliyun --profile prod sts GetCallerIdentity
   ```

3. Choose region and staging object. Default to `cn-shanghai` to match current `aliyun-ops` ECS/OSS patterns. Use a dedicated private image-import bucket or an approved existing bucket in that same region. Recommended object prefix:

   ```text
   ecs-images/aliyun-acorn/YYYYMMDD/nixos-aliyun-acorn.qcow2
   ```

4. Upload the QCOW2 with `ossutil cp` to the public Shanghai endpoint from local machines, or the internal endpoint from same-region Aliyun resources. Confirm the object exists with `ossutil stat` before import.

5. Preflight account-side image import assumptions before the live import:

   ```bash
   aliyun --profile prod ecs DescribeRegions
   aliyun --profile prod ram GetRole --RoleName "$ALIYUN_ECS_IMAGE_IMPORT_ROLE"
   ossutil stat "oss://$ALIYUN_ACORN_IMAGE_BUCKET/$ALIYUN_ACORN_IMAGE_OBJECT" \
     -e oss-cn-shanghai.aliyuncs.com
   ```

   Use `ALIYUN_ECS_IMAGE_IMPORT_ROLE=AliyunECSImageImportDefaultRole` unless the account has a different reviewed role name for ECS image import.

6. Import the custom image with explicit UEFI boot mode:

   ```bash
   aliyun --profile prod ecs ImportImage \
     --RegionId cn-shanghai \
     --RoleName "$ALIYUN_ECS_IMAGE_IMPORT_ROLE" \
     --Architecture x86_64 \
     --OSType linux \
     --Platform 'Customized Linux' \
     --BootMode UEFI \
     --ImageName nixos-aliyun-acorn-YYYYMMDD \
     --Description 'NixOS aliyun-acorn custom image YYYYMMDD' \
     --DetectionStrategy Standard \
     --DiskDeviceMapping.1.OSSBucket "$ALIYUN_ACORN_IMAGE_BUCKET" \
     --DiskDeviceMapping.1.OSSObject "$ALIYUN_ACORN_IMAGE_OBJECT" \
     --DiskDeviceMapping.1.Format qcow2 \
     --Tag.1.Key Project --Tag.1.Value dotfiles \
     --Tag.2.Key Component --Tag.2.Value aliyun-acorn
   ```

7. Poll image state with `DescribeImages` until available. Record the `ImageId` in task evidence if a live run is approved.

8. Generate first-boot cloud-init user data from a local public key at execution time. The file is local-only and must not be committed:

   ```bash
   ALIYUN_ACORN_SSH_PUBKEY_PATH="${ALIYUN_ACORN_SSH_PUBKEY_PATH:-$HOME/.ssh/id_ed25519.pub}"
   ALIYUN_ACORN_USER_DATA_FILE="${TMPDIR:-/tmp}/aliyun-acorn-user-data.yaml"
   install -m 600 /dev/null "$ALIYUN_ACORN_USER_DATA_FILE"
   {
     printf '%s\n' '#cloud-config'
     printf '%s\n' 'users:'
     printf '%s\n' '  - default'
     printf '%s\n' '  - name: c1'
     printf '%s\n' '    groups: [wheel, docker]'
     printf '%s\n' '    sudo: ["ALL=(ALL) NOPASSWD:ALL"]'
     printf '%s\n' '    shell: /run/current-system/sw/bin/zsh'
     printf '%s\n' '    ssh_authorized_keys:'
     printf '      - %s\n' "$(cat "$ALIYUN_ACORN_SSH_PUBKEY_PATH")"
     printf '%s\n' 'ssh_pwauth: false'
     printf '%s\n' 'disable_root: true'
   } > "$ALIYUN_ACORN_USER_DATA_FILE"
   ALIYUN_ACORN_USER_DATA_B64="$(base64 < "$ALIYUN_ACORN_USER_DATA_FILE" | tr -d '\n')"
   ```

9. Preflight instance creation with `DryRun=true`. Use an existing approved VPC/vSwitch/security group or a separately reviewed Terraform module. For temporary validation, prefer `PostPaid`, low-cost instance type, bounded `AutoReleaseTime`, `UserData`, and a restricted SSH source CIDR.

   ```bash
   aliyun --profile prod ecs RunInstances \
     --RegionId cn-shanghai \
     --ImageId "$ALIYUN_ACORN_IMAGE_ID" \
     --InstanceType "$ALIYUN_ACORN_INSTANCE_TYPE" \
     --SecurityGroupId "$ALIYUN_ACORN_SECURITY_GROUP_ID" \
     --VSwitchId "$ALIYUN_ACORN_VSWITCH_ID" \
     --InstanceName aliyun-acorn-validation \
     --HostName aliyun-acorn \
     --SystemDisk.Category cloud_essd \
     --SystemDisk.Size 40 \
     --InternetMaxBandwidthOut 5 \
     --UserData "$ALIYUN_ACORN_USER_DATA_B64" \
     --AutoReleaseTime "$ALIYUN_ACORN_AUTO_RELEASE_TIME" \
     --DryRun true
   ```

10. If the dry run passes and user confirms, create the validation instance by removing `--DryRun true`. Validate serial console/system log, cloud-init, DHCP, SSH as `c1`, root partition growth, and `uname -a`/`nixos-version` after login.

11. Clean up temporary resources: release validation instance, delete unused custom image, remove staging OSS object, and remove the staging bucket only if it was created solely for this task.

### 5.3 Cloud Resource Boundary

This RFC intentionally does not decide the final VPC/vSwitch/security-group ownership. Two acceptable live-run modes remain:

- **Validation mode**: use existing approved `cn-shanghai` network resources from `aliyun-ops`, with temporary instance auto-release and narrow SSH ingress.
- **Durable mode**: create a follow-up `aliyun-ops` Terraform task for a dedicated Linux/NixOS ECS module before running `apply`.

The implementation should document both modes and require the user to choose before live resource creation.

## 6. Alternatives Considered

### Option A: Dotfiles runbook plus local image fix

- Pros: Smallest change; keeps dotfiles responsible for Nix image production; aligns with the user request to find but not rewrite `aliyun-ops`; easy to review and rollback.
- Cons: Durable ECS resources are not declaratively managed until a later `aliyun-ops` task.
- Fit: Best current choice because the immediate blocker is local image buildability and first-boot procedure clarity.

### Option B: Add a new Terraform module in `~/Work/aliyun-ops`

- Pros: Best long-term ownership for ECS/VPC/security resources; plan/apply/destroy become reproducible.
- Cons: Cross-repo scope; requires a separate Legion task/envelope in `aliyun-ops`; still depends on the dotfiles image target being fixed first.
- Fit: Good follow-up if `aliyun-acorn` should become a persistent host rather than a one-off validation instance.

### Option C: One-off manual CLI deploy with no repository changes

- Pros: Fastest path to try a boot.
- Cons: Leaves no durable runbook, repeats the current problem, and makes cleanup/resource provenance harder.
- Fit: Rejected unless the user explicitly asks for an emergency live-only experiment.

### Decision

Choose Option A now. Record Option B as the durable-infra follow-up if the validation instance is promoted to a long-lived host.

## 7. Rollout And Rollback

### 7.1 Rollout Plan

- Milestone 1: Fix local image target.
- Milestone 2: Add README runbook with explicit Aliyun command templates and confirmation gates.
- Milestone 3: Run local verification. If authorized, run Aliyun identity/import/instance preflight and then live validation.

### 7.2 Rollback Plan

- Repository rollback: revert the image lock and README changes.
- Image import rollback: `DeleteImage` for the imported custom image after no instances/disks depend on it.
- Instance rollback: stop/release the validation ECS instance; confirm disks and public IP resources are released or intentionally retained.
- OSS rollback: delete the staging object; delete the bucket only if it was task-specific and empty.
- Security rollback: remove temporary SSH ingress rules if any were created outside Terraform.

## 8. Observability And First-boot Validation

- `ImportImage` response and `DescribeImages` state identify image import success/failure.
- ECS console/system log and serial console validate kernel/bootloader progress when SSH is unavailable.
- `cloud-init status --long`, `journalctl -u cloud-init -u cloud-config -u cloud-final`, and `networkctl status` validate first-boot initialization.
- `systemctl status sshd systemd-networkd cloud-init` validates reachability dependencies.
- `ssh c1@<public-ip>` using the local private key matching the runtime public key validates login without committed secrets.
- `df -h /` validates root partition growth.
- `nixos-version` and `/run/current-system` validate the expected NixOS generation.

## 9. Security And Privacy

- Use RAM user credentials configured through local Aliyun CLI profiles; do not write credentials into dotfiles or Legion evidence.
- Do not put private SSH keys, passwords, AccessKeys, or tokens in `UserData` or README examples.
- Prefer Aliyun key pair association or cloud-init authorized public keys, not password SSH.
- Restrict SSH ingress to an operator CIDR for validation.
- Treat Terraform state, Aliyun CLI profiles, image import logs containing account IDs, and local QCOW2 artifacts as non-committed local state.

## 10. Testing Strategy

- Local Nix:
  - `nix eval --json '.#hostMetadata."aliyun-acorn"'`
  - `nix eval --raw '.#nixosConfigurations.aliyun-acorn.config.system.build.toplevel.drvPath'`
  - `nix eval --raw './hosts/aliyun-acorn/image#aliyun-image.system'`
  - `nix build --dry-run './hosts/aliyun-acorn/image#aliyun-image'`
  - full `nix build './hosts/aliyun-acorn/image#aliyun-image'` if the local builder can realize the image in acceptable time/resources.
- Documentation/static:
  - `git diff --check`
  - sensitive path review for AccessKeys, profiles, tfstate, tfvars, and QCOW2 artifacts.
- Aliyun preflight, only after confirmation:
  - `aliyun --profile prod sts GetCallerIdentity`
  - `aliyun --profile prod ram GetRole --RoleName "$ALIYUN_ECS_IMAGE_IMPORT_ROLE"`
  - `ossutil stat "oss://$ALIYUN_ACORN_IMAGE_BUCKET/$ALIYUN_ACORN_IMAGE_OBJECT" -e oss-cn-shanghai.aliyuncs.com`
  - `aliyun --profile prod ecs ImportImage ... --DryRun true` if API accepts the dry-run combination.
  - `aliyun --profile prod ecs RunInstances ... --DryRun true`
- Aliyun live validation, only after confirmation:
  - Upload QCOW2, import image, create temporary validation instance, run first-boot checks, then clean up or record retained resources.

## 11. Milestones

- **Milestone 1: Image target repair**
  - Scope: update nested image lock or equivalent minimal input fix.
  - Acceptance: `./hosts/aliyun-acorn/image#aliyun-image.system` evaluates and image build dry-run reaches derivation planning.
  - Rollback impact: revert lock/input change.
- **Milestone 2: Deployment runbook**
  - Scope: update `hosts/aliyun-acorn/README.md` with Aliyun ops method and guarded command flow.
  - Acceptance: README contains build, upload, import, preflight, first-boot, and cleanup steps with no secrets.
  - Rollback impact: revert README update.
- **Milestone 3: Verification and optional live run**
  - Scope: run local Nix/static checks; if explicitly authorized, run Aliyun preflight/live commands.
  - Acceptance: `docs/test-report.md` records pass/fail and any live resource IDs or skipped reasons.
  - Rollback impact: repository rollback plus cloud cleanup if live resources were created.

## 12. Open Questions

- [ ] Which OSS bucket should stage the QCOW2 object for import?
- [ ] Should the first validation instance reuse existing `cn-shanghai-b` VPC/vSwitch/security group or wait for a dedicated `aliyun-ops` Terraform module?
- [ ] Which local public key path should be used for runtime cloud-init SSH access? Default assumption is `~/.ssh/id_ed25519.pub`.
- [ ] Should a successful validation instance be retained as the real `aliyun-acorn` host or released after smoke testing?

## 13. Implementation Notes

- Expected dotfiles changes:
  - `hosts/aliyun-acorn/image/flake.lock`
  - `hosts/aliyun-acorn/README.md`
  - `.legion/tasks/aliyun-acorn-ecs-deploy/docs/*`
- Do not edit `~/Work/aliyun-ops` unless the user explicitly expands scope.
- If image lock update causes broad input churn, inspect whether the nested image flake can safely follow the root path input without a stale standalone lock; choose the smaller stable fix.

## 14. References

- Plan: `.legion/tasks/aliyun-acorn-ecs-deploy/plan.md`
- Research: `.legion/tasks/aliyun-acorn-ecs-deploy/docs/research.md`
- Dotfiles:
  - `hosts/aliyun-acorn/default.nix`
  - `hosts/aliyun-acorn/image/flake.nix`
  - `hosts/aliyun-acorn/image/flake.lock`
  - `hosts/aliyun-acorn/README.md`
- Aliyun ops:
  - `~/Work/aliyun-ops/README.md`
  - `~/Work/aliyun-ops/AGENTS.md`
  - `~/Work/aliyun-ops/shell.nix`
  - `~/Work/aliyun-ops/terraform/aliyun-qmt-windows/README.md`
  - `~/Work/aliyun-ops/terraform/aliyun-kline-oss/README.md`

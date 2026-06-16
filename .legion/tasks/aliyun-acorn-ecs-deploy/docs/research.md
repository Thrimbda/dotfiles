# Research Notes: Aliyun Acorn ECS Deploy

## 1. Problem Restatement

- `hosts/aliyun-acorn` already defines a NixOS host and nested QCOW2 image flake for Alibaba Cloud ECS import, but the image target no longer evaluates because the nested image lock is stale.
- The task must bridge dotfiles image production with the existing `~/Work/aliyun-ops` cloud-operation style without committing credentials, Terraform state, image artifacts, or other sensitive local state.

## 2. Relevant Entry Points

- `hosts/aliyun-acorn/default.nix` - NixOS host target for ECS; sets `system = "x86_64-linux"`, hostname `aliyun-acorn`, DHCP via `systemd-networkd`, cloud-init with `AliYun` datasource, serial console on `ttyS0`, and UEFI/systemd-boot settings. Evidence: lines 4, 51-57, 71-97, 107-113.
- `hosts/aliyun-acorn/image/flake.nix` - nested image flake; extends `dotfiles.nixosConfigurations.aliyun-acorn` with `virtualisation/disk-image.nix`, `image.format = "qcow2"`, `efiSupport = true`, and `virtualisation.diskSize = 8192`. Evidence: lines 15-32.
- `hosts/aliyun-acorn/README.md` - current operator note says build `./hosts/aliyun-acorn/image#aliyun-image`, import QCOW2 through ECS custom image import, and match boot mode to UEFI/EFI. Evidence: lines 5-26.
- `.legion/wiki/tasks/aliyun-nixos-image-host.md` - historical handoff says local root evaluation/dry-run had passed, but full image realization and Aliyun import/first boot remained external validation. Evidence: lines 9-31.
- `~/Work/aliyun-ops/shell.nix` - the Aliyun ops shell provides `terraform`, `aliyun-cli`, `ossutil`, `sops`, and `age`; shellHook advertises `aliyun configure`, `aliyun sts GetCallerIdentity`, and Terraform plan commands. Evidence: lines 3-28.
- `~/Work/aliyun-ops/README.md` and `AGENTS.md` - credentials are configured locally with `aliyun configure`; do not commit AccessKeys, CLI profiles, plaintext passwords, Terraform state, `tfvars`, QMT account data, screenshots, or exported snapshots. Evidence: README lines 11-23, AGENTS lines 3-7.
- `~/Work/aliyun-ops/terraform/aliyun-qmt-windows/*` - current ECS/Terraform pattern uses provider profile `prod`, region `cn-shanghai`, zone `cn-shanghai-b`, VPC/vSwitch/security group resources, a PostPaid spot ECS instance, and local ignored Terraform state. Evidence: README lines 15-23, 31-55, 124-142; `main.tf` lines 17-20, 49-108.
- `~/Work/aliyun-ops/terraform/aliyun-kline-oss/*` - OSS pattern uses profile `prod`, region `cn-shanghai`, private bucket, `Standard` + `LRS`, lifecycle cleanup, and `ossutil cp` examples with public/internal Shanghai endpoints. Evidence: README lines 16-36, 68-82; `variables.tf` lines 1-22.

## 3. Existing Conventions

- `aliyun-ops` treats cloud credentials and provider state as local operator state, not repository state.
- Terraform is used for durable infrastructure in `aliyun-ops`; live `terraform apply` is only recorded after explicit task scope and validation.
- CLI checks are used for live verification after apply, for example `aliyun ecs DescribeSecurityGroupAttribute` in the RDP follow-up evidence.
- OSS bucket names are globally unique, so defaults must be overrideable or confirmed during real creation.
- Dotfiles should own the NixOS host/image definition; `aliyun-ops` should remain the reference for Aliyun account operations unless a separate cross-repo task explicitly changes it.

## 4. Local Command Evidence

- `nix eval --json '.#hostMetadata."aliyun-acorn"'` passed and returned `{"os":"nixos","path":".../hosts/aliyun-acorn","system":"x86_64-linux"}`. Nix also printed a non-blocking readonly eval-cache warning for `/home/c1/.cache/nix/eval-cache-v6/...sqlite`.
- `nix eval --raw '.#nixosConfigurations.aliyun-acorn.config.system.build.toplevel.drvPath'` passed and returned a toplevel derivation path.
- `nix build --dry-run '.#nixosConfigurations.aliyun-acorn.config.system.build.toplevel'` passed as a dry-run and listed 163 derivations to build plus 124 paths to fetch.
- `nix eval --raw './hosts/aliyun-acorn/image#aliyun-image.system'` failed while evaluating `config.system.build.image` with `attribute 'qtengine' missing` at `modules/desktop/caelestia.nix:278`. The nested `hosts/aliyun-acorn/image/flake.lock` input list for `dotfiles` includes `caelestia-shell` dependencies from the old graph but does not include current root inputs such as `qtengine` and `sidra`.
- `nix-shell --run 'command -v aliyun ... command -v ossutil ... command -v terraform ...'` in `~/Work/aliyun-ops` passed and resolved Aliyun CLI `3.1.5`, ossutil `v1.7.18`, and Terraform `1.14.0`.
- `aliyun ecs ImportImage help` confirms `RegionId` is required and import parameters include `Architecture`, `BootMode`, `OSType`, `Platform`, `ImageName`, `DetectionStrategy`, and `DiskDeviceMapping.n.OSSBucket/OSSObject/Format`. `BootMode` defaults to BIOS, so `aliyun-acorn` needs explicit `BootMode=UEFI`.
- `aliyun ecs RunInstances help` confirms `ImageId`, `InstanceType`, `SecurityGroupId`, `VSwitchId`, `SystemDisk.Size`, `SystemDisk.Category`, `AutoReleaseTime`, `DryRun`, `KeyPairName`, `UserData`, `InternetMaxBandwidthOut`, and `SpotStrategy` are relevant for a controlled first-boot validation instance.

## 5. Historical Decisions

- `aliyun-nixos-image-host` created the NixOS host and image target but left full image realization and Aliyun first boot as remaining external validation.
- `aliyun-cli-shell` in `aliyun-ops` added `aliyun-cli` to the Nix shell and established local-only credential setup with `aliyun configure`.
- `aliyun-kline-oss` in `aliyun-ops` established `ossutil` availability and private OSS bucket defaults, but did not run live `terraform apply` without explicit credentials and resource confirmation.
- `aliyun-qmt-windows-infra` established the current Shanghai ECS/VPC/Terraform operating style and recorded that account balance and local Terraform state can block or affect live operations.

## 6. Constraints And Non-goals

- Do not commit AccessKeys, Aliyun CLI profiles, Terraform state, `tfvars`, plaintext passwords, generated account exports, or QCOW2 image artifacts.
- Do not create, modify, or delete paid Aliyun resources without explicit confirmation of expected resources and cleanup path.
- Do not refactor `~/Work/aliyun-ops` inside this dotfiles task; use it as operational reference unless the user creates a separate task there.
- Do not solve post-boot application migration for `aliyun-acorn`; this task targets image import and first-boot reachability.

## 7. Risks And Pitfalls

- The nested image flake lock is stale; any deployment runbook is unusable until `hosts/aliyun-acorn/image#aliyun-image` evaluates again.
- ECS `ImportImage` defaults `BootMode` to BIOS; importing this image without `BootMode=UEFI` risks a non-booting custom image.
- ECS image import usually depends on same-region OSS object availability and correct RAM role/permission setup; missing role or bucket policy can block import.
- `RunInstances` can create paid resources immediately. Use `DryRun=true` for preflight where possible and set `AutoReleaseTime` for temporary validation instances.
- Public SSH exposure should be narrower than `0.0.0.0/0` unless explicitly accepted; the current Windows RDP opening is a separate validation-specific decision and should not be copied blindly to Linux SSH.
- If cloud-init fails, SSH may be unavailable; serial console/system log checks must be part of first-boot validation.

## 8. Unknowns

- [ ] Which OSS bucket should stage the QCOW2 import object: a new dedicated private image bucket, an existing bucket, or a short-lived operator bucket.
- [ ] Which VPC/vSwitch/security group should host `aliyun-acorn`: reuse the current Shanghai validation VPC or create a separate Linux validation network.
- [ ] Whether a suitable Aliyun key pair already exists for `c1`, or whether SSH access should rely on cloud-init user data during first boot.
- [ ] Whether the Aliyun account has the required image-import RAM role and permissions; confirm with a non-secret CLI preflight before live import.

## 9. References

- Plan: `.legion/tasks/aliyun-acorn-ecs-deploy/plan.md`
- Dotfiles:
  - `hosts/aliyun-acorn/default.nix`
  - `hosts/aliyun-acorn/image/flake.nix`
  - `hosts/aliyun-acorn/image/flake.lock`
  - `hosts/aliyun-acorn/README.md`
  - `.legion/wiki/tasks/aliyun-nixos-image-host.md`
- Aliyun ops:
  - `~/Work/aliyun-ops/README.md`
  - `~/Work/aliyun-ops/AGENTS.md`
  - `~/Work/aliyun-ops/shell.nix`
  - `~/Work/aliyun-ops/terraform/aliyun-qmt-windows/README.md`
  - `~/Work/aliyun-ops/terraform/aliyun-qmt-windows/main.tf`
  - `~/Work/aliyun-ops/terraform/aliyun-kline-oss/README.md`

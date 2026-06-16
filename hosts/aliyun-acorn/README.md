# aliyun-acorn

NixOS host/image target for importing into Alibaba Cloud ECS.

## Build

From the repository root:

```sh
nix build ./hosts/aliyun-acorn/image#aliyun-image
```

The image flake also exposes the explicit Linux package path:

```sh
nix build ./hosts/aliyun-acorn/image#packages.x86_64-linux.aliyun-image
```

The output is a QCOW2 disk image named with the `nixos-aliyun-acorn` base name.

## Import notes

- Import the QCOW2 image through Alibaba Cloud ECS custom image import.
- Match the imported image boot mode to UEFI/EFI; this host enables `systemd-boot` and EFI image support.
- First boot relies on generic QEMU guest support, DHCP via `systemd-networkd`, serial console on `ttyS0`, root partition growth, and cloud-init with the `AliYun` datasource enabled.
- Actual ECS first-boot validation is still required after upload/import.

## Deploy to Alibaba Cloud ECS

Use `~/Work/aliyun-ops` for Alibaba Cloud tooling and credentials. That repository provides `aliyun-cli`, `ossutil`, and Terraform through `nix-shell`; configure credentials locally with `aliyun configure` and do not commit AccessKeys, CLI profiles, Terraform state, `tfvars`, plaintext passwords, cloud account exports, or QCOW2 image artifacts.

The commands below are templates. Do not run the paid-resource steps until the target bucket, VPC/vSwitch/security group, instance type, SSH source CIDR, and cleanup path are confirmed.

### 1. Build the image

From this repository root:

```sh
nix build ./hosts/aliyun-acorn/image#aliyun-image
```

Keep the `result` symlink and QCOW2 output local. Do not commit or copy the image into this repository.

### 2. Enter the Aliyun ops shell

```sh
cd ~/Work/aliyun-ops
nix-shell
aliyun --profile prod sts GetCallerIdentity
```

Use the `prod` profile only if it is the intended target account. The identity command is a non-secret sanity check; do not paste AccessKeys into shell history or repository files.

### 3. Choose staging and runtime variables

Default to `cn-shanghai` unless a later task chooses a different region. The OSS bucket used for image import must be in the same region as `ImportImage`.

```sh
export ALIYUN_ACORN_REGION=cn-shanghai
export ALIYUN_ACORN_OSS_ENDPOINT=oss-cn-shanghai.aliyuncs.com
export ALIYUN_ACORN_IMAGE_BUCKET=REVIEWED_PRIVATE_IMAGE_BUCKET
export ALIYUN_ACORN_IMAGE_OBJECT=ecs-images/aliyun-acorn/$(date +%Y%m%d)/nixos-aliyun-acorn.qcow2
export ALIYUN_ECS_IMAGE_IMPORT_ROLE=AliyunECSImageImportDefaultRole
```

Use a dedicated private image-import bucket or an approved existing private bucket. If a new bucket is needed, create and lifecycle-manage it from `aliyun-ops`, not from dotfiles.

### 4. Upload the QCOW2 to OSS

From `~/Work/aliyun-ops`, point `ALIYUN_ACORN_QCOW2` at the built image in the dotfiles checkout:

```sh
export ALIYUN_ACORN_QCOW2=/home/c1/dotfiles/result/nixos-aliyun-acorn.qcow2
ossutil cp "$ALIYUN_ACORN_QCOW2" "oss://$ALIYUN_ACORN_IMAGE_BUCKET/$ALIYUN_ACORN_IMAGE_OBJECT" \
  -e "$ALIYUN_ACORN_OSS_ENDPOINT"
ossutil stat "oss://$ALIYUN_ACORN_IMAGE_BUCKET/$ALIYUN_ACORN_IMAGE_OBJECT" \
  -e "$ALIYUN_ACORN_OSS_ENDPOINT"
```

If running from an ECS instance in the same region, use the internal endpoint `oss-cn-shanghai-internal.aliyuncs.com` instead.

### 5. Preflight image import

Confirm the account can see the target region, import role, and staging object before live import:

```sh
aliyun --profile prod ecs DescribeRegions
aliyun --profile prod ram GetRole --RoleName "$ALIYUN_ECS_IMAGE_IMPORT_ROLE"
ossutil stat "oss://$ALIYUN_ACORN_IMAGE_BUCKET/$ALIYUN_ACORN_IMAGE_OBJECT" \
  -e "$ALIYUN_ACORN_OSS_ENDPOINT"
```

### 6. Import the custom image

Import with explicit UEFI boot mode. `ImportImage` defaults to BIOS, which does not match this image target.

```sh
aliyun --profile prod ecs ImportImage \
  --RegionId "$ALIYUN_ACORN_REGION" \
  --RoleName "$ALIYUN_ECS_IMAGE_IMPORT_ROLE" \
  --Architecture x86_64 \
  --OSType linux \
  --Platform 'Customized Linux' \
  --BootMode UEFI \
  --ImageName nixos-aliyun-acorn-$(date +%Y%m%d) \
  --Description "NixOS aliyun-acorn custom image $(date +%Y%m%d)" \
  --DetectionStrategy Standard \
  --DiskDeviceMapping.1.OSSBucket "$ALIYUN_ACORN_IMAGE_BUCKET" \
  --DiskDeviceMapping.1.OSSObject "$ALIYUN_ACORN_IMAGE_OBJECT" \
  --DiskDeviceMapping.1.Format qcow2 \
  --Tag.1.Key Project --Tag.1.Value dotfiles \
  --Tag.2.Key Component --Tag.2.Value aliyun-acorn
```

Poll until the image is available:

```sh
aliyun --profile prod ecs DescribeImages \
  --RegionId "$ALIYUN_ACORN_REGION" \
  --ImageName nixos-aliyun-acorn-$(date +%Y%m%d)
```

Record the returned image ID locally for the validation instance:

```sh
export ALIYUN_ACORN_IMAGE_ID=YOUR_IMPORTED_IMAGE_ID
```

### 7. Generate first-boot user data

Generate cloud-init user data locally from a public SSH key. This injects access for `c1` at first boot without committing keys or using passwords.

```sh
export ALIYUN_ACORN_SSH_PUBKEY_PATH=${ALIYUN_ACORN_SSH_PUBKEY_PATH:-$HOME/.ssh/id_ed25519.pub}
export ALIYUN_ACORN_USER_DATA_FILE=${TMPDIR:-/tmp}/aliyun-acorn-user-data.yaml
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
export ALIYUN_ACORN_USER_DATA_B64=$(base64 < "$ALIYUN_ACORN_USER_DATA_FILE" | tr -d '\n')
```

### 8. Preflight and create a validation instance

Set reviewed runtime variables. Restrict SSH to an operator CIDR unless broad access has been explicitly accepted.

```sh
export ALIYUN_ACORN_INSTANCE_TYPE=ecs.u1-c1m2.large
export ALIYUN_ACORN_SECURITY_GROUP_ID=REVIEWED_SECURITY_GROUP_ID
export ALIYUN_ACORN_VSWITCH_ID=REVIEWED_VSWITCH_ID
export ALIYUN_ACORN_AUTO_RELEASE_TIME=YYYY-MM-DDTHH:MM:00Z
```

Run a dry-run first:

```sh
aliyun --profile prod ecs RunInstances \
  --RegionId "$ALIYUN_ACORN_REGION" \
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

Only after reviewing the dry-run result and expected cost, remove `--DryRun true` to create the instance.

### 9. First-boot validation

Use ECS console logs or serial console if SSH does not come up. After SSH is reachable:

```sh
ssh c1@PUBLIC_IP
cloud-init status --long
systemctl status sshd systemd-networkd cloud-init
journalctl -u cloud-init -u cloud-config -u cloud-final --no-pager
networkctl status
df -h /
nixos-version
```

The expected first-boot shape is: UEFI boot succeeds, DHCP configures the primary NIC, cloud-init reaches done, SSH accepts the injected `c1` public key, and `/` grows to the ECS system disk size.

### 10. Cleanup

For temporary validation, clean up in this order:

1. Release the validation ECS instance after recording any needed boot evidence.
2. Delete the custom image if no retained instance or disk depends on it.
3. Delete the staging OSS object.
4. Delete the staging bucket only if it was created solely for image import and is empty.
5. Remove any temporary SSH ingress rule created outside Terraform.

If `aliyun-acorn` should become a durable host, create a follow-up task in `~/Work/aliyun-ops` for Terraform-owned ECS/VPC/security-group state instead of keeping one-off CLI state as the long-term source of truth.

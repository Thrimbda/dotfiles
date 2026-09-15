# Ant

Alibaba Cloud host copied from Acorn's server baseline, with no application services enabled.

- NixOS 26.05, x86_64, UEFI/systemd-boot, ext4 root, DHCP through systemd-networkd.
- User `c1`, Neovim, Git, tmux, zsh and Node.js; SSH keys come from the existing `c1` profile.
- SSH, Fail2ban, vnStat and normal system maintenance are enabled. The host firewall permits TCP 22 only.
- Acorn's ingress, FRP, RustDesk, Auth Mini, ConstX, Cybion, Vaultwarden, bots and tunnel accounts are not imported. No application secrets or specialisations are loaded.
- Password login and root SSH login are disabled. The `c1` operator can use sudo without a password. The shared bootstrap password is overridden with locked password hashes.
- cloud-init preserves the hostname `ant`; NixOS owns user provisioning.

## Build

Build on Axiom, from an isolated copy of this repository:

```sh
nix build path:.#nixosConfigurations.ant.config.system.build.image \
  --out-link ../ant-image
```

The output contains `nixos-ant.qcow2`, an 8 GiB UEFI disk image. It uses the repository's root `flake.lock`; there is no separate image dependency lock. The root filesystem grows to the destination disk size on first boot. Do not build on Acorn or Ant.

## Alibaba Cloud installation

The target is a **Simple Application Server**, not an ECS instance. ECS `ImportImage` cannot supply an image to this product. Its custom images are created from Simple Application Server snapshots.

For the initial installation:

1. Verify the account, instance, disk, architecture and boot mode. Preserve a snapshot of the original disk.
2. Build on Axiom and boot a disposable UEFI VM with 2 GiB RAM and a 40 GiB disk. Check SSH, cloud-init, hostname preservation and filesystem growth.
3. Build a RAM-based installer on Axiom from the pinned NixOS netboot module. Transfer and hash-check its kernel/initrd, then use a one-time GRUB entry to boot it. Verify the target's DMI UUID and disk size, and ensure its disk is unmounted before writing. The upstream kexec transition did not restore connectivity on this instance; its disk remained intact and a cloud reboot recovered the original system.
4. Stream the decompressed raw image to the system disk. Compare the written bytes with the source SHA-256, then relocate the backup GPT to the end of the disk.
5. While the destination disk remains unmounted in the RAM installer, snapshot the pristine disk before its first boot. Create a lightweight custom image from that snapshot; this avoids capturing host SSH private keys or first-boot state.
6. Start Ant and verify the real cloud boot, SSH, DHCP, root growth and absence of application services.

This replaces all existing system-disk data. Direct disk installation preserves the disk ID; the original snapshot is retained for recovery. Do not substitute the cloud `ResetSystem` operation, which has different snapshot rollback limitations. A lightweight server cannot reset itself from its own custom image; the retained image is useful for other compatible lightweight instances.

Cloud access uses the `environments` skill with explicit account `humble-little-c1` and region `cn-shanghai`. Credentials stay in SOPS and are passed only to the calling process.

References: [lightweight vs ECS](https://help.aliyun.com/zh/simple-application-server/product-overview/comparison-between-simple-application-server-and-ecs), [lightweight custom images](https://help.aliyun.com/zh/simple-application-server/user-guide/overview-of-custom-images), [reset limitations](https://help.aliyun.com/zh/simple-application-server/user-guide/reset-a-simple-application-server/).

## Deployment record — 2026-09-15

| Item | Value |
| --- | --- |
| Account selector / region | `humble-little-c1` / `cn-shanghai` |
| Instance / public IP | `3943f1fc74954c79a53036d6f9adc6db` / `106.15.156.143` |
| System disk | `d-uf6ga92ewloi4t6l31iq`, 40 GiB |
| Original-system snapshot | `s-uf6e4vphwx8b4tr5nj02` |
| Pristine NixOS snapshot | `s-uf6azwhdr585z99wws41` |
| Custom image | `nixos-ant-20260915` / `m-uf61yhkxw7q61knq4il8` |
| Source baseline | `9f848e66` plus this `hosts/ant` configuration |
| Build host / retained files | Axiom: `/home/c1/Work/ant-cloud-image-20260915/` |

SSH: `ssh c1@106.15.156.143`.

The QCOW2 SHA-256 is `f5139f50269799ee824209091919bc9c5cfeae63ba562c806c7318191a726064`. The raw image SHA-256 is `ceeaf928163981647cb0be36e3ef1551c9821e7913bdc780bfb36aca0beb32b7`; the first 8 GiB read back from the destination disk matched it before relocating the backup GPT.

Verified on the cloud instance: NixOS `26.05.7813.0dd31db7e6db`, hostname `ant`, UEFI boot, SSH and sudo, root filesystem growth to 40 GiB, `DataSourceAliYunLocal` completion with no cloud-init errors, and no failed systemd units. The custom image is available (`Status=1`).

Alibaba Cloud retains the original `SourceImageName` / `SourceImageVersion` metadata (`Alibaba Cloud Linux` / `3.21.04`) because this installation writes the disk directly. Those fields describe the instance's original image, not the running OS. Use SSH and `nixos-version` to verify the actual system.

The pinned cloud-init package emits an optional `keys-to-console` helper warning. All initialization stages finish successfully; SSH host-key generation and login were verified independently.

A source copy is installed at `/home/c1/dotfiles` on Ant.

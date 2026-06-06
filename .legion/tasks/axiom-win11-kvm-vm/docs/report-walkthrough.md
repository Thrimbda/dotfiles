# Report Walkthrough: Axiom Win11 KVM VM

Mode: implementation

## What Changed
- Added axiom-local libvirt/QEMU system virtualization support in `hosts/axiom/default.nix`.
- Enabled `virtualisation.libvirtd` and `virtualisation.libvirtd.qemu.swtpm` for Windows 11 TPM 2.0 support.
- Enabled `programs.virt-manager` for the `qemu:///system` management UI.
- Added `virt-viewer` and `virtio-win` to system packages for VM console/driver media support.
- Added `c1` to `kvm` and `libvirtd` groups for non-root system libvirt management after activation/session refresh.
- Added Legion task evidence: plan, research, RFC, RFC review, test report, change review, and this walkthrough.

## Why This Shape
- The final RFC chose axiom-local configuration instead of broadening `modules.virt.qemu.enable` because `ramen` already uses that shared module.
- This keeps the blast radius limited to axiom while still preparing the host for Windows 11 KVM/libvirt usage.
- The change intentionally avoids GPU passthrough, VFIO, SPICE USB redirection, and storage changes to the 1.8T NTFS disk.

## Verification Evidence
- `nix eval` confirms for axiom:
  - `virtualisation.libvirtd.enable = true`
  - `virtualisation.libvirtd.qemu.swtpm.enable = true`
  - `programs.virt-manager.enable = true`
  - `c1` extra groups include `kvm` and `libvirtd`
- `nix build --no-link --no-write-lock-file .#nixosConfigurations.axiom.config.system.build.toplevel` passed.
- The built closure includes `libvirt-11.7.0`, `qemu-10.1.2`, `swtpm-0.10.1`, `virt-viewer-11.0`, and `virtio-win-0.1.285-1`.
- `review-change` passed the repository change with an operational blocker.

## Operational Blocker
- `sudo -n true` failed with `sudo: 需要密码`, so this session cannot run `nixos-rebuild test` or `switch`.
- Current libvirt services remain inactive.
- Current `c1` runtime groups do not include `kvm` or `libvirtd` until activation and session refresh.
- Because host activation is blocked, Windows 11 ISO download, VM creation, and guest validation are deferred.

## Continuation
After merge or while testing this worktree, run:

```sh
sudo nixos-rebuild test --flake /home/c1/dotfiles/.worktrees/axiom-win11-kvm-vm#axiom
```

Then start a fresh session and verify:

```sh
id c1
systemctl is-active libvirtd virtlogd virtlockd
virsh -c qemu:///system list --all
```

Once libvirt is active, create the Windows 11 VM with Q35, UEFI/Secure Boot capable firmware, TPM 2.0, VirtIO disk/network, SPICE display, and no PCI host devices.

# RFC: Axiom Win11 KVM VM

> Profile: Standard RFC  
> Status: Draft  
> Owner: OpenCode agent  
> Created: 2026-06-06

## Context
Axiom has the hardware required for Windows 11 virtualization, but the current NixOS dotfiles only expose a minimal QEMU toggle. Windows 11 needs a VM profile that presents UEFI/Secure Boot capability and TPM 2.0. On NixOS 25.11, libvirt's OVMF handling changed: the old `virtualisation.libvirtd.qemu.ovmf` submodule is removed, and libvirt uses QEMU-provided firmware metadata and images.

The requested VM is intentionally not a GPU passthrough VM. It should use a normal virtual display and guest integration so it can be managed safely before any future VFIO work.

## Goals
- Enable libvirt/QEMU, virt-manager, and swtpm on axiom through the dotfiles configuration.
- Let `c1` manage `qemu:///system` with normal libvirt group membership.
- Create a non-GPU-passthrough Windows 11 VM with Q35, UEFI/Secure Boot capable firmware, TPM 2.0, VirtIO storage/network, and SPICE display/clipboard path.
- Verify TPM, Secure Boot, VirtIO drivers, network connectivity, clipboard behavior, and basic responsiveness.
- Record any external blocker with exact continuation steps.

## Non-goals
- No RTX 5090 passthrough, VFIO binding, Looking Glass, or GPU reset work.
- No storage migration or repartitioning of the 1.8T NTFS NVMe.
- No Windows licensing, activation, account, or installer policy bypass.
- No generic VM platform abstraction beyond the Windows 11 VM need.

## Options
### Option A: Expand `modules.virt.qemu` and enable it on axiom
- Pros: Reuses the existing virtualization module, keeps host config declarative, and creates a reusable toggle for future hosts.
- Pros: Centralizes NixOS 25.11-specific libvirt/swtpm/virt-manager behavior in one module.
- Cons: Broadens a module previously limited to plain QEMU package/KVM module setup.
- Cons: `ramen` already enables this module, so broadening the switch would affect another host outside the axiom-specific scope.

### Option B: Put all libvirt configuration directly in `hosts/axiom/default.nix`
- Pros: Smallest local change for this one machine.
- Pros: Avoids changing the meaning of `modules.virt.qemu.enable` for other hosts.
- Cons: Duplicates a capability that already has a module slot and makes future hosts more likely to copy/paste host-local libvirt config.

### Option C: Use temporary `nix shell` commands without changing dotfiles
- Pros: Fastest way to experiment if only a one-off VM were needed.
- Cons: Does not satisfy the persistent host configuration goal; services, group membership, swtpm, and virt-manager connection behavior would not survive rebuilds.

## Decision
Choose Option B.

The task is axiom-specific and must not change behavior for `ramen`, which already uses `modules.virt.qemu.enable`. Keeping the libvirt/virt-manager/swtpm stack in `hosts/axiom/default.nix` satisfies the Windows 11 VM acceptance criteria with the smallest safe blast radius. A later task can redesign `modules.virt.qemu` with explicit sub-options if multiple hosts need the same libvirt profile.

## Scope
- Update `hosts/axiom/default.nix` to enable libvirt, swtpm, virt-manager, useful QEMU/KVM/Windows guest tooling, and libvirt/kvm user groups.
- Leave `modules/virt/qemu.nix` unchanged unless evaluation reveals a narrow bug unrelated to broadening its semantics.
- Use libvirt/virt-manager-compatible VM settings for a Windows 11 VM without PCI host devices.
- Add verification and review artifacts under `.legion/tasks/axiom-win11-kvm-vm/docs/`.

## VM Creation Approach
Prefer a reproducible `virt-install`/libvirt domain creation path over a pure GUI-only path, while keeping the VM fully editable in virt-manager.

Recommended domain shape:
- Machine: Q35.
- Firmware: UEFI/Secure Boot capable loader selected by libvirt from QEMU firmware metadata.
- TPM: emulated TPM 2.0 using swtpm.
- CPU: host passthrough.
- Memory: 12-16 GiB, adjusted if storage or install flow requires a smaller test VM.
- vCPU: 8 initially.
- Disk: qcow2, VirtIO or VirtIO-SCSI, moderate size for root filesystem limits.
- Network: default libvirt NAT with VirtIO model.
- Display/input: SPICE display, tablet input, no PCI GPU passthrough.
- Media: Windows 11 ISO plus VirtIO driver ISO.

If the Windows installer cannot proceed without manual license/account decisions, stop at the exact interactive step and record continuation instructions rather than bypassing policy.

## Verification
- Host config evaluation: `nix eval` or `nixos-rebuild dry` equivalent confirms the axiom configuration evaluates.
- Host activation: `libvirtd` active, `virsh -c qemu:///system` works, and `c1` has the expected groups after session refresh or documented limitation.
- VM definition: `virsh dumpxml` shows no `<hostdev>` GPU passthrough, Q35 machine, TPM 2.0, and virtio disk/network devices.
- Windows guest:
  - `tpm.msc` or PowerShell confirms TPM 2.0.
  - `msinfo32` or PowerShell confirms Secure Boot state/capability.
  - Device Manager/driver install confirms VirtIO storage/network and guest tools.
  - Network can reach the internet or at least the host/default gateway.
  - Clipboard works through SPICE guest tools.
  - Basic performance is acceptable for desktop use, with CPU/RAM/disk settings recorded.

## Rollback
- Dotfiles rollback: revert the commit or remove the axiom-local libvirt/virt-manager/swtpm config and rebuild.
- Host service rollback: stop/disable libvirt through the reverted NixOS generation.
- VM rollback: shut down and undefine the test VM if it was created; remove its qcow2 only after confirming no user data needs preservation.
- Download rollback: remove downloaded ISO/driver media only if stored as task artifacts and no longer needed.

## Operational Boundaries
- Do not place long-lived VM disk images on the 1.8T NTFS disk in this task.
- Do not create a GPU passthrough device assignment.
- Do not continue through Windows setup by bypassing licensing/account prompts.
- If system activation, ISO download, or Windows GUI setup is blocked, record the blocker as task evidence and leave exact commands/state for continuation.

## Open Questions
- Can the official Windows 11 ISO be downloaded non-interactively in this environment?
- Can the current session run `sudo nixos-rebuild switch --flake .#axiom`?
- Can the Windows installer be completed through the available display/remote session without manual credentials from the user?

## References
- Plan: `.legion/tasks/axiom-win11-kvm-vm/plan.md`
- Research: `.legion/tasks/axiom-win11-kvm-vm/docs/research.md`
- Relevant files:
  - `modules/virt/qemu.nix`
  - `hosts/axiom/default.nix`

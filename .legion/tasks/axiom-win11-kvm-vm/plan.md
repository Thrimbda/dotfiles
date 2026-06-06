# Axiom Win11 KVM VM

## Name
Axiom Win11 KVM VM

## Task ID
`axiom-win11-kvm-vm`

## Goal
Enable the KVM/QEMU/libvirt/virt-manager stack on `axiom`, create a non-GPU-passthrough Windows 11 VM, and verify the VM has the required Windows 11 virtualization features and usable guest integration.

## Problem
`axiom` has suitable hardware for Windows 11 virtualization, including AMD-V, KVM, IOMMU, enough CPU capacity, and enough memory. The current NixOS configuration does not enable libvirt, virt-manager, or swtpm, so Windows 11 cannot yet be created and managed through virt-manager. Windows 11 also requires UEFI/Secure Boot and TPM 2.0, which must be exposed correctly by libvirt/QEMU.

## Acceptance
- Axiom's NixOS configuration enables libvirt/QEMU management, virt-manager, and swtpm for TPM 2.0 backed Windows 11 VMs.
- User `c1` can manage the system libvirt connection without ad-hoc root-only VM management.
- A non-GPU-passthrough Windows 11 VM is created or the exact external blocker is documented with reproducible continuation steps.
- The VM uses UEFI/Secure Boot capable firmware, emulated TPM 2.0, VirtIO storage/network where practical, and no PCI GPU passthrough.
- Windows guest validation covers TPM, Secure Boot, VirtIO drivers, network connectivity, clipboard integration, and basic performance responsiveness.
- Verification evidence is recorded in Legion task docs, including any command output or screenshots/log notes available from this environment.
- The implementation is delivered through the required Legion workflow stages and repository lifecycle.

## Assumptions
- The Windows 11 ISO may be downloaded during this task from an official or otherwise trustworthy source if a local ISO is not already present.
- Full Windows setup may require interactive input, a license decision, Microsoft account handling, or network access that cannot be bypassed silently.
- NixOS system activation may require `sudo` privileges and a session/group refresh before `c1` can use libvirt without re-login.
- The first VM can live on the current root filesystem for a bounded test, but long-term storage may need a separate libvirt storage pool because `/` has limited free space.
- The task is for a normal desktop VM, not for gaming/CUDA/3D performance.

## Constraints
- Follow Legion workflow before implementation and close with verification, review, walkthrough, and wiki writeback.
- Do not use RTX 5090 or any other PCI GPU passthrough in this task.
- Do not repartition, format, or write to the 1.8T NTFS disk without a separate explicit decision.
- Do not bypass Windows licensing, activation, account, or installer policy prompts.
- Keep changes minimal and aligned with the existing NixOS module structure.

## Risks
- Official Windows ISO download may be gated by a dynamic web flow, region behavior, or manual selection.
- Windows installation and validation may require GUI interaction that cannot be fully automated from the agent session.
- Running a NixOS rebuild may need credentials or may affect active virtualization/networking services.
- Root filesystem free space is tight for a comfortable Windows 11 disk image plus ISO and driver media.
- Clipboard and performance validation depend on SPICE/VirtIO guest tools being installed inside Windows.

## Scope
- Update the existing `modules.virt.qemu` path or host config so `axiom` enables libvirt, virt-manager, swtpm, and useful Windows VM tooling.
- Apply or prepare the system activation needed for the new virtualization stack when possible.
- Download or locate Windows 11 ISO and VirtIO driver media when possible.
- Create a non-GPU-passthrough Windows 11 VM using libvirt/virt-manager-compatible settings.
- Validate and record TPM, Secure Boot, VirtIO, network, clipboard, and basic performance behavior.

## Non-Goals
- No GPU passthrough, VFIO binding, Looking Glass, or RTX 5090 reset-bug work.
- No conversion of the second NVMe NTFS disk into VM storage.
- No Windows license bypass, forced offline-account bypass, or activation workaround.
- No long-term storage architecture beyond the minimum needed for this VM task.
- No generalized VM management framework beyond what this Windows 11 VM requires.

## Design Summary
Keep the shared `modules.virt.qemu` semantics unchanged and add the libvirt/virt-manager/swtpm Windows 11 VM stack directly to `hosts/axiom/default.nix`. On NixOS 25.11, rely on libvirt's QEMU-provided OVMF firmware paths instead of the removed `virtualisation.libvirtd.qemu.ovmf` option, enable `qemu.swtpm` for Windows 11 TPM 2.0, and expose virt-manager plus useful guest media/tools. Create the Windows 11 VM as a normal Q35/UEFI/TPM/VirtIO/SPICE VM without PCI passthrough. Treat ISO download, system activation, and Windows GUI setup as operational steps that must either complete or leave clear continuation evidence.

## Phases
1. Materialize the Legion task contract.
2. Run design gate for the NixOS/libvirt and VM-creation approach because this touches host services and external installer flow.
3. Implement the minimal dotfiles changes in the required worktree/PR envelope.
4. Activate or prepare the host virtualization stack and create the Windows 11 VM when operational permissions allow.
5. Verify TPM, Secure Boot, VirtIO, network, clipboard, and basic performance or document precise blockers.
6. Review the change for scope and safety.
7. Produce walkthrough evidence and update the Legion wiki.

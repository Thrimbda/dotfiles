# Research Notes: Axiom Win11 KVM VM

## 1. Problem Restatement
- Axiom can run KVM guests, but its NixOS configuration has not enabled libvirt, virt-manager, or swtpm.
- Windows 11 VM creation requires UEFI/Secure Boot capable firmware and TPM 2.0 in addition to normal CPU, memory, storage, and graphics requirements.
- The requested VM must be a normal desktop VM without GPU passthrough.

## 2. Relevant Code / Entry Points
- `modules/virt/qemu.nix` currently exposes `modules.virt.qemu.enable` but only installs `qemu` and loads the CPU-specific KVM module.
- `hosts/ramen/default.nix` already enables `modules.virt.qemu.enable`, so changing that switch to mean full libvirt/virt-manager setup would affect another host outside this task.
- `hosts/axiom/default.nix` does not enable `modules.virt.qemu.enable`; current workstation modules include desktop, dev, editors, shell, services, and hardware profiles.
- NixOS 25.11 `virtualisation.libvirtd` provides the system libvirt daemon and includes QEMU packages and OVMF firmware wiring from QEMU by default.
- NixOS 25.11 `programs.virt-manager.enable` installs virt-manager and configures the default `qemu:///system` connection.

## 3. Existing Conventions
- Host-level feature toggles live under `modules = { ... }` in `hosts/<host>/default.nix`.
- Reusable capability modules live under `modules/`, with `modules.virt.qemu` already present for QEMU-related Linux virtualization.
- Previous Legion tasks keep task contracts and delivery evidence under `.legion/tasks/<task-id>/`.

## 4. Hardware / Runtime Evidence
- Host: `axiom`, NixOS 25.11, Linux 6.12.68, x86_64.
- CPU: AMD Ryzen 9 9950X, 16 cores / 32 threads, AMD-V exposed as `svm` and `Virtualization: AMD-V`.
- Memory: about 46 GiB total, with more than 30 GiB available during research.
- KVM: `/dev/kvm` exists and is accessible; `kvm_amd` and `kvm` are loaded.
- `virt-host-validate qemu`: hardware virtualization, `/dev/kvm`, `/dev/vhost-net`, `/dev/net/tun`, device assignment IOMMU support, and kernel IOMMU are PASS.
- Storage: `/` has about 86-87 GiB free, which is enough for a bounded test but tight for a comfortable long-lived Windows 11 VM.
- Secondary NVMe: 1.8T NTFS partition exists but is not in scope for formatting or VM storage conversion.

## 5. Constraints & Non-goals
- Do not configure PCI GPU passthrough or VFIO binding.
- Do not write to or reformat the second NVMe NTFS disk.
- Do not bypass Windows licensing, activation, Microsoft account, or installer policy prompts.
- Keep NixOS changes minimal and reusable.

## 6. Risks & Pitfalls
- NixOS 25.11 removed `virtualisation.libvirtd.qemu.ovmf`; adding old OVMF config would fail evaluation. Libvirt now uses QEMU-provided firmware images under `/run/libvirt/nix-ovmf`.
- Shared module drift is a scope risk: changing `modules.virt.qemu.enable` would affect `ramen`, so this task should keep the Windows 11 VM stack axiom-local.
- `c1` needs `libvirtd` group membership and possibly a new login/session before non-root libvirt management works.
- Official Windows ISO download may require dynamic web form selections, region-specific URLs, or manual browser interaction.
- Windows guest validation for clipboard and VirtIO depends on guest tools installed inside Windows.
- Creating a large qcow2 on `/` may exhaust space; keep the first disk moderate or stop for a storage decision.

## 7. Unknowns
- [ ] Whether official Windows ISO download can complete non-interactively from this environment.
- [ ] Whether `sudo nixos-rebuild switch --flake .#axiom` can run without a password prompt.
- [ ] Whether Windows setup can be completed from the available GUI/remote session without user credentials or manual choices.

## 8. References
- Plan: `.legion/tasks/axiom-win11-kvm-vm/plan.md`
- Code:
  - `modules/virt/qemu.nix`
  - `hosts/axiom/default.nix`
- NixOS modules inspected:
  - `nixos/modules/virtualisation/libvirtd.nix`
  - `nixos/modules/programs/virt-manager.nix`

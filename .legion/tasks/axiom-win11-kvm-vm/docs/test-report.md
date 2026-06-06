# Test Report: Axiom Win11 KVM VM

## Summary
- Result: BLOCKED for host activation, VM creation, and Windows guest validation.
- Implemented NixOS configuration evaluates and builds successfully.
- Operational activation is blocked because this session does not have non-interactive `sudo`.
- Current host libvirt services are inactive, so `qemu:///system` VM creation cannot proceed yet.

## Why These Checks
- `nix eval` directly proves the changed NixOS options resolve to the intended values without activating the system.
- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --no-link` is the strongest non-destructive validation that the full axiom system closure can be built with the new libvirt/QEMU/swtpm/virt-manager configuration.
- `sudo -n true`, `systemctl is-active ...`, and `id c1` determine whether the workflow can proceed from declarative config validation to actual host activation and VM creation.

## Commands Run
### Config option evaluation
```sh
nix eval --json --no-write-lock-file .#nixosConfigurations.axiom.config.virtualisation.libvirtd.enable
nix eval --json --no-write-lock-file .#nixosConfigurations.axiom.config.virtualisation.libvirtd.qemu.swtpm.enable
nix eval --json --no-write-lock-file .#nixosConfigurations.axiom.config.programs.virt-manager.enable
nix eval --json --no-write-lock-file .#nixosConfigurations.axiom.config.users.users.c1.extraGroups
nix eval --json --no-write-lock-file .#nixosConfigurations.axiom.config.environment.systemPackages
```

Evidence:
- `virtualisation.libvirtd.enable`: `true`
- `virtualisation.libvirtd.qemu.swtpm.enable`: `true`
- `programs.virt-manager.enable`: `true`
- `users.users.c1.extraGroups`: includes `kvm` and `libvirtd`
- `environment.systemPackages`: evaluates and includes `virt-viewer-11.0` and `virtio-win-0.1.285-1`

### Full system closure build
```sh
nix build --no-link --no-write-lock-file .#nixosConfigurations.axiom.config.system.build.toplevel
```

Result: PASS.

Evidence:
- Build completed successfully.
- The closure included the expected virtualization stack, including `libvirt-11.7.0`, `qemu-10.1.2`, `swtpm-0.10.1`, `virt-viewer-11.0`, and `virtio-win-0.1.285-1`.
- Existing warnings were unrelated to this change: specialArgs `pkgs` warning, deprecated `mesa.drivers`, renamed `hardware.pulseaudio`, and renamed `system` package attribute warning.

### Operational activation readiness
```sh
sudo -n true
systemctl is-active libvirtd virtqemud virtlogd virtlockd
id c1
```

Result: BLOCKED.

Evidence:
- `sudo -n true` failed with `sudo: 需要密码`.
- `systemctl is-active libvirtd virtqemud virtlogd virtlockd` returned all services as `inactive`.
- Runtime `id c1` showed current groups as `users,wheel,audio,docker,ydotool,gamemode`; the current login session has not yet gained `kvm` or `libvirtd`.

## Skipped / Blocked Validation
- `sudo nixos-rebuild test --flake .#axiom`: skipped because non-interactive sudo is unavailable.
- `libvirtd` activation checks: blocked until the NixOS config is activated.
- Windows 11 ISO download: skipped because the host cannot create the system libvirt VM until activation succeeds; downloading multi-GB media before activation would not unblock validation.
- VM creation: blocked because `libvirtd` is inactive.
- Guest validation for TPM 2.0, Secure Boot, VirtIO, network, clipboard, and performance: blocked because the VM could not be created.

## Continuation Steps
After the PR/config is accepted or while testing the worktree locally, run:

```sh
sudo nixos-rebuild test --flake /home/c1/dotfiles/.worktrees/axiom-win11-kvm-vm#axiom
```

Then refresh the user session or use a new login so `c1` gains `kvm` and `libvirtd`. Verify:

```sh
id c1
systemctl is-active libvirtd virtlogd virtlockd
virsh -c qemu:///system list --all
```

Once libvirt is active, proceed with Windows 11 ISO/VirtIO media acquisition and create the non-GPU-passthrough VM using Q35, UEFI/Secure Boot capable firmware, TPM 2.0, VirtIO disk/network, and SPICE display.

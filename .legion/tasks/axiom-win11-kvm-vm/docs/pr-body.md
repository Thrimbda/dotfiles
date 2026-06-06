## Summary
- Enable axiom-local libvirt/QEMU, swtpm, and virt-manager for Windows 11 KVM VM support.
- Add VirtIO driver media and virt-viewer tooling, plus `kvm`/`libvirtd` groups for `c1`.
- Keep shared `modules.virt.qemu` behavior unchanged to avoid affecting `ramen`.

## Verification
- PASS: `nix eval` confirms libvirt, swtpm, and virt-manager are enabled for axiom.
- PASS: `nix eval` confirms `c1` includes `kvm` and `libvirtd` after activation.
- PASS: `nix build --no-link --no-write-lock-file .#nixosConfigurations.axiom.config.system.build.toplevel`.
- BLOCKED: host activation and Windows VM creation require sudo; this session has `sudo: 需要密码`.

## Notes
- No GPU passthrough, VFIO, SPICE USB redirection, or NTFS disk/storage changes are included.
- Follow-up operational step: activate the config, refresh the user session, then create and validate the Windows 11 VM.

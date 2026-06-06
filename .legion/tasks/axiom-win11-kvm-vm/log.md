# Log: Axiom Win11 KVM VM

## 2026-06-06
- Entered Legion workflow because the request is a non-trivial multi-step engineering task in a Legion-managed repository.
- No explicit task id/path was supplied, so the workflow entered `brainstorm` and created task id `axiom-win11-kvm-vm`.
- User selected `allow download ISO` for the Windows 11 installation media boundary.
- Contract scope explicitly excludes GPU passthrough and modifying the second NVMe NTFS disk.
- Opened git-worktree-pr envelope from `origin/master` into `.worktrees/axiom-win11-kvm-vm` on branch `legion/axiom-win11-kvm-vm-win11-kvm`.
- Wrote standard RFC and research notes.
- Initial RFC review failed because broadening `modules.virt.qemu.enable` would affect existing `ramen` usage outside the axiom-specific scope.
- Revised RFC to use axiom-local libvirt/virt-manager/swtpm config and leave shared `modules.virt.qemu` semantics unchanged.
- Final RFC review passed.
- Added axiom-local NixOS config for libvirt, swtpm, virt-manager, `kvm`/`libvirtd` groups, `virt-viewer`, and `virtio-win`.
- Minimal implementation checks passed with `nix eval`: libvirt, swtpm, and virt-manager are enabled; `c1` includes `kvm` and `libvirtd`; system packages evaluate with `virt-viewer` and `virtio-win`.
- Full axiom system closure build passed with `nix build --no-link --no-write-lock-file .#nixosConfigurations.axiom.config.system.build.toplevel`.
- Operational activation is blocked: `sudo -n true` requires a password, libvirt services are currently inactive, and the current `c1` session does not yet include `kvm`/`libvirtd`.
- Review-change passed the repository change with an operational blocker: code/config is ready for PR, but host activation and VM creation require sudo/session refresh.
- Produced implementation-mode report walkthrough and PR body.
- Wrote Legion wiki task summary, current decision entry, maintenance follow-up, and wiki log entries.
- Created PR: https://github.com/Thrimbda/dotfiles/pull/77

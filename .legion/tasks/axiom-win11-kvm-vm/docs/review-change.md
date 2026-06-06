# Review Change: Axiom Win11 KVM VM

## Decision
PASS with operational blocker

## Blocking Findings
None for the repository change.

## Scope Review
- In scope: `hosts/axiom/default.nix` adds axiom-local libvirt, swtpm, virt-manager, VirtIO media, virt-viewer, and `c1` group membership for `kvm`/`libvirtd`.
- In scope: Legion task artifacts record the design gate, validation, and operational blocker.
- Not changed: `modules/virt/qemu.nix`, other hosts, GPU/VFIO settings, storage partitioning, and the 1.8T NTFS disk.

## Correctness Review
- The implementation matches the final RFC decision to keep the shared QEMU module unchanged and configure only axiom.
- Nix evaluation confirms `virtualisation.libvirtd.enable`, `virtualisation.libvirtd.qemu.swtpm.enable`, and `programs.virt-manager.enable` are all `true` for axiom.
- Nix evaluation confirms `c1` will gain `kvm` and `libvirtd` after activation/session refresh.
- Full system closure build passed, including libvirt, QEMU, swtpm, virt-viewer, and virtio-win.

## Security Lens
Security trigger applied because this change modifies local virtualization permissions.

- `libvirtd` membership lets `c1` manage system libvirt VMs. This is intended by the task acceptance and consistent with `c1` already being the workstation owner and a `wheel` user.
- `kvm` membership gives direct KVM device access. This is expected for non-root VM operation and does not extend beyond the local workstation owner account.
- SPICE USB redirection was not enabled, avoiding a broader USB device access surface.
- No secrets, tokens, network trust boundary, or remote auth policy was changed.

## Operational Blocker
- Host activation and VM creation are blocked by missing non-interactive sudo in this session.
- This blocker does not require code changes. The continuation path is documented in `docs/test-report.md`.

## Residual Risks
- After activation, the current login session may need to be refreshed before `c1` gains `kvm`/`libvirtd`.
- Windows 11 ISO download and Windows setup may still require manual browser or installer interaction.
- Root filesystem space remains tight for a long-lived Windows VM; this PR only prepares the host stack.

# Review RFC: Axiom Win11 KVM VM

## Initial Decision
FAIL

## Blocking Finding
- `modules.virt.qemu.enable` is already enabled by `hosts/ramen/default.nix`. The draft RFC chose to broaden that shared module into a full libvirt/virt-manager/swtpm desktop virtualization stack. That would affect `ramen` even though the task contract is axiom-specific. This makes the proposed design scope ambiguous and unsafe to implement without either a separate compatibility decision for `ramen` or a more local axiom-only design.

## Required Correction
- Revise the design to keep existing `modules.virt.qemu.enable` semantics unchanged for other hosts, or add explicit opt-in sub-options before broadening behavior. For this task, prefer an axiom-local libvirt/virt-manager/swtpm configuration because it satisfies the acceptance criteria without changing other hosts.

## Final Decision
PASS

## Final Notes
- The RFC now chooses the axiom-local configuration path and explicitly leaves `modules/virt/qemu.nix` unchanged. The previous blast-radius issue is resolved.
- Verification and rollback are concrete enough for implementation: evaluate the axiom config, activate if possible, inspect libvirt service/domain state, and revert the axiom-local config if needed.

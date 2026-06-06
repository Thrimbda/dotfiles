# axiom-win11-kvm-vm

## Metadata

- `task-id`: `axiom-win11-kvm-vm`
- `status`: `active-blocked`
- `risk`: `medium`
- `schema-version`: `legion-workflow`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- Axiom now has a repository change that declaratively enables the host-side Windows 11 KVM/libvirt stack: libvirt, swtpm, virt-manager, VirtIO media, virt-viewer, and `c1` membership in `kvm`/`libvirtd`.
- The final design keeps this stack axiom-local and leaves shared `modules.virt.qemu` behavior unchanged because `ramen` already uses that module.
- Static validation passed: focused `nix eval` checks and the full axiom system closure build succeeded.
- Runtime activation, Windows ISO download, VM creation, and guest validation remain blocked until a sudo-authorized activation and user session refresh are performed.

## Reusable Decisions

- Do not broaden `modules.virt.qemu.enable` into full libvirt/virt-manager setup without explicit sub-options or a separate cross-host task; existing hosts may rely on the narrower QEMU-only semantics.
- For Axiom's first Windows 11 VM, use a normal libvirt system VM with Q35, UEFI/Secure Boot capable firmware, swtpm TPM 2.0, VirtIO storage/network, SPICE display, and no PCI GPU passthrough.
- Treat GPU passthrough, 1.8T NTFS disk conversion, SPICE USB redirection, Windows licensing/account bypass, and long-term VM storage architecture as separate scoped tasks.

## Related Raw Sources

- `plan`: `.legion/tasks/axiom-win11-kvm-vm/plan.md`
- `log`: `.legion/tasks/axiom-win11-kvm-vm/log.md`
- `tasks`: `.legion/tasks/axiom-win11-kvm-vm/tasks.md`
- `research`: `.legion/tasks/axiom-win11-kvm-vm/docs/research.md`
- `rfc`: `.legion/tasks/axiom-win11-kvm-vm/docs/rfc.md`
- `review-rfc`: `.legion/tasks/axiom-win11-kvm-vm/docs/review-rfc.md`
- `test-report`: `.legion/tasks/axiom-win11-kvm-vm/docs/test-report.md`
- `review-change`: `.legion/tasks/axiom-win11-kvm-vm/docs/review-change.md`
- `report`: `.legion/tasks/axiom-win11-kvm-vm/docs/report-walkthrough.md`

## Notes

- This summary is current for the repository change, not proof that Windows 11 has already been installed.
- Continue from the test report once sudo activation is available.

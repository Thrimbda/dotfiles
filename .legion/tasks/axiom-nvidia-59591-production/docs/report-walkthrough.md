# Delivery Walkthrough: Axiom NVIDIA 595.99.02 Production Driver

**Mode:** implementation

## Outcome

Axiom now runs NVIDIA production driver 595.99.02 for its RTX 5090. The
override is local to Axiom, so the shared NVIDIA profile and all other hosts
retain their existing driver selection.

## Implementation

- `hosts/axiom/default.nix` imports the Axiom-specific driver module.
- `hosts/axiom/modules/nvidia-driver.nix` uses the configured kernel package
  set's `mkDriver` helper and upstream production hashes for 595.99.02.
- `lib.mkForce` intentionally overrides the shared profile's beta package only
  for Axiom.

## Evidence

- Design and rollback: [`rfc.md`](rfc.md)
- Design review: [`review-rfc.md`](review-rfc.md), PASS
- Runtime verification: [`test-report.md`](test-report.md), PASS
- Delivery review: [`review-change.md`](review-change.md), PASS

The full Axiom closure built successfully. After the user performed the
privileged switch and reboot, `nvidia-smi` reported 595.99.02, `lspci` reported
the `nvidia` kernel driver, `/run/current-system` matched the new closure,
`systemctl` reported `running`, and Hyprland was running.

## Rollback

Select the previous NixOS generation from the boot loader if the new driver
fails to boot. For a persistent rollback, revert the Axiom-only module and its
import, redeploy, and reboot; the shared beta package selection resumes.

## Remaining Optional Checks

CUDA compilation and suspend/resume were not forced because they would disrupt
the active workstation session. They can be exercised during a maintenance
window if additional runtime assurance is required.

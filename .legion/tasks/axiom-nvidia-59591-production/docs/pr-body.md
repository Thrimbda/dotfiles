## Summary

- Pin NVIDIA production driver 595.99.02 for Axiom's RTX 5090.
- Keep the override tied to Axiom's configured kernel package set.
- Leave the shared NVIDIA profile and all other hosts unchanged.

## Verification

- `nixos-rebuild build --flake .#axiom --no-link -L` completed successfully.
- After switch and reboot, `nvidia-smi` reports 595.99.02.
- The RTX 5090 uses the `nvidia` kernel driver; the active system generation,
  system health, and Hyprland session were verified.

## Rollback

Boot the previous NixOS generation, or revert the Axiom-only module and import,
then redeploy and reboot.

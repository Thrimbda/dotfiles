## Summary

- migrate Axiom's deprecated NixOS, Home Manager, and package references to supported forms
- remove the unused root `x86_64-darwin` platform and make the GTK4/Info-documentation policy explicit
- resolve system-path collisions through explicit SSH, Steam, Gamescope, NVIDIA, and X11 package ownership
- replace the Bluetooth VM fixture's deprecated wake hook with explicit boot and resume services

## Testing

- targeted `vm-test-run-bluetooth-predeploy-integration` build from Axiom `system.extraDependencies`
- rendered Axiom, Atlas, Azar, Darwin-platform, and host-metadata assertions
- `nixos-rebuild build --flake .#axiom --show-trace -L`
- `git diff --check`

## Notes

- No deployment, activation, Acorn build, or live suspend/resume was performed.
- `docs/review-change.md` records PASS with no blocking findings.

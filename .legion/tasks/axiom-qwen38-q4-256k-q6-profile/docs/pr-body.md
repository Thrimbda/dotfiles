## Summary

- Make Q4_K_M the default full-GPU Qwen profile at 262144 tokens with Q8 K/V cache.
- Retain Q6_K as the full-GPU 131072-token high-precision profile with Q4 K/V cache.
- Remove all Q5 configuration and model-control paths.

## Static Validation

- `nix-instantiate --parse hosts/axiom/modules/qwen.nix >/dev/null`
- `nix build --no-link .#nixosConfigurations.axiom.config.system.build.toplevel`
- CPU-only MTP load of `RVN-Q4_K_M-mtp.gguf`
- Generated launcher inspection confirms only Q4/Q6 targets, each with `--n-gpu-layers all`.

## Runtime Migration Required

The active deployed link currently points to Q5, which the new launcher intentionally does not support. Before deploying this branch, use the currently deployed control command to select Q4, then switch the generation from this worktree:

```bash
qwen-model q4
sudo nixos-rebuild switch --flake .#axiom
```

Q5 must remain on disk until Q4 256K and Q6 128K have both passed health/API/GPU validation. Full evidence: `.legion/tasks/axiom-qwen38-q4-256k-q6-profile/docs/test-report.md`.

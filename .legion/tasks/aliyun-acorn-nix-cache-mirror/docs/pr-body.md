## Summary

- Prefer domestic Nix/NixOS binary cache mirrors for `aliyun-acorn`: TUNA, USTC, then SJTU.
- Keep existing Cachix substituters and `https://cache.nixos.org/` fallback, with the official `cache.nixos.org` trusted public key preserved by the final NixOS config.
- Open NixOS firewall TCP port `2222` for `aliyun-acorn` only.
- Refresh Legion evidence for the updated scope and validation target.

## Verification

- `nix eval --option eval-cache false '.#nixosConfigurations.aliyun-acorn.config.nix.settings.substituters' --json`
- `nix eval --option eval-cache false '.#nixosConfigurations.aliyun-acorn.config.nix.settings.trusted-public-keys' --json`
- `nix eval --option eval-cache false '.#nixosConfigurations.aliyun-acorn.config.networking.firewall.allowedTCPPorts' --json`
- `nix eval --option eval-cache false './hosts/aliyun-acorn/image#aliyun-image.drvPath'`

## Legion Evidence

- Plan: `.legion/tasks/aliyun-acorn-nix-cache-mirror/plan.md`
- Design-lite: `.legion/tasks/aliyun-acorn-nix-cache-mirror/docs/rfc.md`
- Test report: `.legion/tasks/aliyun-acorn-nix-cache-mirror/docs/test-report.md`
- Review: `.legion/tasks/aliyun-acorn-nix-cache-mirror/docs/review-change.md`
- Walkthrough: `.legion/tasks/aliyun-acorn-nix-cache-mirror/docs/report-walkthrough.md`

## Notes

- This does not change `flake.nix` inputs or GitHub fetch behavior.
- This does not change other hosts, Darwin config, or global cache policy.
- This does not add new trusted public keys.
- This only opens TCP 2222 in the NixOS firewall; Aliyun security group and service-level policy are out of scope.

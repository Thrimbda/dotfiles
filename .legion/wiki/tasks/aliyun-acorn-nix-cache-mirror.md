# aliyun-acorn-nix-cache-mirror

## Metadata

- `task-id`: `aliyun-acorn-nix-cache-mirror`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `2026-06-29`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- `aliyun-acorn` now has host-level domestic Nix binary cache mirror preference: TUNA, USTC, then SJTU.
- The final substituter order is TUNA, USTC, SJTU, nix-community Cachix, Hyprland Cachix, then official `cache.nixos.org` fallback.
- The final trusted public key list still includes official `cache.nixos.org` and the existing Cachix keys; no new trusted public key was added.
- `aliyun-acorn` NixOS firewall now allows TCP `2222`.
- The change intentionally does not alter `flake.nix` inputs, GitHub flake fetch behavior, other hosts, Darwin configuration, Aliyun security groups, or the service/SSH listener behind TCP 2222.
- Validation proved the final substituter list, trusted keys, firewall TCP ports, and `./hosts/aliyun-acorn/image#aliyun-image.drvPath` evaluation.

## Reusable Decisions

- For host-specific domestic cache acceleration, prefer `lib.mkBefore` at the host level so existing global Cachix and official fallback remain intact.
- When relying on official Nix cache mirrors, verify the final evaluated config still includes `cache.nixos.org` fallback and trusted public key.
- Treat nixpkgs/GitHub input mirroring as a separate task from binary cache substituter selection.
- For one-off machine usage, pass `--option substituters "<mirror-1> <mirror-2> https://cache.nixos.org/"` to the specific Nix command instead of landing config.
- Treat NixOS firewall port opening as separate from cloud security-group policy and service listener configuration unless the task contract explicitly joins them.

## Related Raw Sources

- `plan`: `.legion/tasks/aliyun-acorn-nix-cache-mirror/plan.md`
- `log`: `.legion/tasks/aliyun-acorn-nix-cache-mirror/log.md`
- `tasks`: `.legion/tasks/aliyun-acorn-nix-cache-mirror/tasks.md`
- `rfc`: `.legion/tasks/aliyun-acorn-nix-cache-mirror/docs/rfc.md`
- `test-report`: `.legion/tasks/aliyun-acorn-nix-cache-mirror/docs/test-report.md`
- `review`: `.legion/tasks/aliyun-acorn-nix-cache-mirror/docs/review-change.md`
- `report`: `.legion/tasks/aliyun-acorn-nix-cache-mirror/docs/report-walkthrough.md`

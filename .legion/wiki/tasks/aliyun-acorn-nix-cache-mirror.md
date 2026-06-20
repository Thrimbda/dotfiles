# aliyun-acorn-nix-cache-mirror

## Metadata

- `task-id`: `aliyun-acorn-nix-cache-mirror`
- `status`: `active`
- `risk`: `low`
- `schema-version`: `2026-06-20`
- `historical`: `false`
- `supersedes`: `(none)`
- `superseded-by`: `(none)`

## Outcome Summary

- `aliyun-acorn` now has a host-level TUNA Nix binary cache mirror preference.
- The final substituter order is TUNA, nix-community Cachix, Hyprland Cachix, then official `cache.nixos.org` fallback.
- The change intentionally does not alter `flake.nix` inputs, GitHub flake fetch behavior, other hosts, or trusted public keys.
- Validation proved the final substituter list and `aliyun-acorn` toplevel derivation evaluation.

## Reusable Decisions

- For host-specific domestic cache acceleration, prefer `lib.mkBefore` at the host level so existing global Cachix and official fallback remain intact.
- Treat nixpkgs/GitHub input mirroring as a separate task from binary cache substituter selection.
- For one-off machine usage, pass `--option substituters "<mirror> https://cache.nixos.org/"` to the specific Nix command instead of landing config.

## Related Raw Sources

- `plan`: `.legion/tasks/aliyun-acorn-nix-cache-mirror/plan.md`
- `log`: `.legion/tasks/aliyun-acorn-nix-cache-mirror/log.md`
- `tasks`: `.legion/tasks/aliyun-acorn-nix-cache-mirror/tasks.md`
- `rfc`: `.legion/tasks/aliyun-acorn-nix-cache-mirror/docs/rfc.md`
- `test-report`: `.legion/tasks/aliyun-acorn-nix-cache-mirror/docs/test-report.md`
- `review`: `.legion/tasks/aliyun-acorn-nix-cache-mirror/docs/review-change.md`
- `report`: `.legion/tasks/aliyun-acorn-nix-cache-mirror/docs/report-walkthrough.md`

## Summary

- Delete the old active `hosts/acorn` profile and promote the former `hosts/aliyun-acorn` profile to `hosts/acorn`.
- Rename the active Nix host identity to `acorn`, including hostName, image flake target, image base name, runbook paths/names, and Axiom frp/autossh references.
- Preserve encrypted age secret contents and public key material; only paths/local variable names move with the host profile.

## Validation

- `nix eval --json --no-write-lock-file --apply 'configs: { acorn = builtins.hasAttr "acorn" configs; aliyunAcorn = builtins.hasAttr "aliyun-acorn" configs; }' .#nixosConfigurations`
- `nix eval --raw --no-write-lock-file .#nixosConfigurations.acorn.config.networking.hostName`
- `nix eval --raw --no-write-lock-file './hosts/acorn/image#aliyun-image.system'`
- `nix build --dry-run --no-write-lock-file './hosts/acorn/image#aliyun-image'`
- `git diff --check`
- Stale active reference search over `hosts/**/*.nix` and `hosts/**/*.md`

## Legion Evidence

- Plan: `.legion/tasks/acorn-aliyun-host-rename/plan.md`
- RFC: `.legion/tasks/acorn-aliyun-host-rename/docs/rfc.md`
- RFC review: `.legion/tasks/acorn-aliyun-host-rename/docs/review-rfc.md`
- Test report: `.legion/tasks/acorn-aliyun-host-rename/docs/test-report.md`
- Change review: `.legion/tasks/acorn-aliyun-host-rename/docs/review-change.md`
- Walkthrough: `.legion/tasks/acorn-aliyun-host-rename/docs/report-walkthrough.md`

## Notes

- No compatibility alias for `nixosConfigurations.aliyun-acorn` is kept intentionally.
- No remote deploy, DNS/Terraform/Aliyun API operation, secret rotation, or live service validation is included in this PR.

## Summary

- Install the Feishu desktop client on `axiom` by adding `feishu` to the host's managed `user.packages`.
- Keep scope limited to declarative package installation; no account, proxy, autostart, or runtime data is configured.
- Add Legion task evidence for verification, review, and walkthrough.

## Verification

- `nix eval --json ".#nixosConfigurations.axiom.config.user.packages" --apply 'pkgs: builtins.map (p: p.pname or p.name or "") pkgs'`
- `nix eval --raw ".#nixosConfigurations.axiom.config.system.build.toplevel.drvPath"`

## Evidence

- Test report: `.legion/tasks/axiom-feishu-client/docs/test-report.md`
- Review: `.legion/tasks/axiom-feishu-client/docs/review-change.md`
- Walkthrough: `.legion/tasks/axiom-feishu-client/docs/report-walkthrough.md`

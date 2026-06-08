# Axiom Install Sops CLI - Report Walkthrough

## Mode

implementation

## Summary

- Added `sops` to `axiom`'s host-local `user.packages` in `hosts/axiom/default.nix`.
- Kept scope limited to CLI availability; did not introduce `sops-nix`, modify agenix, or change secrets files.
- Verification confirms `pkgs.sops` exists, final `users.users.c1.packages` contains `sops`, and the `axiom` toplevel derivation evaluates.

## Files Changed

- `hosts/axiom/default.nix`: adds `sops` to the existing `user.packages` list.
- `.legion/tasks/axiom-install-sops-cli/plan.md`: task contract.
- `.legion/tasks/axiom-install-sops-cli/tasks.md`: task status.
- `.legion/tasks/axiom-install-sops-cli/log.md`: process log and handoff.
- `.legion/tasks/axiom-install-sops-cli/docs/test-report.md`: verification evidence.
- `.legion/tasks/axiom-install-sops-cli/docs/review-change.md`: readiness review.

## Verification

Evidence: `.legion/tasks/axiom-install-sops-cli/docs/test-report.md`

- PASS: `nix eval --impure --raw .#nixosConfigurations.axiom.pkgs.sops.pname` returned `sops`.
- PASS: `nix eval --impure --json .#nixosConfigurations.axiom.config.users.users.c1.packages --apply 'packages: builtins.any (pkg: (pkg.pname or "") == "sops") packages'` returned `true`.
- PASS: `nix eval --impure --raw .#nixosConfigurations.axiom.config.system.build.toplevel.drvPath` returned a valid toplevel `.drv` path.
- INCONCLUSIVE: `nix build --impure --dry-run .#nixosConfigurations.axiom.config.system.build.toplevel` exceeded the 120 second tool timeout while retrying a remote cache HTTP 500; recorded as an environment/cache limitation.

## Review

Evidence: `.legion/tasks/axiom-install-sops-cli/docs/review-change.md`

- PASS: No blocking findings.
- PASS: Scope is limited to one host-local package addition plus task evidence.
- PASS: Security lens applied because `sops` is secrets tooling; no secrets, agenix, identity, ownership, or `sops-nix` configuration changed.

## Residual Risk

- `sops` becomes available on the live `axiom` profile only after the user applies the NixOS configuration.
- `sops-nix` adoption remains a separate design task if declarative secrets integration is needed later.

## Post-Merge / Post-Switch Check

- After switching `axiom`, run `sops --version` to confirm the command is present in the live user environment.

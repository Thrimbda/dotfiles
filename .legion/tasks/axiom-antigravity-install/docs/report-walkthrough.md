# Axiom Antigravity Install - Walkthrough

Mode: implementation

## Summary

- Installs Google Antigravity on axiom by adding `unstable.antigravity-fhs` to the host-specific `user.packages` list.
- Uses the repository's existing `pkgs.unstable` overlay and `allowUnfree` setup; no new flake input, lock update, or manual install path was introduced.
- Keeps runtime concerns out of scope: no account, token, extension, sync, proxy, or GUI state configuration.

## Files Changed

- `hosts/axiom/default.nix` - adds `unstable.antigravity-fhs` to axiom user packages.
- `.legion/tasks/axiom-antigravity-install/**` - task contract and delivery evidence.

## Verification Evidence

- `nix eval --json .#nixosConfigurations.axiom.config.users.users.c1.packages ...` returned `antigravity`, proving the merged axiom user package list includes the package.
- `nix build --no-link .#nixosConfigurations.axiom.pkgs.unstable.antigravity-fhs` passed, proving the selected package builds from the current lock.
- `nix build --dry-run .#nixosConfigurations.axiom.config.system.build.toplevel` passed, proving the full axiom rebuild plan resolves and includes Antigravity derivations.
- `git diff --check` passed.

Full evidence: `docs/test-report.md`.

## Review Evidence

- `docs/review-change.md` passed with no blocking findings.
- Scope check confirmed the change is limited to axiom package installation and task evidence.
- Security lens found no auth, secret, privileged path, or trust-boundary changes; the only security-relevant residual is the expected proprietary GUI binary requested by the user.

## Known Limits

- The current lock resolves `antigravity-fhs` to version `1.15.8`; updating to a newer upstream Antigravity version is a separate lock/update task.
- GUI launch, Google login, extension marketplace, and runtime state were not validated because the contract only covers installation into the system environment.

---

*生成于: 2026-05-15*

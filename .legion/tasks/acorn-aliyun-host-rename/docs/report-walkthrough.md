# Walkthrough: Acorn Aliyun Host Profile Rename

Mode: implementation

## What Changed

- Removed the old Azure/development-oriented `hosts/acorn` profile.
- Moved the former `hosts/aliyun-acorn` profile into `hosts/acorn` as the canonical Acorn host.
- Updated the active host identity to `acorn`, including `networking.hostName`, `nixosConfigurations.acorn`, image base name, image flake reference, runbook commands, Axiom frp/autossh naming, and local age recipient variable names.
- Preserved Aliyun provider-specific runbook context and existing encrypted secret material.

## Reviewer Path

1. Start with `.legion/tasks/acorn-aliyun-host-rename/plan.md` for scope, non-goals, and risk level.
2. Review `.legion/tasks/acorn-aliyun-host-rename/docs/rfc.md` for the no-alias cutover decision.
3. Inspect the host move around `hosts/acorn/**` and `hosts/axiom/default.nix`.
4. Check `.legion/tasks/acorn-aliyun-host-rename/docs/test-report.md` for Nix eval/dry-run evidence.
5. Check `.legion/tasks/acorn-aliyun-host-rename/docs/review-change.md` for readiness and security-lens notes.

## Validation Evidence

- `nix eval` confirmed `nixosConfigurations.acorn` exists and `nixosConfigurations.aliyun-acorn` is absent.
- `nix eval` confirmed `networking.hostName = "acorn"`.
- `nix eval './hosts/acorn/image#aliyun-image.system'` returned `x86_64-linux`.
- `nix build --dry-run './hosts/acorn/image#aliyun-image'` planned successfully.
- `git diff --check` passed.
- Active host source/docs search found no stale `aliyun-acorn` references.

## Security Notes

- Age secret files were moved with the host profile but not decrypted or edited.
- Public key strings remained unchanged; only local variable names changed.
- No root-level `acorn_id_ed25519` material was touched.

## Residual Follow-Up

- Remote ECS boot, SSH reachability, ACME issuance, and runtime service health still require a separate deploy/validation task.
- Any external scripts outside this repo still using `aliyun-acorn` paths or flake attrs must be updated outside this PR.

# RFC Review: Prune Raw Tasks and Extract Host Frameworks

> **Decision**: PASS
> **Reviewed**: 2026-08-20
> **Design source**: `docs/rfc.md`

## Findings

- No blocking findings. The design is implementable, verifiable and rollbackable without introducing a new topology DSL.
- Shared modules remain limited to proven mechanics; single-host policy stays in host-local modules.
- Full PR revert provides a complete rollback path for both task pruning and module movement.

## Suggestions Applied

- Defined `_facts.nix` as a plain imported attrset, not a new option or argument framework.
- Limited Acorn `ingress.nix` to declarations currently owned by `hosts/acorn/default.nix`.
- Added baseline/candidate JSON comparison for moved Axiom workstation policy.
- Required module-local rollback to include its import and interface changes.

## Handoff

Implementation may proceed in the existing worktree. Preserve evaluated service topology and prefer mechanical moves over API growth.

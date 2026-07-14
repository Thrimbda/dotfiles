# Auth Mini Gateway Latest Pin

## Goal

Make Acorn's declarative auth-mini-gateway package match the latest upstream version already deployed for live validation.

## Problem

Acorn currently uses a runtime override for upstream `3e4c273`, while dotfiles still pins `f0519d1`. A reboot or NixOS switch would restore the older gateway.

## Acceptance Criteria

- The package pins `Thrimbda/auth-mini-gateway@3e4c273ae244e0745419ddc01d2ec02e3c140dbb` with correct source and cargo hashes.
- The gateway package and Acorn toplevel build successfully.
- Existing gateway service, allowlist, secret, nginx, and port configuration remains unchanged.
- The change is merged through a PR.

## Scope

- Update only `packages/auth-mini-gateway/default.nix` and Legion delivery evidence.

## Non-Goals

- Do not change gateway policy or service configuration.
- Do not add an RFC or redesign deployment.
- Do not repeat the already-completed live runtime deployment.

## Assumptions

- Upstream `master` is `3e4c273`, containing mobile session lifecycle changes from code commit `26c42aa` plus task closeout docs.
- The live Acorn runtime override is healthy on all four gateway instances.

## Constraints

- Preserve `buildRustPackage` and exact-revision source pinning.
- Do not expose gateway secrets or session data.

## Risks

- Incorrect source or cargo hashes would break evaluation/build; package and host builds must prove both.

## Design Summary

Advance the exact upstream revision and regenerate only the two Nix fixed-output hashes required by `fetchFromGitHub` and `buildRustPackage`.

## Phases

1. Refresh package pin and hashes.
2. Build package and Acorn toplevel.
3. Review, document, merge, and clean up.

# Auth Mini Upstream Release Pin

## Goal

Update the declarative Acorn auth-mini package to the upstream release produced after Passkey PR #137 merged.

## Problem

Acorn is temporarily running an independently deployed build, while dotfiles still pins the previous `latest` release hash. A future NixOS switch would either fail the fixed-output fetch or restore the older binary.

## Acceptance Criteria

- `packages/auth-mini/default.nix` identifies the 2026-07-12 upstream release and uses its published Linux archive hash.
- The auth-mini package and Acorn system configuration evaluate and build successfully.
- The pinned release corresponds to upstream merge commit `9560660a51ee0e0b0a538e36c0b2883b16281eff`.
- The change is delivered and merged through a PR.

## Scope

- Update only the auth-mini package version metadata and fixed-output hash.
- Record bounded verification and delivery evidence.

## Non-Goals

- Do not change auth-mini service, gateway, secret, nginx, or database configuration.
- Do not redesign deployment or add an RFC.
- Do not alter the already-running temporary Acorn process during this repository-only change.

## Assumptions

- Upstream `zccz14/auth-mini` PR #137 merged as commit `9560660`.
- The upstream `latest` Linux release asset digest is `sha256:3852e456f2a456b6a2f8cbf6d918659aad9256ff86c3a3f2eac2a1a27099b159`.

## Constraints

- Keep the existing `fetchurl` and `autoPatchelfHook` packaging design.
- Do not expose credentials or service data in task artifacts.

## Risks

- The mutable `latest` URL can drift again; the fixed hash intentionally makes such drift fail closed.
- A package-only build may miss host integration issues, so the Acorn toplevel must also build.

## Design Summary

Advance the date-based package version and replace the fixed-output hash with the verified upstream release digest. No service-level change is required.

## Phases

1. Update the release pin.
2. Build the package and Acorn configuration.
3. Review and document the bounded change.
4. Submit, merge, clean up, and refresh the main workspace.

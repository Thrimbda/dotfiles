# Acorn Vaultwarden Package Update

## 目标

Update Vaultwarden on Acorn to the newest package available from a separately pinned nixpkgs-vaultwarden input while preserving the primary nixpkgs lock and unrelated system package versions. Repair the discovered auth-mini fixed-output pin only as needed to restore the Axiom system build, then deploy safely from Axiom.

## 问题陈述

Vaultwarden currently comes from the globally pinned nixpkgs input. Updating that input would upgrade unrelated system packages, so Acorn needs an isolated package source and an explicit service package override. The required Axiom deployment build also exposed an existing auth-mini fixed-output mismatch: the mutable `latest` asset changed while its declared SHA-256 remained pinned to an older artifact.

## 验收标准

- [ ] A dedicated nixpkgs-vaultwarden flake input supplies synchronized services.vaultwarden.package and services.vaultwarden.webVaultPackage values on Acorn without changing the primary nixpkgs lock.
- [ ] Updating nixpkgs-vaultwarden refreshes only its lock node and yields the newest Vaultwarden version packaged by the selected nixos-unstable revision.
- [ ] The Acorn configuration evaluates with the isolated package for its target system while preserving existing Vaultwarden settings, secret handling, backup directory, and reverse-proxy configuration.
- [ ] `packages/auth-mini/default.nix` pins the official current `auth-mini-linux-x86_64.tar.gz` through its GitHub release asset-ID API endpoint with the matching SRI SHA-256 and accurate asset date metadata, without changing auth-mini service configuration or behavior.
- [ ] The complete Acorn closure builds on Axiom after the verified auth-mini pin repair; no build occurs on Acorn.
- [ ] The documented Acorn deployment command runs from Axiom and the post-switch Vaultwarden service is healthy with the intended version or a concrete blocker is recorded.
- [ ] The post-switch auth-mini service and its non-authenticated health surface remain healthy, without testing login flows or exposing authentication data.
- [ ] Rollback is possible by reverting the input and package override, then switching Acorn with the prescribed remote-build command.

## 假设 / 约束 / 风险

- **假设**: The current workspace is Axiom and can safely perform the required remote build and deployment to Acorn.
- **假设**: nixos-unstable provides a current Vaultwarden package compatible with the existing NixOS Vaultwarden module and Acorn data directory.
- **假设**: Acorn backups and current database state are healthy enough for a routine Vaultwarden package upgrade.
- **假设**: The official `zccz14/auth-mini` latest-release asset and its GitHub API digest identify the intended x86_64 Linux binary.
- **约束**: Do not update the primary nixpkgs input or unrelated flake inputs.
- **约束**: Never build or evaluate the system closure on Acorn; use the exact prescribed remote deployment command from Axiom.
- **约束**: Do not expose or modify Vaultwarden secrets, database contents, domain configuration, or authentication settings.
- **约束**: Production configuration changes must occur in an isolated worktree after RFC review.
- **约束**: Keep auth-mini service configuration, secrets, database, routes, and gateway behavior unchanged; change only its package source reference, version metadata, and fixed-output SHA unless a revised RFC explicitly approves more.
- **风险**: A newer Vaultwarden release can perform database migrations or change runtime behavior.
- **风险**: An incorrect package-system selection can make the Acorn configuration fail evaluation.
- **风险**: Remote deployment can fail because of build, transfer, SSH, sudo, or activation issues; the fallback must not build on Acorn.
- **风险**: Updating the authentication-service binary can affect login or session behavior even when the service configuration does not change.
- **风险**: GitHub release-asset API downloads require an explicit content-negotiation header; a malformed source reference or header can make the package fail to fetch.

## 关键主张

- **auth-mini-asset-provenance**: The new SRI SHA-256 is the base64 form of the official GitHub release asset digest for `auth-mini-linux-x86_64.tar.gz`, and the asset-ID API endpoint resolves that asset. This is an authority claim, high criticality, and blocks deployment if evidence is incomplete or disagrees.
- **auth-mini-build-compatibility**: The repaired package can build as part of the Acorn closure on Axiom without changing auth-mini service shape. This is a formal/routine claim, high criticality, and blocks deployment on failure.
- **auth-mini-post-switch-health**: After the required remote switch, the auth-mini systemd unit and non-authenticated health surface are healthy. This is an objective/routine claim, critical, and blocks delivery on failure.

## 要点

- Use an independent nixpkgs-vaultwarden input on nixos-unstable and reference its legacyPackages for the Acorn target system.
- Keep the primary nixpkgs node unchanged and confirm the lock diff is limited to the new input and its dependencies.
- Verify package version, configuration shape, remote service health, and rollback path.
- Verify the upstream auth-mini asset provenance before accepting its asset-ID source reference and fixed-output SHA.

## 范围

- flake.nix and flake.lock input wiring.
- hosts/acorn/modules/vaultwarden.nix service and Web Vault package selection.
- packages/auth-mini/default.nix asset-ID source reference, version metadata, fetch header, and fixed-output SHA only.
- Task-local RFC, review, verification, walkthrough, and wiki artifacts.
- The prescribed Axiom-to-Acorn deployment and non-destructive post-deployment health checks.

## 非目标

- Do not refresh the primary nixpkgs input, nixpkgs-unstable, or any unrelated flake input.
- Do not change Vaultwarden secrets, database schema manually, user data, domain, authentication policy, backup retention, or Nginx routing.
- Do not replace the NixOS Vaultwarden module or add an external container or overlay unless the approved design proves the isolated input cannot work.
- Do not use Acorn as a build host or fall back to a local build on Acorn if deployment fails.
- Do not update auth-mini source code, service options, database schema, gateway configuration, secrets, authentication policy, or HTTP routing.
- Do not weaken, remove, or bypass the fixed-output hash or content-negotiation header to make the upstream asset build.

## 设计索引 (Design Index)

> **Design Source of Truth**: docs/rfc.md

**摘要**:
- Add a dedicated nixpkgs-vaultwarden input rather than reuse nixpkgs-unstable, so future Vaultwarden updates do not advance unrelated unstable packages.
- Bind services.vaultwarden.package and services.vaultwarden.webVaultPackage to the input package set for pkgs.stdenv.hostPlatform.system.
- Use an RFC to define preflight, deployment, health checks, rollback, and lockfile-isolation verification before applying the change.
- Replace the mutable upstream `latest` URL with the official GitHub release asset-ID API endpoint, use the documented content-negotiation header, and accept the fixed-output hash only after it matches the official asset digest.

## 阶段概览

1. **Contract** - Materialize the stable update contract
2. **Design** - Produce and review the Vaultwarden design, then reopen it for the high-risk auth-mini source-pin repair.
3. **Implementation** - Create an isolated worktree, implement the approved input override, and apply only the reviewed auth-mini package pin repair.
4. **Verification** - Verify lock isolation, package provenance, configuration, full Axiom build, deployment, and both service health surfaces.
5. **Review and Delivery** - Review implementation and operational safety, then produce delivery artifacts and wiki writeback after a successful deployment.

---

*创建于: 2026-07-30 | 最后更新: 2026-07-30*

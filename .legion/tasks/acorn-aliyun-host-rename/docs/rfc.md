# RFC: Acorn Aliyun Host Profile Rename

## Context

The repository currently exposes two Acorn-shaped NixOS host profiles:

- `hosts/acorn`: the older Azure/development-oriented `acorn` profile.
- `hosts/aliyun-acorn`: the low-resource Alibaba Cloud ECS profile that now owns the public `0xc1.wang` server role.

The requested cutover is to delete the old `acorn` and rename `aliyun-acorn` to `acorn`. Because `mapHosts ./hosts` derives `nixosConfigurations.<name>` from directory names, this is not just a filesystem move: active references to the old `aliyun-acorn` attr, image flake path, image base name, runtime hostname, Axiom frp/autossh references, and runbook commands must be updated together.

## Goals

- Make the former `hosts/aliyun-acorn` content the only active `hosts/acorn` profile.
- Expose the target as `nixosConfigurations.acorn` with `networking.hostName = "acorn"`.
- Update active source/runbook references that directly address the target host identity.
- Preserve encrypted secret material and public keys without rotation.

## Non-Goals

- No remote deploy, DNS cutover, Terraform migration, Aliyun API operation, or data migration.
- No compatibility alias for `nixosConfigurations.aliyun-acorn` unless review finds an active in-repo consumer that cannot be updated.
- No rewrite of historical `.legion/tasks/**` or existing historical wiki task summaries.
- No deletion or rotation of root-level `acorn_id_ed25519` material.

## Options

### Option A: Atomic rename without alias

Delete the old `hosts/acorn`, move `hosts/aliyun-acorn` to `hosts/acorn`, and update active references to the new `acorn` identity.

Pros:

- Matches the user's requested end state directly.
- Avoids two names for the same target.
- Lets validation fail fast if any active `aliyun-acorn` consumer remains.

Cons:

- Requires synchronized updates across the image flake, runbook, and Axiom references.
- Historical docs will still mention old names by design.

### Option B: Keep an `aliyun-acorn` alias

Keep compatibility for `nixosConfigurations.aliyun-acorn` while introducing `acorn`.

Pros:

- Reduces short-term breakage for unknown consumers.

Cons:

- Violates the requested rename by preserving the old active identity.
- Adds compatibility code without a proven persisted or external contract.
- Makes future operations ambiguous.

### Option C: Filesystem symlink

Replace one host directory with a symlink or wrapper to the other.

Pros:

- Small apparent diff.

Cons:

- Keeps two active names or non-obvious filesystem behavior.
- Weakens `mapHosts` clarity and makes Nix/secret paths harder to reason about.

## Decision

Use Option A.

The implementation should perform a clean directory-level cutover and update only active source/runbook references needed for the renamed host. Historical Legion task records stay historical; this task's wiki writeback will record the new current truth.

## Implementation Boundaries

- Remove old `hosts/acorn/**` contents from the active tree.
- Move `hosts/aliyun-acorn/**` to `hosts/acorn/**`.
- Update `hosts/acorn/default.nix` hostName from `aliyun-acorn` to `acorn`.
- Update `hosts/acorn/image/flake.nix` to extend `dotfiles.nixosConfigurations.acorn` and use an `nixos-acorn` image base name.
- Update `hosts/acorn/README.md` commands, image names, runtime hostname examples, and path references to `acorn` while retaining Aliyun provider terminology where it describes the cloud provider.
- Rename active Nix variable/service labels in `hosts/axiom/default.nix` and `hosts/axiom/secrets/secrets.nix` from `aliyunAcorn`/`frpc-aliyun-acorn-*` to `acorn` equivalents without changing IPs or key values.
- Rename local recipient variables in moved `hosts/acorn/secrets/secrets.nix` without changing encrypted files or public key strings.

## Verification

Run scoped checks from the worktree:

- `nix flake show --json --all-systems --no-write-lock-file` or a narrower equivalent to confirm `nixosConfigurations.acorn` exists.
- `nix eval --raw .#nixosConfigurations.acorn.config.networking.hostName` returns `acorn`.
- `nix eval --raw './hosts/acorn/image#aliyun-image.system'` returns `x86_64-linux`.
- `nix build --dry-run './hosts/acorn/image#aliyun-image'` plans successfully, or record the environmental blocker.
- `git diff --check` passes.
- Search active source for stale `hosts/aliyun-acorn`, `nixosConfigurations.aliyun-acorn`, and runtime hostname `aliyun-acorn` references, excluding historical Legion records and this task's rationale.

## Rollback

Rollback is a normal git revert of the PR branch. No remote resources, DNS, secret recipients, or data stores are mutated by this task.

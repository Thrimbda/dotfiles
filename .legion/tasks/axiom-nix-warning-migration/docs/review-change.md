# Change Review: Axiom Nix Warning Migration

## Decision

PASS.

## Blocking Findings

None.

## Scope Review

- In scope: Axiom-reachable deprecated options and package aliases, root platform declarations, system-path ownership, and the focused Bluetooth VM fixture.
- Out of scope avoided: no flake input update, global warning suppression, deployment, Acorn build, or production Bluetooth resume behavior change.

## Correctness Review

- The supported replacements remove the warned package and option forms while retaining the selected GTK4, Steam, NVIDIA Settings wrapper, XKB, and SSH askpass behavior.
- The root platform list now matches declared hosts: the two Darwin hosts are `aarch64-darwin`, and no declared host consumes `x86_64-darwin`.
- The Bluetooth fixture replaces the deprecated hook with explicit boot and resume services. The corrected assertion observes the `tlp` node that actually runs the boot fixture.
- Single package ownership resolves the system-path collisions without broad priority suppression. The evaluated OpenSSH package contains wrapped `ssh`, `scp`, `ssh-add`, and `ssh-copy-id` entrypoints.

## Security Lens

Applied because `modules/xdg.nix` changes OpenSSH client package ownership. No server authentication, key handling, authorization, firewall, tunnel, or secret behavior changes. The remaining gap is command-level wrapper behavior rather than a new trust boundary.

## Verification Reviewed

- Targeted Bluetooth VM regression: PASS.
- Rendered Axiom, Atlas, Azar, Darwin-platform, and host-metadata assertions: PASS.
- `nixos-rebuild build --flake .#axiom --show-trace -L`: PASS with no warning output.
- `git diff --check`: PASS.

## Residual Test Gaps

- No live Axiom activation or suspend/resume test was run; both are explicitly outside this task's safe, non-deployment scope.
- No command-level OpenSSH wrapper smoke covers XDG config, known-host, or `ssh-copy-id` behavior. The evaluated package contents confirm wrapper ownership only.

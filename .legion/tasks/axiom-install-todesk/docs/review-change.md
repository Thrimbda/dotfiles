# Review: Install ToDesk on axiom

Date: 2026-05-11

## Verdict

PASS.

## Blocking Findings

None.

## Scope Review

- In scope: `hosts/axiom/default.nix` adds `todesk` to the existing host-local `user.packages` list.
- In scope: task-local Legion evidence under `.legion/tasks/axiom-install-todesk`.
- No out-of-scope daemon, service, firewall, desktop-module, or live-system switch changes were introduced.

## Correctness Review

- `todesk` is referenced through `with pkgs;`, matching the surrounding package list style.
- Verification confirms the pinned nixpkgs input exposes `todesk-4.7.2.0`, `meta.broken = false`, `mainProgram = "todesk"`, and `platforms = [ "x86_64-linux" ]`.
- Host configuration evaluation confirms `hasTodesk = true` and produces an axiom toplevel derivation path.

## Security Lens

Applied lightly because remote desktop software is security-sensitive. This change only makes the application package available; it does not configure credentials, enable a daemon, open firewall ports, or change remote-access policy. No exploitable trust-boundary change was found in this diff.

## Residual Risks

- Runtime launch/login behavior was not tested because the task explicitly avoids live-system switching.
- ToDesk remains proprietary/unfree software; package inclusion is intentional and already supported by the repo's unfree package policy.

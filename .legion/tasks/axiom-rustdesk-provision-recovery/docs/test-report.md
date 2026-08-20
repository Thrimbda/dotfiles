# Verification Report: Axiom RustDesk Provision Recovery

> **Date**: 2026-08-20
> **Worktree**: `.worktrees/axiom-rustdesk-provision-recovery`
> **Scope**: Static, generated-artifact, and closure verification before merge
> **Verdict**: PASS for source/build evidence; live switch pending merged source and interactive sudo

## Why These Checks

The change is a root-owned Nix-generated shell state machine. Source grep alone
cannot prove that the Nix interpolation produces valid shell or that systemd
receives the new restart trigger. The selected checks therefore cover Nix
evaluation, full Axiom closure realization, the exact generated script, and the
exact generated unit without invoking RustDesk or opening the encrypted secret.

## Results

| Gate | Command or Artifact | Result |
| --- | --- | --- |
| Build-host safety | `hostname` | PASS: `axiom`; no Acorn build was run. |
| Diff hygiene | `git diff --check` | PASS: no whitespace errors. |
| Source branch removal | `attempt-used` search in `hosts/axiom/modules/rustdesk.nix` | PASS: no remaining production terminal path. |
| Source shape | Source inspection of `remove_revision_object`, `reservation-reset`, and `restartTriggers` | PASS: cleanup is inspect-remove-sync-reinspect; current ready exits before password flow. |
| Axiom evaluation | `nix eval --impure --raw .#nixosConfigurations.axiom.config.system.build.toplevel.drvPath` | PASS: produced `/nix/store/0vk62zaci1l4lcylspz5g3m3l1nghgk4-nixos-system-axiom-26.05.7813.0dd31db7e6db.drv`. |
| Trigger evaluation | `nix eval --impure --json '.#nixosConfigurations.axiom.config.systemd.services."rustdesk-provision".restartTriggers'` | PASS: the list contains the agenix ciphertext, revision object, and `axiom-rustdesk-provision` script. |
| Closure dry run | `nix build --impure --dry-run .#nixosConfigurations.axiom.config.system.build.toplevel` | PASS: Nix planned 31 derivations with the candidate provision script and restart-trigger unit. |
| Closure build | `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel` | PASS: all 31 planned derivations built successfully on Axiom. |
| Generated shell syntax | `bash -n /nix/store/6f8i8gqizkw2v7nx9v36h75qi9z2l3b6-axiom-rustdesk-provision` | PASS. |
| Generated recovery path | Built script lines 127-137 and 576-599 | PASS: helper validates before and after removal; `ready=current` exits 0; `ready=absent|stale` removes only a current reservation and continues. |
| Generated systemd unit | `systemd-analyze verify /nix/store/7xjfbbx9hln9vnni3jyc8qr3ndd7g9zj-unit-rustdesk-provision.service/rustdesk-provision.service` | PASS: no diagnostics. |
| Trigger materialization | Built `X-Restart-Triggers-rustdesk-provision` artifact | PASS: it contains `/nix/store/6f8i8gqizkw2v7nx9v36h75qi9z2l3b6-axiom-rustdesk-provision`. |

## Evidence Boundary

- No RustDesk command, agenix secret read, mutable provision state read, state
  deletion, finalizer, or system switch was executed during static validation.
- `sudo -n` requires an interactive password, so live state metadata cannot be
  inspected from this session. The observed `attempt-used` log is enough to
  establish a valid current reservation but cannot distinguish absent from
  current ready state.
- A live switch after merge is the decisive regression test: either current
  ready exits successfully without reapplying the password, or absent/stale
  ready consumes the reservation and retries the existing protected flow.
- An exploratory `nix path-info` invocation was not applicable to the already
  realized toplevel path and is not used as evidence; it did not affect the
  successful evaluation or build gates above.

## Required Post-Merge Runtime Check

1. Refresh Axiom to merged `origin/master` and run the normal privileged
   `nixos-rebuild switch --flake .#axiom` flow.
2. Confirm the command no longer returns nonzero because of
   `rustdesk-provision.service`.
3. Inspect `systemctl status rustdesk-provision.service` and bounded journal
   output. There must be no `attempt-used` entry from the new invocation.
4. If a current ready record remains, retain the explicit
   `rustdesk-provision-finalize --confirm-remote-auth` process; do not finalize
   without a real remote authentication confirmation.

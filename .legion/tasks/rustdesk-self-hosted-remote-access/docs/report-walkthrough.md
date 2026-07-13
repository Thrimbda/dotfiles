# RustDesk Axiom Fixed-Forward Hotfix

> **Mode:** implementation
> **Design review:** Round 9 PASS
> **Verification:** PASS
> **Change review:** PASS for hotfix PR
> **Candidate runtime:** pending until merge

## Problem

The merged 1.4.9 deployment exposed three Axiom runtime blockers:

1. Clash fake-IP resolution broke RustDesk's required TCP path.
2. The spawned c1 server lacked the active Hyprland session coordinates.
3. The RustDesk wrapper did not expose PipeWire's `pipewiresrc` plugin.

The old Axiom reservation remains present, its ready process identity is invalid, and no stamp exists. RustDesk is stopped. That state must not be finalized or rolled back.

## Change

Only `hosts/axiom/default.nix` changes:

- Resolve the canonical RustDesk hostname directly to Acorn on Axiom.
- Add the static c1 Hyprland/DBus coordinates while preserving root `HOME=/root` and `XDG_CONFIG_HOME=/root/.config`.
- Add the immutable `${pkgs.pipewire}/lib/gstreamer-1.0` plugin path.
- Include the resolver and exact service environment in a fresh composite revision while retaining the legal `axiom-rustdesk-provision-v4:` prefix.

Acorn, Charlie, secrets, modules and the existing provision/finalizer state machine are unchanged.

## Evidence

- Exact option, resolver, environment and revision checks: PASS.
- `pipewiresrc`, `videoconvert` and `appsink` factory checks: PASS.
- Stale reservation/ready transition and old-finalizer rejection: PASS.
- Generated script syntax and ShellCheck: PASS.
- Full Axiom build: `/nix/store/lx4xz9nwrsaxkayb9byp1fk1p1s5mybf-nixos-system-axiom-25.11.20260630.b6018f8`.
- No candidate switch, secret read, authentication, capture, input or finalization is claimed.

## Post-Merge Gate

Switch Axiom only from the clean merged commit. Require a fresh reservation/ready, direct canonical resolution, correct live child environment, successful screen/input control, correct-password success and wrong-password rejection. Then run the exact manual finalizer and verify fast-skip. Any failure means stop RustDesk and fixed-forward again. Charlie remains blocked until Axiom finalizes.

Evidence: [`test-report.md`](./test-report.md), [`review-change.md`](./review-change.md).

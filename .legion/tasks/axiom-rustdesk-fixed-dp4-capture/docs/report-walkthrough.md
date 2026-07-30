# Delivery Walkthrough: Persistent unattended DP-4 capture

## Mode

Implementation.

## Change

Axiom already has an XDPH picker that emits `screen:DP-4`, but the actual
RustDesk c1 server inherited root's config path and could not save the portal
restore token. This change adds a pre-start state-access script to
`rustdesk.service`:

- `RustDesk.toml`, containing permanent-password material, remains root-owned.
- `RustDesk2.toml`, which holds RustDesk options including the Wayland restore
  token, is owned by c1.
- ACL traversal plus a sticky RustDesk config directory lets c1 update only its
  Config2 file atomically while protecting root-owned sibling files.
- RustDesk's root service, environment, network/auth configuration, monitor
  layout, and fixed DP-4 XDPH picker are unchanged.

## Evidence

- `docs/rfc.md` documents the alternatives and why a virtual display was
  rejected.
- `docs/review-rfc.md` passed the design gate.
- `docs/test-report.md` records the passing full Axiom build, generated unit
  inspection, generated script syntax check, and unchanged root environment.
- `docs/review-change.md` passed scope, correctness, and security review for
  merge.

## Remaining Runtime Check

After the PR is merged and deployed from refreshed `origin/master`, make one
new remote RustDesk connection and another after restarting RustDesk. Both must
show DP-4 without an Axiom-side chooser. This is deliberately not claimed as
complete before the privileged switch and remote-client exercise occur.

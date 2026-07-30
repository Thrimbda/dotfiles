# Change Review: Persistent unattended DP-4 capture

## Verdict

**PASS for merge.** Production runtime acceptance remains pending the merged
system switch and remote connection test recorded in `test-report.md`.

## Findings

No implementation blockers found.

## Scope and Correctness

- The production change is limited to `hosts/axiom/default.nix`.
- `rustdesk.service` keeps the existing root user, `--service` start command,
  environment, stop command, limits, network ordering, and provisioning path.
- The new pre-start script creates no virtual output and does not alter the
  Hyprland monitor or XDPH picker configuration. The existing picker remains
  fixed to `screen:DP-4`.
- `RustDesk2.toml` is prepared before the c1 child starts, so RustDesk can load
  a persisted portal restore token immediately after a service restart.
- The config directory is sticky. c1 can atomically replace its own Config2
  file but cannot rename or remove root-owned sibling files.

## Security Review

The security lens applies because this changes a root-owned state boundary and
the token governs unattended screen capture.

- `RustDesk.toml`, which upstream uses for permanent-password material, stays
  root-owned and inaccessible to c1.
- c1 receives traversal only on `/root` and `/root/.config`; it gets write
  access only in the RustDesk config directory and ownership only of
  `RustDesk2.toml`.
- This trusts c1 with its portal restore token and non-secret client options.
  That is within the existing single-owner RustDesk trust boundary, but it
  would not be acceptable for a shared or untrusted local account.

## Verification Review

The full Axiom `toplevel` build, generated-script syntax check, generated-unit
inspection, exact environment evaluation, and diff hygiene check passed.
The only remaining evidence is necessarily runtime-only: a merged privileged
switch plus two remote connections, including one after a RustDesk restart.

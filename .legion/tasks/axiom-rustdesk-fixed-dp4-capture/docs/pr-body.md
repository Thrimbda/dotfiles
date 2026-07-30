## Summary

Make Axiom's RustDesk Wayland selection persistent without a virtual display.
The existing XDPH picker continues to select `DP-4`; the RustDesk c1 server can
now persist its portal restore token in `RustDesk2.toml`.

## Security Boundary

`RustDesk.toml` remains root-owned and holds permanent-password material.
Only `RustDesk2.toml` becomes c1-owned. Sticky-directory and ACL rules allow
c1 to update that file without deleting or replacing root-owned siblings.

## Verification

- Passed: Axiom `toplevel` build, generated script syntax, generated unit
  inspection, unchanged root service environment, and `git diff --check`.
- Pending after merge and privileged switch: two remote connections, including
  one after a RustDesk restart, must capture DP-4 without a local chooser.

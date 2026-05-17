# Report Walkthrough

## Mode
Implementation.

## What Changed
- Removed the Hypridle `$suspend_cmd` definition from `config/hypr/hypridle.conf`.
- Removed the 15 minute `timeout = 900` listener that called the suspend command.
- Left the 5 minute `hyprlock` listener and 10 minute DPMS off/on listener unchanged.

## Why
The requested Axiom default is to stop automatic idle suspend from Hypridle while preserving idle security and display power saving. This removes the suspend trigger itself instead of depending on Keep Awake state or another inhibitor to counteract it.

## Evidence
- `docs/test-report.md`: PASS for suspend-string grep, `git diff --check`, and Axiom toplevel build.
- `docs/review-change.md`: PASS with no blocking findings; security lens found no permission, auth, secret, trust-boundary, or data-exposure changes.

## Residual Risk
Live Hypridle reload and real idle behavior still require a post-deploy graphical-session smoke check on Axiom.

# SSH Foot Term Compatibility Walkthrough

> Mode: implementation
> Task: `.legion/tasks/ssh-foot-term-compat/`
> Branch: `legion/ssh-foot-term-compat`
> Worktree: `.worktrees/ssh-foot-term-compat/`

## Summary

This fixes SSH sessions launched from Foot-backed hosts failing remote startup when the target machine lacks Foot terminfo. The local Foot/default terminal setup stays unchanged; only the repository-managed `ssh` wrapper now exports `TERM=xterm-256color` before invoking OpenSSH.

## Why

Remote hosts may not have a terminal definition for `foot`. When `TERM=foot` reaches those hosts, remote shell startup or Nix `set-environment` scripts can print `can't find terminal definition for foot`. Setting a portable terminal type at the SSH boundary avoids requiring every remote host to install Foot terminfo.

## Changed Files

- `modules/xdg.nix`: adds `--set TERM xterm-256color` to the wrapped `ssh` binary and documents the Foot terminfo portability reason.
- `.legion/tasks/ssh-foot-term-compat/**`: records the task contract, verification, review, and delivery evidence.

## Validation

- PASS: `git diff --check`.
- PASS: Axiom evaluates `modules.xdg.ssh.enable = true`.
- PASS: Azar evaluates `modules.xdg.ssh.enable = true`.
- PASS: built the generated Axiom OpenSSH wrapper and confirmed `bin/ssh` contains `export TERM='xterm-256color'`.
- PASS: confirmed generated `bin/scp` has no `TERM` override.

Details: `docs/test-report.md`.

## Review

PASS with no blocking findings. Security lens was applied because SSH is a protocol/trust-boundary component; no auth, identity, host-key, permission, secret, crypto, or command execution policy changes were found.

Details: `docs/review-change.md`.

## Residual Risk

- Live SSH to an affected remote host was not run in this tool session.
- Users bypassing the repository-managed `ssh` binary will still send their ambient `TERM`.
- Remote applications may lose Foot-specific capabilities, which is the accepted compatibility tradeoff.

## Deployment Note

After this lands, rebuild the affected host configuration and start a new SSH session. Existing SSH sessions will not be changed retroactively.

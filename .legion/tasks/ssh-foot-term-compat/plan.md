# SSH Foot Term Compatibility

## Task Identity

- Name: SSH Foot Term Compatibility
- Task ID: `ssh-foot-term-compat`
- Trigger: user reported SSHing from Foot prints `can't find terminal definition for foot` from a Nix `set-environment` script on remote machines.
- Base ref: `origin/master`

## Goal

Make SSH sessions from hosts using Foot avoid remote terminfo failures while keeping Foot as the local/default terminal.

## Problem

The local terminal stack can expose `TERM=foot` to SSH sessions. Some remote hosts do not have Foot's terminfo installed, so shell startup or Nix-generated environment setup on the remote side cannot resolve the terminal definition and prints errors before the session is usable. This is a portability problem at the SSH boundary, not a request to replace Foot or redesign local terminal behavior.

## Acceptance Criteria

- Interactive SSH launched through the repository-managed OpenSSH wrapper sends a widely available terminal type instead of `foot`.
- The change does not alter the configured default terminal, Foot package/config generation, or local tmux terminal behavior.
- The fix stays scoped to the SSH client boundary and does not require installing Foot terminfo on every remote host.
- Nix evaluation for at least one affected host succeeds, and diff whitespace validation passes.
- Task evidence records the implementation choice, validation, and PR lifecycle state.

## Scope

- Inspect the Foot terminal and SSH wrapper configuration relevant to `TERM` propagation.
- Patch the repository-managed SSH client wrapper to use a portable terminal value for SSH sessions.
- Validate the Nix configuration path and record targeted verification.
- Ship through the Legion worktree/PR lifecycle.

## Non-Goals

- Do not change `modules.desktop.term.default` away from `foot`.
- Do not change Foot's config files or package selection.
- Do not force remote hosts to install Foot terminfo.
- Do not redesign tmux defaults or shell startup beyond the SSH boundary.
- Do not touch unrelated untracked files such as local token material.

## Assumptions

- The reported remote errors are caused by `TERM=foot` reaching machines without Foot terminfo.
- `xterm-256color` is available broadly enough to be the safest default for SSH ptys.
- The repository-managed OpenSSH wrapper is the right central place because affected hosts already enable `modules.xdg.ssh`.

## Constraints

- Use the Legion worktree/PR lifecycle with branch `legion/ssh-foot-term-compat` and worktree `.worktrees/ssh-foot-term-compat/`.
- Preserve unrelated user changes in the main workspace.
- Keep the patch minimal and reversible.

## Risks

- Some remote applications may lose Foot-specific terminal capabilities over SSH, but this is preferable to startup errors on hosts lacking terminfo.
- Non-wrapper SSH binaries or manually launched alternate clients will not inherit this repository-managed fix.
- Existing sessions will not change until the NixOS configuration is rebuilt and a new SSH process is launched.

## Design Summary

- Keep local terminal configuration intact.
- Treat the SSH client wrapper as the portability boundary.
- Set `TERM=xterm-256color` only for the wrapped `ssh` binary, leaving `scp`, `ssh-add`, Foot, and local tmux untouched.
- Validate by evaluating affected host configuration and checking the wrapper diff.

## Phases

- Brainstorm: materialize this narrow compatibility contract.
- Engineer: patch the SSH wrapper in the isolated worktree.
- Verify: run targeted Nix evaluation and diff validation.
- Review/report/wiki: document readiness and ship through the PR lifecycle.

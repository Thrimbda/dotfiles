# SSH Foot Term Compatibility Review

## Result

PASS. No blocking correctness, maintainability, scope, or security findings were found.

## Blocking Findings

None.

## Scope Compliance

- `modules/xdg.nix` changes only the repository-managed OpenSSH wrapper.
- `TERM=xterm-256color` is applied to the wrapped `ssh` binary only.
- `scp`, `ssh-add`, Foot package/config, local default terminal, and tmux behavior remain unchanged.
- The change matches the task contract's SSH-boundary-only scope.

## Correctness And Maintainability

- The generated Axiom `bin/ssh` wrapper contains `export TERM='xterm-256color'`, directly addressing remote hosts that lack Foot terminfo.
- The sibling generated `bin/scp` wrapper has no `TERM` override, matching the intended narrow behavior.
- The explanatory comment is short and tied to the concrete compatibility boundary.
- Verification evidence covers diff whitespace, host enablement for Axiom and Azar, and generated wrapper output.

## Security Lens

Security lens applied because the change touches SSH, a protocol/trust-boundary component.

Outcome: no security blocker. The patch does not change authentication, identity selection, host key handling, permissions, secrets, crypto, command execution policy, or remote trust decisions. It only changes the terminal type environment value used by the wrapped interactive SSH client.

## Residual Risks And Gaps

- Live SSH to an affected remote host was not run in this tool session.
- Users bypassing the repository-managed `ssh` binary will still send their ambient `TERM`.
- Hard-setting `TERM=xterm-256color` may reduce Foot-specific capabilities in remote interactive applications, which is an accepted tradeoff for remote compatibility.

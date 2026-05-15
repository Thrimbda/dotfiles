## Summary

- Set `TERM=xterm-256color` at the repository-managed `ssh` wrapper boundary so Foot-backed hosts do not send `TERM=foot` to remotes lacking Foot terminfo.
- Keep local Foot/default terminal config, local tmux behavior, `scp`, and `ssh-add` unchanged.
- Add Legion task evidence for the contract, verification, review, and delivery walkthrough.

## Validation

- PASS: `git diff --check`
- PASS: `nix eval --impure --expr '(builtins.getFlake (toString ./.)).nixosConfigurations.axiom.config.modules.xdg.ssh.enable'`
- PASS: `nix eval --impure --expr '(builtins.getFlake (toString ./.)).nixosConfigurations.azar.config.modules.xdg.ssh.enable'`
- PASS: built the generated Axiom OpenSSH wrapper and confirmed `bin/ssh` exports `TERM='xterm-256color'`
- PASS: confirmed generated `bin/scp` has no `TERM` override

## Review

- PASS: `docs/review-change.md`
- Security lens applied for SSH touchpoint; no blocker found.

## Evidence

- Contract: `.legion/tasks/ssh-foot-term-compat/plan.md`
- Test report: `.legion/tasks/ssh-foot-term-compat/docs/test-report.md`
- Review: `.legion/tasks/ssh-foot-term-compat/docs/review-change.md`
- Walkthrough: `.legion/tasks/ssh-foot-term-compat/docs/report-walkthrough.md`

# Log: Axiom CLI Mode

- User requested a mode for `axiom` that does not start the desktop when the machine is used only through SSH, with local screens showing a raw TTY.
- User confirmed the command should not have any relationship to `hey`.
- Chosen task id: `axiom-cli-mode`.
- Git lifecycle: isolated worktree `.worktrees/axiom-cli-mode`, branch `legion/axiom-cli-mode-ssh-tty`, base `origin/master`.
- Implemented `axiom-mode` as a plain `pkgs.writeShellScriptBin` command in `environment.systemPackages`, with no `hey` invocation or hook dependency.
- Added `axiom-cli.target` requiring `multi-user.target`, wanting `getty@tty1.service`, conflicting with `graphical.target`, and allowing isolation.
- Verification passed: targeted Nix eval, generated script build plus `bash -n`, and Axiom system dry-run.
- Review found one non-blocking correctness improvement before final PASS: `axiom-mode status` now uses `list-units --all` so inactive units are not omitted.
- Change review passed with security lens applied for sudo/systemctl usage; no blocking findings.
- Generated implementation walkthrough artifacts: `docs/report-walkthrough.md`, `docs/report-walkthrough.html`, and `docs/pr-body.md`.
- Wrote Legion wiki summary and durable decision/pattern/maintenance entries for `axiom-mode`.

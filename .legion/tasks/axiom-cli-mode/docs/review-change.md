# Review Change: Axiom CLI Mode

Decision: PASS.

## Findings

No blocking findings.

## Scope Review

The diff is limited to the approved scope:

- `hosts/axiom/default.nix`: adds the standalone `axiom-mode` command and `axiom-cli.target`.
- `hosts/axiom/README.org`: documents mode usage and systemd target semantics.
- `.legion/tasks/axiom-cli-mode/**`: records task contract, log, and verification evidence.

No unrelated Axiom service topology, desktop module, SSH module, or power-management behavior is changed.

## Correctness Review

- `axiom-cli.target` requires `multi-user.target`, wants `getty@tty1.service`, conflicts with `graphical.target`, and has `AllowIsolate = true`, matching the intended CLI mode behavior.
- `greetd` remains attached to `graphical.target`, while `sshd`, reverse SSH, cloudflared, and opencode remain attached to `multi-user.target`.
- `axiom-mode cli` and `axiom-mode desktop` persist the selected default target before isolating it, so the mode survives reboot.
- `axiom-mode status` uses `list-units --all` so inactive units are not silently omitted from the report.

## Security Lens

Applied because the command invokes `sudo` and privileged `systemctl` operations.

No blocking security issue found:

- The command dispatch is restricted to fixed case branches.
- The privileged target names passed to `systemctl` are fixed strings, not user-controlled shell fragments.
- The script uses store paths for `systemctl`, `id`, and `printf`, and the only runtime wrapper path is the standard NixOS sudo wrapper.

## Verification Review

`docs/test-report.md` provides sufficient evidence for this change:

- Targeted Nix eval confirms command presence and target/service relationships.
- Generated script builds and passes `bash -n`.
- Axiom top-level system build dry-run evaluates successfully.

Runtime target isolation and power measurements are appropriately deferred to live deployment on `axiom`.

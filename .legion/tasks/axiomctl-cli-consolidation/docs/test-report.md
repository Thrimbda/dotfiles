# Test Report: Axiomctl CLI Consolidation

## Summary

Result: PASS.

The validation focused on the claims in `plan.md`: the package is now exposed as `.#axiomctl`, the binary help reflects the renamed command and bounded command surface, Axiom installs `axiomctl` instead of `axiom-mode`, existing `axiom-cli.target` relationships remain intact, current-truth docs no longer point at the stale package name, and the final diff has no whitespace errors.

## Commands

### Rust formatting

Command:

```sh
nix shell nixpkgs#rustfmt -c rustfmt --check packages/axiomctl/src/main.rs
```

Result: PASS.

Evidence: `rustfmt --check` exited successfully after formatting the file once. Nix printed a non-fatal readonly eval-cache warning from `/home/c1/.cache/nix/eval-cache-v6/...sqlite`; the command still completed successfully.

### Package build

Command:

```sh
nix build --impure --no-link --print-out-paths .#axiomctl
```

Result: PASS.

Evidence:

```text
/nix/store/v8qrk9pvx27wyh50q2cg504ps8pn02y9-axiomctl-0.1.0
```

Note: the first build attempt failed because the new `packages/axiomctl` directory was untracked, so the Git-backed flake source did not expose `.#axiomctl`. `git add -N packages/axiomctl` made the new package visible for validation; the final commit will stage the package normally.

### Help output

Command:

```sh
pkg=$(nix build --impure --no-link --print-out-paths .#axiomctl) && "$pkg/bin/axiomctl" --help && "$pkg/bin/axiomctl" mode --help
```

Result: PASS.

Evidence excerpt:

```text
Usage: axiomctl COMMAND [ARGS]

Commands:
  mode [cli|desktop|status]  Manage the persistent Axiom systemd target.
  cli                        Alias for `mode cli`.
  desktop                    Alias for `mode desktop`.
  status                     Alias for `mode status`.
  reload                     Trigger the reviewed Axiom reload hook path.
Usage: axiomctl mode {cli|desktop|status}
```

### Axiom host wiring and target semantics

Command:

```sh
nix eval --impure --json --expr 'let c = (builtins.getFlake (toString ./.)).nixosConfigurations.axiom.config; hasAxiomctl = p: builtins.match ".*axiomctl.*" (p.name or "") != null; hasAxiomMode = p: builtins.match ".*axiom-mode.*" (p.name or "") != null; in { hasAxiomctl = builtins.any hasAxiomctl c.environment.systemPackages; axiomctlPackages = map (p: p.name or "") (builtins.filter hasAxiomctl c.environment.systemPackages); hasAxiomMode = builtins.any hasAxiomMode c.environment.systemPackages; axiomCli = { after = c.systemd.targets.axiom-cli.after or []; requires = c.systemd.targets.axiom-cli.requires or []; wants = c.systemd.targets.axiom-cli.wants or []; conflicts = c.systemd.targets.axiom-cli.conflicts or []; allowIsolate = c.systemd.targets.axiom-cli.unitConfig.AllowIsolate or null; }; keyWantedBy = { greetd = c.systemd.services.greetd.wantedBy or []; sshd = c.systemd.services.sshd.wantedBy or []; autossh = c.systemd.services.autossh-reverse-ssh.wantedBy or []; cloudflared = c.systemd.services.cloudflared.wantedBy or []; opencode = c.systemd.services.opencode-server.wantedBy or []; }; }'
```

Result: PASS.

Evidence:

```json
{"axiomCli":{"after":["multi-user.target"],"allowIsolate":true,"conflicts":["graphical.target"],"requires":["multi-user.target"],"wants":["getty@tty1.service"]},"axiomctlPackages":["axiomctl-0.1.0"],"hasAxiomMode":false,"hasAxiomctl":true,"keyWantedBy":{"autossh":["multi-user.target"],"cloudflared":["multi-user.target"],"greetd":["graphical.target"],"opencode":["multi-user.target"],"sshd":["multi-user.target"]}}
```

### Axiom toplevel integration dry-run

Command:

```sh
nix build --impure --dry-run .#nixosConfigurations.axiom.config.system.build.toplevel
```

Result: PASS.

Evidence: dry-run completed and listed the expected `axiomctl-0.1.0.drv` in the closure to be built, alongside unchanged Axiom system derivations.

### Stale current-reference check

Command:

```sh
test -z "$(rg -n 'packages/axiom-mode|#axiom-mode|AXIOM_MODE|writeShellScriptBin\s+"axiom-mode"|pkgs\.callPackage ../../packages/axiom-mode' hosts packages .legion/wiki/decisions.md .legion/wiki/patterns.md .legion/wiki/maintenance.md hosts/axiom/README.org)"
```

Result: PASS.

Evidence: command produced no output and exited successfully. Historical raw task docs were intentionally not included in this current-reference check.

### Diff whitespace check

Command:

```sh
git diff --check
```

Result: PASS.

Evidence: no output.

## Skipped

- Live `axiomctl mode cli` / `axiomctl mode desktop` were not run because they would change the active systemd target on the current machine.
- Live `axiomctl reload` was not run because it targets the active graphical session hook path and should be smoke-tested after deployment on Axiom.

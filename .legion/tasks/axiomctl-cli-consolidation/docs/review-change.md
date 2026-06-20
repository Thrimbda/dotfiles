# Review Change: Axiomctl CLI Consolidation

## Verdict

PASS.

No blocking findings.

## Scope Review

- In scope: `packages/axiom-mode` is renamed into `packages/axiomctl`, the Cargo/Nix metadata and binary help text now use `axiomctl`, and `hosts/axiom/default.nix` installs the renamed package.
- In scope: the old mode switching behavior remains under `axiomctl mode cli`, `axiomctl mode desktop`, and `axiomctl mode status`, with top-level `cli` / `desktop` / `status` aliases preserving the common previous workflow.
- In scope: `axiomctl reload` is a narrow fixed-argv bridge to the existing reviewed `hey reload` path.
- In scope: current README and wiki truth were updated away from `axiom-mode` / `packages/axiom-mode`.
- Out of scope avoided: no Rofi commands were ported, no broad `hey sync` / `pull` / `gc` / profile workflows were rewritten, and no Caelestia-owned desktop controls were replaced.

## Correctness Review

- The parser keeps the command surface small and deterministic. `axiomctl mode` without an argument defaults to status, matching the prior no-argument behavior of `axiom-mode`.
- The privileged mode paths still use fixed target constants: `axiom-cli.target` and `graphical.target`.
- `ensure_root` re-execs the current binary through `/run/wrappers/bin/sudo` and preserves the original argv, matching the previous Rust implementation's privilege model.
- The host injects `${hey.binDir}/hey` into the package for `axiomctl reload`, so the deployed Axiom binary does not rely on an interactive shell PATH for that bridge.
- The standalone flake package remains buildable as `.#axiomctl`; outside the Axiom host-specific callPackage, the reload bridge defaults to `hey`, which is acceptable for the exported package build and is not used as proof of deployed host behavior.

## Security Lens

Security lens applied because this change touches privileged systemd target switching and command execution.

- PASS: user-controlled input does not become a systemd target name. Mode values are parsed into fixed enum branches only.
- PASS: `axiomctl reload` does not pass user input to `hey` and does not invoke a shell; it runs fixed argv `["reload"]` against the injected binary path.
- PASS: no secrets, tokens, auth policy, broad sudo rules, or polkit grants are changed.

## Verification Evidence

Validation evidence is recorded in `.legion/tasks/axiomctl-cli-consolidation/docs/test-report.md`:

- Rust formatting: PASS.
- `nix build --impure --no-link --print-out-paths .#axiomctl`: PASS.
- Built binary help output: PASS.
- Axiom host package/target eval: PASS, with `hasAxiomctl=true`, `hasAxiomMode=false`, and unchanged `axiom-cli.target` relationships.
- Axiom toplevel dry-run: PASS.
- Current-reference stale grep: PASS.
- `git diff --check`: PASS.

## Residual Risk

- Live `axiomctl mode cli`, `axiomctl mode desktop`, and `axiomctl reload` were intentionally not executed in this environment because they affect the active system target or graphical reload path. They remain post-deploy Axiom smoke checks.

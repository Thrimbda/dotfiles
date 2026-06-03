# Test Report

## Summary

- Result: PASS
- Scope: targeted validation for the VSCode/Data Wrangler Jupyter extension fix on the Axiom NixOS configuration.
- Changed file under test: `modules/editors/vscode.nix`

## Commands

### Parse Modified Module

- Command: `nix-instantiate --parse modules/editors/vscode.nix >/dev/null`
- Result: PASS
- Why: catches Nix syntax errors in the directly modified module before broader evaluation.

### Evaluate Edited Wrapper Expression

- Command: `nix eval --raw --impure --expr 'let flake = builtins.getFlake (toString ./.); pkgs = import flake.inputs.nixpkgs { system = builtins.currentSystem; config.allowUnfree = true; }; in (pkgs.vscode-with-extensions.override { vscode = pkgs.vscode.fhs; vscodeExtensions = with pkgs.vscode-extensions; [ ms-toolsai.datawrangler ms-toolsai.jupyter ms-toolsai.jupyter-keymap ms-toolsai.jupyter-renderers ms-toolsai.vscode-jupyter-cell-tags ms-toolsai.vscode-jupyter-slideshow ]; }).name'`
- Result: PASS, returned `code-with-extensions-1.106.2`
- Why: confirms the pinned nixpkgs attribute names and wrapper override are valid.

### Evaluate Axiom User Package Selection

- Command: `NIXPKGS_ALLOW_UNFREE=1 nix eval --impure --expr 'let flake = builtins.getFlake (toString ./.); cfg = flake.nixosConfigurations.axiom.config; names = map (p: p.name or "") cfg.users.users.${cfg.user.name}.packages; in builtins.toJSON (builtins.filter (name: name == "code-with-extensions-1.106.2") names)'`
- Result: PASS, returned `["code-with-extensions-1.106.2"]`
- Why: proves the changed module is active in the Axiom host configuration and replaces the plain VSCode package in the configured user packages.
- Note: Nix emitted the existing repository warning about `specialArgs.pkgs` causing `nixpkgs.config`/`nixpkgs.overlays` options to be ignored. The command still evaluated successfully and the warning is unrelated to this VSCode extension change.

### Build Axiom VSCode Wrapper Package

- Command: `NIXPKGS_ALLOW_UNFREE=1 nix build --no-link --impure --expr 'let flake = builtins.getFlake (toString ./.); cfg = flake.nixosConfigurations.axiom.config; matches = builtins.filter (p: (p.name or "") == "code-with-extensions-1.106.2") cfg.users.users.${cfg.user.name}.packages; in builtins.elemAt matches 0'`
- Result: PASS
- Why: proves the generated VSCode wrapper and extension build environment can be built from the Axiom configuration.

### Inspect Generated Extension Directory

- Command: `NIXPKGS_ALLOW_UNFREE=1 nix build --print-out-paths --no-link --impure --expr 'let flake = builtins.getFlake (toString ./.); cfg = flake.nixosConfigurations.axiom.config; matches = builtins.filter (p: (p.name or "") == "code-with-extensions-1.106.2") cfg.users.users.${cfg.user.name}.packages; in builtins.elemAt matches 0'`
- Result: PASS, output path `/nix/store/l8358sid7lxh40kr2j1wic8wd3f7a427-code-with-extensions-1.106.2`
- Evidence: wrapper script passes `--extensions-dir /nix/store/kqha7dw44zppx7hhh5pf1zwd9s708xj0-vscode-extensions/share/vscode/extensions`.
- Evidence: generated extension directory contains `ms-toolsai.datawrangler/`, `ms-toolsai.jupyter/`, `ms-toolsai.jupyter-keymap/`, `ms-toolsai.jupyter-renderers/`, `ms-toolsai.vscode-jupyter-cell-tags/`, and `ms-toolsai.vscode-jupyter-slideshow/`.
- Why: directly verifies the runtime-visible extension directory contains the extension Data Wrangler requests plus Jupyter's extension pack members.

### Diff Whitespace Check

- Command: `git diff --check`
- Result: PASS
- Why: catches whitespace errors across the pending task diff.

## Skipped

- Interactive VSCode/Data Wrangler launch was not run from this session. The strongest available non-interactive proof is the Axiom configuration evaluation plus successful build and inspection of the generated VSCode extension directory.

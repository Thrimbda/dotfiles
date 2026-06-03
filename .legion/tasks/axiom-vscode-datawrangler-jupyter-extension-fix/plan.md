# Axiom VSCode Data Wrangler Jupyter Extension Fix

## Task Identity

- Name: Axiom VSCode Data Wrangler Jupyter Extension Fix
- Task ID: `axiom-vscode-datawrangler-jupyter-extension-fix`
- Trigger: user reported VSCode Data Wrangler fails to launch a kernel because it cannot get the Jupyter extension.
- Base ref: `origin/master`

## Goal

Make VSCode Data Wrangler launch its Jupyter-backed kernel on Axiom by persistently declaring the required VSCode extension dependencies in the dotfiles/Nix configuration.

## Problem

Data Wrangler is installed and loads far enough to run its launch path, but it aborts with `Could not get Jupyter extension`. The current repository VSCode module only installs `vscode.fhs` and does not declare Jupyter-related VSCode extensions, so the environment can be rebuilt without the extension Data Wrangler expects.

## Acceptance Criteria

- The repository VSCode configuration declares the Jupyter extension required by Data Wrangler.
- Any directly necessary VSCode extension dependencies are declared in the same persistent configuration path.
- Repository-local formatting or evaluation checks for the changed Nix configuration pass, or the reason they cannot be run is recorded.
- Evidence records the reported runtime failure, the persistent configuration fix, and the validation result.

## Scope

- Inspect the existing VSCode module and surrounding Nix conventions.
- Add the smallest persistent VSCode extension declaration needed for Data Wrangler to access the Jupyter extension.
- Run targeted validation for the Nix configuration and record the result.

## Non-Goals

- Do not modify Data Wrangler extension source code.
- Do not redesign the editor module or global development environment.
- Do not install ad-hoc user extensions as the primary fix.
- Do not add unrelated Python, notebook, or language-server tooling unless the extension dependency requires it.

## Assumptions

- The live error accurately identifies a missing or unavailable VSCode Jupyter extension as the startup blocker.
- Persisting VSCode extensions in the dotfiles module is preferable to manual one-off installation.
- The configured `vscode.fhs` package can be combined with a VSCode extension set in this repository's Nix conventions.

## Constraints

- Use the Legion workflow and worktree/PR lifecycle for repository changes.
- Keep the fix minimal and preserve unrelated worktree changes.
- Prefer repository-managed configuration over live-home mutation.

## Risks

- The repository may not already use `vscode-with-extensions`, requiring a small packaging adjustment.
- Extension attribute names may differ across nixpkgs revisions.
- The local tool session may not be able to fully launch VSCode/Data Wrangler, so validation may rely on Nix evaluation plus extension presence checks.

## Design Summary

- Treat the failure as an unavailable Jupyter VSCode extension dependency, not a Data Wrangler code defect.
- Make the VSCode module build a persistent VSCode package/profile that includes Data Wrangler's required Jupyter extension.
- Validate the Nix expression and, where feasible, the resolved extension set rather than relying only on source inspection.

## Phases

- Brainstorm: materialize this narrow persistent-fix contract.
- Engineer: inspect VSCode/Nix conventions and patch the minimal extension declaration.
- Verify: run targeted Nix validation and capture evidence.
- Review/report/wiki: assess readiness, generate handoff docs, and write back durable Legion knowledge.

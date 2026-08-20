# Log: Dotfiles Prune and Host Framework Extraction

## 2026-08-20

- Confirmed that the user intended all previous raw task directories to be pruned, retaining only this task and the wiki layer.
- Approved the two-layer design: shared modules own proven mechanics; host-local modules own concrete topology and policy.
- Pruned old task directories, deleted the stale root README and recorded the one-off package module inventory.
- Reduced `hosts/axiom/default.nix` from 1986 to 178 lines and `hosts/acorn/default.nix` from 273 to 45 lines.
- Added shared Auth Mini Gateway process mechanics and Cloudflare DNS-01 certificate expansion without abstracting Nginx/FRP topology.
- Candidate Axiom, Acorn and Charlie configurations evaluate. Focused baseline/candidate comparisons are equal except for expected Git-source store paths on age files.
- Acorn candidate explicitly disables the shared Hypridle default; this fixes the pre-existing server evaluation assertion without enabling or removing a runtime desktop service.
- Rebased onto `origin/master` at `05ddebd8`; preserved the newly landed Qwen service in `hosts/axiom/modules/qwen.nix`, retained its wiki summary and pruned its closed raw task directory.
- Focused comparison exposed package merge ordering introduced by the split. A private RustDesk package helper and manifest import ordering restore the exact Axiom user/system package order and Caelestia PATH semantics.
- Re-ran verification against the latest baseline: Axiom, Acorn and Charlie evaluate; focused snapshots pass; Axiom dry-run plans 28 derivations; full flake check retains only the existing `apps.install` schema failure.
- Rebased again onto `origin/master` at `7945b0bd` after the Qwen 128K update landed; preserved `--ctx-size 131072` and the new wiki current-truth while pruning the newly closed raw task.
- Tightened verification commands to use the explicit `origin/master...HEAD` range so the committed branch delta, rather than only the worktree, proves scope invariants.
- When `axiom-qwen38-q6-switcher` landed as an active task, the user chose to preserve that raw task until closeout rather than applying the closed-task prune rule to in-flight evidence.
- Rebased onto `origin/master` at `dc87546e`; moved the Q4/Q6 selection link, bounded `qwen-model` controller and service preflight into `hosts/axiom/modules/qwen.nix` while preserving 128K context and system package order.
- Rebased onto `origin/master` at `532b9aa8`; preserved the Qwen controller's `/run/wrappers/bin/sudo` fix and removed the ineffective store `sudo` runtime input.
- Re-ran verification against `532b9aa8`: all 22 changed Nix files parse; Axiom, Acorn and Charlie candidate evaluations pass; normalized behavior snapshots are equal except for Acorn's intentional inert Hypridle disable; both Axiom dry-runs plan 28 derivations; and the full flake check retains the same baseline schema failure.
- Rebased onto `origin/master` at `07816e00`, preserving the Axiom warning migrations in their new owning modules. Upstream completed the Qwen switcher and warning-migration tasks, so their raw directories were pruned while their wiki summaries and merged code were retained.
- Re-ran final verification against `07816e00`: the one-task whitelist and 142-file wiki baseline pass; all 22 changed Nix files parse; candidate host evaluations and normalized snapshots pass; both Axiom dry-runs plan 28 derivations; and candidate/baseline flake checks retain the identical existing `apps.install` schema failure.
- Final correctness, scope and security review passed with no blockers. Generated the implementation walkthrough and PR body, and wrote the durable task summary plus package-ordering guidance into the wiki.

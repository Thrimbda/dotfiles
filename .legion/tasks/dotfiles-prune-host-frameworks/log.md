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

# Log: Dotfiles Prune and Host Framework Extraction

## 2026-08-20

- Confirmed that the user intended all previous raw task directories to be pruned, retaining only this task and the wiki layer.
- Approved the two-layer design: shared modules own proven mechanics; host-local modules own concrete topology and policy.
- Pruned old task directories, deleted the stale root README and recorded the one-off package module inventory.
- Reduced `hosts/axiom/default.nix` from 1986 to 178 lines and `hosts/acorn/default.nix` from 273 to 45 lines.
- Added shared Auth Mini Gateway process mechanics and Cloudflare DNS-01 certificate expansion without abstracting Nginx/FRP topology.
- Candidate Axiom, Acorn and Charlie configurations evaluate. Focused baseline/candidate comparisons are equal except for expected Git-source store paths on age files.
- Acorn candidate explicitly disables the shared Hypridle default; this fixes the pre-existing server evaluation assertion without enabling or removing a runtime desktop service.

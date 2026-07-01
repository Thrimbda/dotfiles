# Log

## 2026-07-01

- User clarified that `aliyun-acorn` must only deploy `vault.0xc1.wang`; `vault.0xc1.space` must not be kept as compatibility routing on this host.
- Created worktree `.worktrees/aliyun-acorn-vault-wang-only` from `origin/master` at `956dc991`.
- Removed `vault.0xc1.space` from `stagedTlsDomains` and from `services.nginx.virtualHosts` under `hosts/aliyun-acorn`.
- Verified `aliyun-acorn` evaluated nginx vhosts are `status-axiom.0xc1.wang` and `vault.0xc1.wang` only.
- Verified `hosts/aliyun-acorn` has no remaining `vault.0xc1.space` references.

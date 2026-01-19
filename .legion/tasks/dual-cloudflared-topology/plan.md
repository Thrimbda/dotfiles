# dual-cloudflared-topology

## 目标

改造 Zero Trust 方案，让 atlas 与 charlie 各自运行 cloudflared，去除多级依赖并更新相关配置与文档。


## 要点

- 每台主机独立 tunnel 与凭证，避免单点依赖
- WARP 私有路由仍覆盖 192.168.50.0/24，但由每台主机各自注册
- 浏览器 SSH 分别指向各自主机的 tunnel/hostname
- 文档同步更新步骤、测试、风险说明


## 范围

- modules/services/cloudflared.nix
- hosts/atlas/default.nix
- hosts/charlie/default.nix
- docs/cloudflare-zero-trust.md
- docs/charlie-macos-ssh-config.md

## 阶段概览

1. **设计** - 1 个任务
2. **实现** - 1 个任务
3. **文档** - 1 个任务

---

*创建于: 2026-01-19 | 最后更新: 2026-01-19*

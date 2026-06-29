# Aliyun Acorn Nix Cache Mirror

## 目标

让 `aliyun-acorn` 在阿里云 ECS 上优先使用国内 Nix/NixOS binary cache mirrors，降低 `nixos-rebuild`、镜像构建和日常 Nix 命令拉取 store paths 时访问海外 cache 的延迟；同时为该主机打开 TCP 2222，并保留官方 cache 信任链与 fallback。

## 问题陈述

`aliyun-acorn` 运行在阿里云环境，访问 `cache.nixos.org` 和海外 cache 容易慢或不稳定。当前需求是只对该 host 的 Nix/NixOS substituters 排序做本地化优化，而不是改变全仓库 flake inputs、其他 hosts 或 Darwin 配置。同时，`aliyun-acorn` 需要在 NixOS 防火墙中允许 TCP 2222，避免部署后该端口被默认防火墙拦截。

## 验收标准

- [ ] `aliyun-acorn` 的最终 Nix settings 优先使用这些 domestic substituters，并按此顺序排在官方 cache 之前：`https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store`、`https://mirrors.ustc.edu.cn/nix-channels/store`、`https://mirror.sjtu.edu.cn/nix-channels/store`。
- [ ] `https://cache.nixos.org/` 作为 fallback 保留；若 repo 已经通过共享模块提供 Cachix 或其他 substituters，不被本任务无意覆盖。
- [ ] 官方 `cache.nixos.org-1:6NCHdD59X431o0gW...` trusted public key 被保留或显式添加，且不新增不必要的第三方 signing key。
- [ ] `aliyun-acorn` NixOS 防火墙允许 TCP 2222。
- [ ] 改动 scope 限定在 `hosts/aliyun-acorn` 相关配置和本任务 Legion 证据内，不全局修改 unrelated hosts、Darwin 配置或 `flake.nix` inputs。
- [ ] 验证至少覆盖 `nix eval` 或 `nix build --dry-run` 针对 `./hosts/aliyun-acorn/image#aliyun-image`。

## 假设 / 约束 / 风险

- **假设**: TUNA、USTC 和 SJTU 的 `nix-channels/store` mirrors 在阿里云网络环境下比官方 cache 更稳定或更快；如果某个 mirror 缺少 nar，后续 fallback 仍能接管。
- **假设**: 这些 mirrors 提供的是官方 NixOS cache 内容，继续信任官方 `cache.nixos.org` public key 即可；不新增第三方 signing key。
- **约束**: 只对 `aliyun-acorn` 生效，不改变其他 hosts、darwin 配置或全局 flake input 来源。
- **约束**: 不解决所有 GitHub flake input 下载问题；如 `flake.lock` 首次拉取仍慢，后续应通过代理或单独 input mirror 策略处理。
- **风险**: 国内动态 cache 可能偶发缺少某些 nar；保留官方 cache 和 repo 既有 substituters fallback 以降低失败概率。
- **风险**: 如果 `substituters` 合并方式错误，可能覆盖既有 Cachix 或官方 cache；验证必须检查最终列表顺序。
- **风险**: 防火墙端口放行扩大暴露面；本任务只放行用户要求的 TCP 2222，不新增服务或认证策略。

## 要点

- **推荐方案**: 先沿用 `aliyun-acorn` 现有 host/image 配置模式；若没有更合适的本地 convention，则在 host-level NixOS module 中用 NixOS merge semantics prepend domestic substituters，并追加/保留官方 trusted public key。
- **推荐方案**: 在同一 host scope 下配置 `networking.firewall.allowedTCPPorts` 包含 `2222`。
- **回滚方式**: 删除本任务新增的 host-level Nix settings 和 firewall 端口配置，或 `git revert` 本 PR。
- **验证策略**: 使用 `nix eval` 检查最终 substituter 列表、trusted keys、firewall ports，并对 `./hosts/aliyun-acorn/image#aliyun-image` 做求值或 dry-run build 验证。

## Non-goals

- 不改 `flake.nix` / `flake.lock` 的 GitHub 或 nixpkgs input 来源。
- 不新增全局 Nix cache mirror，不影响其他 NixOS 或 Darwin hosts。
- 不引入私有 binary cache、Cachix token、代理配置或新的 trusted public key。
- 不在本任务中 benchmark 多个国内镜像的实际吞吐。
- 不新增或修改 TCP 2222 背后的服务进程、认证方式、反向代理或安全组配置。

## 范围

- `hosts/aliyun-acorn/**` - 为该 host/image 配置国内 Nix binary cache mirrors、官方 cache fallback/trusted key 和 TCP 2222 防火墙放行。
- `.legion/tasks/aliyun-acorn-nix-cache-mirror/` - 保存 contract、design-lite、验证、review、walkthrough 和 PR 证据。

## 设计索引 (Design Index)

> **Design Source of Truth**: `.legion/tasks/aliyun-acorn-nix-cache-mirror/docs/rfc.md`

**摘要**:
- 核心流程: host-scoped NixOS settings prepend TUNA、USTC、SJTU mirrors，保留官方 cache fallback 和 trusted key，并在同一 scope 放行 firewall TCP 2222。
- 验证策略: `nix eval` 最终 substituter、trusted key 和 firewall port 配置，并对 `./hosts/aliyun-acorn/image#aliyun-image` 执行求值或 dry-run build。

## 阶段概览

1. **Contract** - 刷新稳定任务契约，覆盖三组国内 mirrors、官方 fallback/key、TCP 2222 和 image 验证目标。
2. **Implementation** - 在 worktree 中为 `aliyun-acorn` 添加 host-scoped Nix settings 和 firewall port。
3. **Verification** - 验证最终 cache/key/firewall 配置，并验证 `./hosts/aliyun-acorn/image#aliyun-image`。
4. **Review** - 检查范围、回滚和残余风险。
5. **Delivery** - 生成 walkthrough、PR body 和 wiki writeback。

---

*创建于: 2026-06-20 | 最后更新: 2026-06-29*

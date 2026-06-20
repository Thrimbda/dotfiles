# Aliyun Acorn Nix Cache Mirror

## 目标

让 `aliyun-acorn` 在阿里云 ECS 上优先使用国内 Nix binary cache，降低 `nixos-rebuild` 和日常 Nix 命令拉取 store paths 时访问 `cache.nixos.org` 的延迟，同时保留现有 Cachix 与官方 cache 作为 fallback。

## 问题陈述

`aliyun-acorn` 运行在阿里云环境，访问 `cache.nixos.org` 和海外 cache 容易慢或不稳定。当前全局 NixOS 配置已经提供 nix-community 与 Hyprland Cachix，并由 NixOS 自动补充官方 cache，但没有针对阿里云主机的国内 mirror 优先级。直接改全局配置会影响其他机器；改 flake inputs 又会扩大到 GitHub/nixpkgs 来源策略，不适合这次小范围 cache 优化。

## 验收标准

- [ ] `aliyun-acorn` 的最终 `nix.settings.substituters` 以 `https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store` 开头。
- [ ] 现有 `https://nix-community.cachix.org`、`https://hyprland.cachix.org` 和 `https://cache.nixos.org/` 仍保留为 fallback。
- [ ] 改动只影响 `hosts/aliyun-acorn/default.nix` 和本任务的 Legion 证据，不修改全局 `flake.nix` inputs。
- [ ] `.#nixosConfigurations.aliyun-acorn` 能正常求值到 `system.build.toplevel.drvPath`。
- [ ] 记录临时切换 cache 的命令说明，便于其他机器一次性使用 mirror 而不落盘配置。

## 假设 / 约束 / 风险

- **假设**: TUNA `nix-channels/store` 在阿里云网络环境下比官方 cache 更稳定或更快。
- **假设**: 该 mirror 使用 Nix 官方 cache 签名，继续信任现有 `cache.nixos.org` public key 即可；不新增第三方 signing key。
- **约束**: 只对 `aliyun-acorn` 生效，不改变其他 hosts、darwin 配置或全局 flake input 来源。
- **约束**: 不解决所有 GitHub flake input 下载问题；如 `flake.lock` 首次拉取仍慢，后续应通过代理或单独 input mirror 策略处理。
- **风险**: 国内动态 cache 可能偶发缺少某些 nar；保留 Cachix 和官方 cache fallback 以降低失败概率。
- **风险**: 如果 `substituters` 合并方式错误，可能覆盖现有 Cachix；验证必须检查最终列表顺序。

## 要点

- **推荐方案**: 在 `hosts/aliyun-acorn/default.nix` 中用 `lib.mkBefore` prepend TUNA substituter。
- **回滚方式**: 删除该 host-level `nix.settings.substituters` 块，或 `git revert` 本 PR。
- **验证策略**: 使用 `nix eval` 检查最终 substituter 列表和 toplevel drv 求值。

## Non-goals

- 不改 `flake.nix` / `flake.lock` 的 GitHub 或 nixpkgs input 来源。
- 不新增全局 Nix cache mirror，不影响其他 NixOS 或 Darwin hosts。
- 不引入私有 binary cache、Cachix token、代理配置或新的 trusted public key。
- 不在本任务中 benchmark 多个国内镜像的实际吞吐。

## 范围

- `hosts/aliyun-acorn/default.nix` - 为该 host prepend 国内 Nix binary cache mirror。
- `.legion/tasks/aliyun-acorn-nix-cache-mirror/` - 保存 contract、design-lite、验证、review、walkthrough 和 PR 证据。

## 设计索引 (Design Index)

> **Design Source of Truth**: `.legion/tasks/aliyun-acorn-nix-cache-mirror/docs/rfc.md`

**摘要**:
- 核心流程: host-level `nix.settings.substituters = lib.mkBefore [ TUNA ]`，让 NixOS 模块合并后国内 mirror 排在已有 Cachix 和官方 cache 前面。
- 验证策略: `nix eval` 最终 substituter 列表并确认 `aliyun-acorn` toplevel derivation 可求值。

## 阶段概览

1. **Contract** - 创建稳定任务契约和 design-lite。
2. **Implementation** - 在 worktree 中为 `aliyun-acorn` 添加 host-level substituter。
3. **Verification** - 验证最终 cache 顺序和 NixOS 配置求值。
4. **Review** - 检查范围、回滚和残余风险。
5. **Delivery** - 生成 walkthrough、PR body 和 wiki writeback。

---

*创建于: 2026-06-20 | 最后更新: 2026-06-20*

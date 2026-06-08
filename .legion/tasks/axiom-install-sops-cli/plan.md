# Axiom Install Sops CLI

## 目标

在 `axiom` 主机的声明式配置中安装 `sops` CLI，让用户 `c1` 在该工作站上可以直接使用 `sops` 命令。

## 问题陈述

`axiom` 目前没有声明式安装 `sops`。用户需要在该主机上使用 `sops` CLI，但本次需求只要求命令可用，不要求迁移或引入新的 secrets 管理架构。仓库现有 secrets 方案包含 agenix，因此把 `sops-nix` 顺手引入会扩大 scope，并把一次包安装变成 secrets 架构设计任务。

## 验收标准

- [ ] `axiom` 的声明式配置安装 `pkgs.sops` 或等价的 nixpkgs CLI package。
- [ ] 变更保持 host-local，不影响其他主机的包集合。
- [ ] 不引入 `sops-nix`、不迁移现有 agenix secrets、不改变 secrets 解密流程。
- [ ] 本地验证记录 `axiom` 配置可求值或可构建的证据；若受环境限制无法完整构建，记录阻塞原因。
- [ ] 不执行 live `nixos-rebuild switch`，实际部署由用户后续切换系统完成。

## 假设 / 约束 / 风险

- **假设**: 目标主机配置是 `hosts/axiom/default.nix`。
- **假设**: 用户选择“只装 CLI”，本次不配置 `sops-nix`。
- **约束**: 遵循 Legion workflow；实现阶段如果修改仓库文件，应走 `git-worktree-pr` envelope。
- **约束**: 保持最小改动，遵循现有 `axiom` host-local `user.packages` 模式。
- **风险**: 如果用户后续需要 NixOS secrets integration，单纯安装 CLI 不能替代 `sops-nix` 的 declarative secrets 管理能力。
- **风险**: 本地 Nix 验证可能受网络、缓存或当前机器权限限制；失败时需要把失败命令和原因写入验证报告。

## 要点

- **taskId**: `axiom-install-sops-cli`
- **推荐方向**: 把 `sops` 加入 `hosts/axiom/default.nix` 的 `user.packages`，与该主机已有 one-off user tooling 保持一致。
- **设计判断**: 不引入 `sops-nix`；是否采用 `sops-nix` 应作为独立任务评估 agenix 共存、迁移路径、密钥来源和回滚策略。
- **验证策略**: 优先执行针对 `axiom` 的 Nix eval/build 检查，避免 live switch。

## 范围

- `hosts/axiom/default.nix` - 添加 `sops` CLI 到 `axiom` 的声明式包集合。
- `.legion/tasks/axiom-install-sops-cli/**` - 记录任务契约、状态、验证、review、walkthrough 和交接证据。
- `.legion/wiki/**` - 收口时写入任务摘要或可复用结论。

## 非目标

- 不引入或配置 `sops-nix`。
- 不迁移、重加密或改写任何现有 secrets 文件。
- 不改变 agenix 模块、age identity、host key 或 secrets ownership。
- 不修改其他主机或全局模块的包集合。
- 不执行 `nixos-rebuild switch` 或其他会激活当前系统配置的命令。

## 设计索引 (Design Index)

> **Design Source of Truth**: 无需 RFC；本任务是低风险 host-local CLI 安装。若后续要引入 `sops-nix`，应另建中风险设计任务。

**摘要**:
- 使用现有 `axiom` host-local `user.packages` 模式安装 `pkgs.sops`。
- 保持 secrets 管理现状不变，避免把 CLI 可用性和 secrets 架构迁移耦合。
- 验证聚焦 Nix 配置求值/构建，不做 live system activation。

## 阶段概览

1. **Contract Materialization** - 创建并回读 Legion task contract。
2. **Implementation** - 在 `axiom` host-local package list 中加入 `sops`。
3. **Verification** - 验证 `axiom` 配置可求值或可构建，并记录结果。
4. **Review And Handoff** - 完成交付 review、walkthrough 和 wiki writeback。

---

*创建于: 2026-06-08 | 最后更新: 2026-06-08*

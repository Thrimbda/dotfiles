# Axiom Feishu Client

## 目标

让 axiom 的桌面用户环境通过 dotfiles 安装飞书客户端，重建后用户可以从系统应用环境启动飞书。

## 问题陈述

axiom 当前已经集中管理常用桌面应用，但没有飞书客户端；如果手动安装会绕过 dotfiles，后续重建或换机时不可复现。

## 验收标准

- [ ] axiom 配置启用一个最小的飞书安装路径。
- [ ] 飞书客户端包被纳入 axiom 的用户或桌面应用包集合。
- [ ] 不改变其他主机的桌面应用行为。
- [ ] 不管理飞书账号、缓存、聊天数据、代理或自启动策略。
- [ ] 针对 axiom 的聚焦 Nix 评估通过，或阻塞原因被记录。

## 假设 / 约束 / 风险

- **假设**: 用户说的飞书指大陆版 Feishu 客户端，而不是 Lark 国际版。
- **假设**: 安装飞书只要求包可用，不要求预配置登录态或组织策略。
- **假设**: 若 nixpkgs 暴露的包名不止一个，优先选择当前 flake 中能直接评估的稳定包名。
- **约束**: 遵循 Legion workflow 和 git-worktree-pr envelope。
- **约束**: 修改范围尽量小，优先复用现有 desktop apps 模块模式或 axiom 本地 package 列表。
- **约束**: 不要触碰 secrets、账号数据或其他主机配置。
- **风险**: Feishu/Electron 客户端运行时可能依赖上游二进制兼容性，Nix 评估不能完全覆盖登录和音视频功能。
- **风险**: 若包只在 unstable 中可用，需要明确锁定到现有 unstable 用法。

## 要点

- 推荐路径: 若仓库已有桌面应用模块模式，则新增极小 reusable module 并只在 axiom 启用；若包只需一次性加入，则保持在 axiom 本地 user.packages。
- 验证策略: 使用 nix eval 检查 axiom 最终包集合或 toplevel 评估，避免无关全量 rebuild。
- 边界: 本任务只安装客户端，不配置 Feishu 运行时数据。

## 范围

- hosts/axiom/default.nix - 启用或加入飞书安装入口。
- modules/desktop/apps - 仅当需要复用桌面应用模块时新增最小模块。
- .legion/tasks/axiom-feishu-client/** - 记录任务、验证、review、walkthrough 证据。
- .legion/wiki/** - 收口写回当前任务结论。

## 设计索引 (Design Index)

> **Design Source of Truth**: 低风险 design-lite：沿用现有桌面应用/用户包模式，不需要独立 RFC。

**摘要**:
- 核心流程: 先确认当前 flake 中飞书包可用，再以最小 Nix 配置把包纳入 axiom。
- 验证策略: 运行聚焦 Nix eval，确认包名和 axiom 配置可评估。

## 阶段概览

1. **契约** - 创建稳定 Legion task contract
2. **实现** - 定位 Feishu 包和 axiom 安装入口
3. **验证与交付** - 运行聚焦 Nix 验证

---

*创建于: 2026-05-11 | 最后更新: 2026-05-11*

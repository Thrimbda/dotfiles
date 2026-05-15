# Axiom Feishu Launcher Entry

## 目标

让 Feishu 出现在 axiom 的 Super+Space launcher/menu 中，并能从该入口启动。

## 问题陈述

上一轮只把 Feishu 加入 axiom 的 user.packages，保证包安装；但 Super+Space 实际打开的是当前桌面 launcher surface，用户反馈 Feishu 没有出现在菜单里，说明 package-only 安装不足以把它纳入 launcher 可发现入口。

## 验收标准

- [ ] Feishu 在 axiom 的 Super+Space launcher/menu 中有可见入口。
- [ ] 该入口使用固定、仓库管理的启动目标，不依赖用户手动创建 desktop entry。
- [ ] 保留 Feishu package-only 安装，不管理账号、缓存、代理、自启动或组织策略。
- [ ] 不改变其他主机的 launcher 行为。
- [ ] 聚焦 Nix/配置验证通过，或阻塞原因被记录。

## 假设 / 约束 / 风险

- **假设**: Super+Space 指 axiom 当前 Hyprland/Caelestia launcher 入口，而不是 Fuzzel direct fallback。
- **假设**: Feishu 上游包的 desktop entry 未被当前 launcher surface 自动采集，或者其可见性需要仓库侧补充。
- **假设**: 用户只要求菜单可见和可启动，不要求登录态或 live UI 验证。
- **约束**: 遵循 Legion workflow 和 git-worktree-pr envelope。
- **约束**: 修改范围保持在 axiom launcher/app 集成和任务证据内。
- **约束**: 不要触碰 secrets、账号数据、Feishu runtime state 或非 axiom 主机配置。
- **风险**: 当前环境无法证明真实 Wayland layer-shell 菜单渲染，只能通过生成配置、desktop entry 和 Nix eval 提供静态证据。
- **风险**: 如果 Feishu 包的启动命令或 desktop metadata 在上游包中变化，仓库侧补充入口可能需要后续维护。

## 要点

- 推荐路径: 定位 Super+Space 的实际 launcher/app 数据来源后，用最小仓库管理入口补齐 Feishu，而不是切换 launcher 架构。
- 验证策略: 检查生成的 launcher/desktop metadata 包含 Feishu，并评估 axiom 配置。
- 边界: 只解决 launcher 可发现性，不配置 Feishu runtime。

## 范围

- hosts/axiom/default.nix - 如需启用 axiom-specific launcher/app 配置。
- modules/desktop/caelestia.nix 或 modules/desktop/hyprland.nix - 如 Super+Space launcher 入口或 app list 需要仓库侧补充。
- modules/desktop/apps 或 home config files - 仅当需要新增 Feishu desktop entry / launcher metadata 时修改。
- .legion/tasks/axiom-feishu-launcher-entry/** - 任务证据。
- .legion/wiki/** - closing writeback。

## 设计索引 (Design Index)

> **Design Source of Truth**: 低风险 design-lite：沿用现有 Super+Space launcher 架构，只补 Feishu 可发现入口。

**摘要**:
- 核心流程: 找到 Super+Space launcher 的 app discovery path，确认 Feishu 缺失原因，然后添加最小的仓库管理入口。
- 验证策略: 静态检查生成配置/desktop entry，并运行 axiom 聚焦 Nix eval。

## 阶段概览

1. **契约** - 创建稳定 Legion task contract
2. **实现** - 定位 Super+Space launcher app discovery path
3. **验证与交付** - 运行聚焦配置验证

---

*创建于: 2026-05-15 | 最后更新: 2026-05-15*

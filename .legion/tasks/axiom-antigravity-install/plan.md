# Axiom Antigravity Install

## 目标

在 axiom 的 NixOS 配置中安装 Google Antigravity，使用户能通过系统环境启动 Antigravity IDE。

## 问题陈述

用户希望在 axiom 上使用 Google Antigravity。当前 dotfiles 已为 axiom 管理桌面、开发工具与用户包，但尚未包含 Antigravity；NixOS 需要通过仓库配置安装，不能依赖临时下载或传统 deb/rpm 安装流程。

## 验收标准

- [ ] axiom 配置包含 Google Antigravity 的 Nix package，并在 rebuild 后可进入用户环境。
- [ ] 使用用户确认的 `pkgs.unstable.antigravity-fhs` 方案，利用既有 `nixpkgs-unstable` 和 `allowUnfree` 配置。
- [ ] 不接入新的第三方 flake，不引入手工下载包或非声明式安装步骤。
- [ ] 不配置 Antigravity 账号、扩展、同步、AI 凭据或运行态数据。
- [ ] 聚焦 Nix 验证通过，或阻塞原因被记录。

## 假设 / 约束 / 风险

- **假设**: axiom 使用当前仓库的 `hosts/axiom/default.nix` 生成系统配置。
- **假设**: `nixpkgs-unstable` 暴露 `antigravity-fhs`，并且该 FHS 变体比稳定通道包更适合 IDE 上游二进制和扩展兼容性。
- **约束**: 遵循 Legion workflow；稳定 contract 后使用 git-worktree-pr envelope 执行仓库修改。
- **约束**: 仅修改 axiom 安装配置与任务证据，不扩大到其他主机或通用编辑器模块。
- **约束**: 保持声明式 Nix 安装，不使用临时 `nix profile install` 作为最终状态。
- **风险**: Antigravity 是 unfree 上游二进制，构建/下载可能受网络、缓存或上游发布变动影响。
- **风险**: FHS 包能静态通过 eval/build，不等于实际 GUI 登录或扩展运行已经完成验证。

## 要点

- **推荐路径**: 在 axiom 的 `user.packages` 中加入 `pkgs.unstable.antigravity-fhs`，沿用当前主机级 app 安装风格。
- **验证策略**: 优先做聚焦 Nix eval/build，确认 axiom 配置能解析并包含目标包；必要时记录网络或 substituter 阻塞。
- **边界**: 只保证 package 安装进入系统环境，不承诺 GUI 登录态、账号配置、扩展市场或模型权限。
- **Task ID**: `axiom-antigravity-install`。

## 范围

- `hosts/axiom/default.nix` - axiom-specific user package 列表。
- `.legion/tasks/axiom-antigravity-install/**` - 任务契约、日志和验证/交付证据。
- `.legion/wiki/**` - closing writeback。

## 非目标

- 不新增或替换全局 editor/app module。
- 不把 Antigravity 安装到其他主机。
- 不接入 `jacopone/antigravity-nix` 或其他第三方 flake。
- 不管理 Antigravity 用户数据、token、登录、代理或扩展。

## 设计索引 (Design Index)

> **Design Source of Truth**: 低风险 design-lite：使用既有 `pkgs.unstable` overlay 中的 FHS 包，最小化 axiom 主机配置变更。

**摘要**:
- 核心流程: 在 axiom 主机的声明式用户包列表中加入 `pkgs.unstable.antigravity-fhs`，避免手工安装和额外 flake 输入。
- 验证策略: 用 Nix eval/build 检查 axiom 配置解析、目标 package 可用性，以及改动 diff 质量。

## 阶段概览

1. **契约** - 创建稳定 Legion task contract。
2. **实现** - 在隔离 worktree 中添加 axiom Antigravity package。
3. **验证与交付** - 运行聚焦验证，完成 review、walkthrough、wiki 和 PR lifecycle。

---

*创建于: 2026-05-15 | 最后更新: 2026-05-15*

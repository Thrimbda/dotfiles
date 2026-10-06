# Doom Org/Norang Minimal

## 目标

把当前 Doom Emacs 私有配置收敛为只服务 Org mode 与 `bh-org.el` / norang 工作流的最小可用配置，并修复已确认的现代 Doom / Org 兼容问题。

## 问题陈述

当前 `~/.config/doom/init.el` 仍启用了 LSP、语言模块、终端、RSS、Treemacs、Magit Forge、grammar 等通用编辑器功能；这些与用户“只用 orgmode，需要 bh-org.el 和完整 norang 工作流”的目标不一致，增加启动、同步和维护噪音。与此同时，`bh-org.el` 中存在少数旧 Org 时代遗留配置，会在 Emacs 30 / Org 9.8 环境中造成加载或运行风险。

## 验收标准

- [x] Doom 模块配置只保留 Org/Norang 日常所需能力，以及少量 Doom 基础 UI / completion / file management 支撑。
- [x] `bh-org.el` 保持 norang 核心能力，包括 agenda、capture、refile、clocking、restriction/narrowing、habit、org-protocol 和 org-crypt。
- [x] 已修复 `org-iswitchb`、`incf`、Babel `sh`/`ammonite` 加载等已确认兼容问题。
- [x] `packages.el` 不再安装与精简目标无关的包；保留用户日常必要的输入法 / Org 视觉辅助包。
- [x] 运行 Doom 同步或至少运行可替代的 batch 加载验证，记录成功项和残余风险。
- [x] 不修改用户的 Org 数据文件，不改变 `~/OneDrive/cone` 的任务内容。

## 假设 / 约束 / 风险

- **假设**: 用户继续使用 `~/.config/doom` 作为 Doom private config，并使用 `~/OneDrive/cone` 作为 Org 目录。
- **假设**: 用户仍希望保留 Doom 的基础交互层，而不是完全退回 vanilla Emacs。
- **约束**: `~/.config/doom` 自身不是 Legion-managed 仓库；Legion raw evidence 放在 `/Users/c1/dotfiles/.legion/tasks/doom-org-norang-minimal/`。
- **约束**: 改动必须尽量局部，避免重写整个 `bh-org.el` 或迁移 Org 数据。
- **风险**: 过度精简可能移除用户仍在 Org source block 中依赖的语言高亮或 Babel 执行能力。
- **风险**: `org-crypt-key` 当前指向本机不存在的 GPG secret key；若用户实际使用 `:crypt:`，需要后续提供可用 key。
- **风险**: Doom CLI 当前 `doom doctor` 曾在 `require straight` 处失败，可能需要 `doom sync` 重新 bootstrap 后再复测。

## 要点

- **最小 Doom**: 精简 `init.el`，去掉非 Org/Norang 工作流必需模块。
- **现代兼容**: 修复 `bh-org.el` 中已确认会影响 Emacs 30 / Org 9.8 的旧接口。
- **保守保留**: 只保留与 Org 体验、中文输入或现有配置直接相关的包和设置。
- **可验证**: 通过 Doom sync / doctor 或 batch load 证明配置至少可加载，并记录未能完全验证的部分。

## 范围

- `/Users/c1/.config/doom/init.el` - Doom 模块精简。
- `/Users/c1/.config/doom/config.el` - 与精简模块一致的 Doom / Org 配置整理。
- `/Users/c1/.config/doom/packages.el` - 私有包列表精简。
- `/Users/c1/.config/doom/bh-org.el` - 兼容性修补，不重写工作流。
- `.legion/tasks/doom-org-norang-minimal/` - 本任务契约、日志、验证和交付文档。

## 非目标

- 不修改 `~/OneDrive/cone` 下任何 Org 数据文件。
- 不升级或降级 Doom Emacs 本体。
- 不启用 org-roam、noter、journal、present 等新的 Org 扩展工作流。
- 不把 Doom 配置迁移成 literate config。
- 不为所有历史 Org Babel 语言块恢复完整编程 IDE 能力。
- 不处理 GPG key 本身的创建、导入或信任配置。

## 设计索引 (Design Index)

> **Design Source of Truth**: `.legion/tasks/doom-org-norang-minimal/docs/rfc.md`

**摘要**:
- 核心流程: 先把 Doom 模块压缩到 Org/Norang 与基础支撑，再修补 `bh-org.el` 的旧接口兼容点，避免重写 norang 工作流。
- 验证策略: 优先运行 `doom sync` / `doom doctor`；若 Doom bootstrap 状态阻塞，则用 Emacs batch load 验证 `bh-org.el` 在当前 Org 版本可加载，并记录阻塞来源。

## 阶段概览

1. **brainstorm** - 建立任务契约并落盘。
2. **engineer** - 精简 Doom 配置并修复 `bh-org.el` 兼容点。
3. **verify-change** - 运行 Doom / Emacs 加载验证并记录结果。
4. **review-change** - 检查改动是否保持 scope、验收和风险边界。
5. **report-walkthrough** - 生成面向评审者的交付摘要。
6. **legion-wiki** - 写回跨任务可复用结论。
7. **git-worktree-pr** - PR 合并、active config 刷新与临时 worktree/branch 清理。

---
*Created: 2026-07-09 | Updated: 2026-07-09*

# Hlissner-aligned Dotfiles Architecture Cleanup

## 目标
在审视当前仓库和 hlissner/dotfiles 架构后，对本仓库做一次审慎的、以 PR 交付的架构清理。目标是让代码库更干净、更可维护，同时不改变既有功能；若出现极小行为调整，必须显式记录原因、影响和验证证据。

## 问题陈述
当前仓库保留了 hlissner 风格的 `flake -> lib.mkFlake -> hosts -> modules` 骨架，但在 Darwin 兼容、Axiom Wayland/Caelestia 桌面产品化、Cloudflare/remote access、Legion 文档和若干历史迁移中积累了横切特例。风险不在单个模块，而在模块边界、平台边界、host-local 配置和生成文件职责之间逐步漂移，导致后续改动需要反复重读上下文。

本任务要先学习 hlissner 原仓库的组织方式，再选择最小正确的清理路径：保留当前行为和公共 option 形状，收敛重复模式，移动或拆分只在边界更清晰时才值得移动的结构，避免把一次清理演变成新桌面功能、输入升级或平台迁移。

## 验收标准
- [ ] 现状研究覆盖当前仓库结构、`.legion/wiki` 当前真源、hlissner/dotfiles 临时克隆对照，并记录到 `docs/research.md`。
- [ ] 在实现前产出并通过 RFC 审查，RFC 明确推荐方案、替代方案、回滚路径、验证策略和“不影响功能”的判定方式。
- [ ] 实现保持现有 flake inputs/lock、host 启用模块集合、secret 路径、服务端口/域名和运行时产品选择不变；任何轻微行为调整都必须在 RFC、log 和交付报告中列出。
- [ ] 架构清理优先减少重复、明确平台边界、收敛 host-local 与 reusable module 的职责，而不是扩大功能面。
- [ ] 运行当前环境可承受的 Nix/静态验证，并把不可验证项、原因和部署后 smoke checklist 写入 `docs/test-report.md`。
- [ ] 完成 readiness review、reviewer walkthrough、PR body、Legion wiki writeback，并创建 PR；PR 不自动合并。

## 假设 / 约束 / 风险
- **假设**: `/tmp/opencode/hlissner-dotfiles` 只作为只读架构参考，不 vendoring 代码、不引入上游 mutable setup 或新产品方向。
- **假设**: 当前有效桌面方向仍是 Axiom 上的 Hyprland + UWSM + Caelestia Shell；Darwin 仍是共享 shell/dev/editor/XDG 目标。
- **约束**: 修改型阶段必须在隔离 git worktree 中完成并通过 PR 交付；主工作区只用于准备、只读检查和最终刷新。
- **约束**: 不读取或改写 `token.env`、age secret 明文、Cloudflare 凭据或其他 secret 内容。
- **约束**: 不升级 flake inputs、不改 `flake.lock`，除非验证命令产生不可避免的锁文件变化并单独确认。
- **约束**: 不自动 merge PR，不执行部署型 rebuild/switch。
- **风险**: 仓库使用 `_module.check = false`，无效 option 或移动后的漏导入可能被求值隐藏，需要额外路径/grep/构建验证弥补。
- **风险**: Git-backed flake 对新文件敏感；新增模块验证前需要 intent-to-add 或在 PR worktree 中确保文件被 Git 看到。
- **风险**: 结构移动可能影响 `${hey.configDir}`、Home Manager source path、generated Hyprland/UWSM 文件和 Darwin/Linux 环境变量边界。

## 要点
- **taskId**: `hlissner-architecture-cleanup`
- **name**: `Hlissner-aligned Dotfiles Architecture Cleanup`
- **推荐方向**: 保留 hlissner 的轻量自制框架，不迁移到 flake-parts/devos；在当前框架内清理职责边界和重复模式。
- **设计摘要**: 优先做“边界清理型”重构：把平台差异、桌面产品集成、host-local facts 和通用模块职责写清并收敛；只有在能证明零功能漂移时才移动文件或抽 helper。
- **PR 策略**: 创建 PR 供 review，不自动合并；checks/review 后续跟进按 Legion workflow 记录。

## 范围
- `flake.nix`、`default.nix`、`darwin/default.nix`、`lib/**/*.nix` - 核心 flake/模块装配层，限于结构清理或 helper 收敛。
- `modules/**/*.nix` - 模块边界、平台边界、重复模式和注释清理，保持 public options 与启用语义稳定。
- `hosts/**/*.nix` - host-local 与 reusable module 职责边界清理，避免改变启用功能和服务参数。
- `config/**`、`bin/**` - 仅当 Nix 结构清理需要同步引用路径或文档化边界时触碰。
- `README.md`、`docs/**`、`.legion/tasks/hlissner-architecture-cleanup/**`、`.legion/wiki/**` - 记录设计、验证、交付和可复用模式。

## 非目标 / Out of Scope
- 不引入新的桌面功能、shell UI、快捷键能力、browser/app baseline 或运行时产品选择。
- 不替换 Caelestia Shell，不恢复 end4/DMS/Quickshell 产品路径，不扩展 X11/bspwm 兼容。
- 不升级 nixpkgs、Hyprland、Caelestia、home-manager、nix-darwin 或其他 flake inputs。
- 不改 secret 格式、recipient、路径、Cloudflare Access policy、tunnel ID、remote SSH 端口或 opencode 暴露策略。
- 不做 live deployment、`nixos-rebuild switch`、`darwin-rebuild switch` 或 PR 自动合并。

## 设计索引
> **Design Source of Truth**: `docs/rfc.md`（待创建）

**摘要**:
- 核心流程: 先形成 evidence-backed research，再用 RFC 决定清理粒度和文件边界，审查通过后在隔离 worktree 中最小实现。
- 验证策略: 组合 `nix eval`/目标 host build、Hyprland 配置验证、静态搜索、diff review 和文档检查；真实 Axiom/Darwin runtime smoke 作为部署后 checklist，不在本地假装已完成。

## 阶段概览
1. **Phase 1 - Contract and Research**: 物化任务契约，审视当前仓库、Legion 当前真源和 hlissner/dotfiles 参考。
2. **Phase 2 - RFC and Review**: 产出架构清理 RFC，完成 RFC review；不通过则回到设计。
3. **Phase 3 - Worktree Implementation**: 进入 git-worktree-pr envelope，在隔离 worktree 中按 RFC 做最小重构。
4. **Phase 4 - Verification and Readiness Review**: 运行验证，记录不可验证项，执行 change review。
5. **Phase 5 - PR Delivery and Writeback**: 生成 walkthrough/PR body，创建但不合并 PR，完成 Legion wiki writeback。

---
*Created: 2026-05-12 | Updated: 2026-05-12*

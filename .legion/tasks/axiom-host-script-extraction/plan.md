# Axiom Host Script Extraction

## 目标
把上一轮后仍留在 `hosts/axiom/default.nix` 的大块内联脚本和 host-local service policy 继续下沉到清晰模块边界，让 Axiom host 主要声明事实、启用模块和少量硬件参数，而不是承载 shell 脚本实现。

## 问题陈述
`axiom-default-modularization` 已经抽出了 reverse SSH、opencode server 和 healthcheck skeleton，但 Axiom host 仍保留 Caelestia mutable config migration、HDMI audio readiness、healthcheck predicate body、ToDesk service、virt stack、polkit allowlist 等较长内联实现。用户明确指出这仍然过于保守，目标不是保留一团 host-local 脚本，而是得到合理、清晰、简明、高内聚、低耦合的 Nix 系统。

本任务继续 aggressively modularize：只要逻辑有明确责任边界，就抽成模块或模块 option；不为旧 inline 写法保留兼容层。

## 验收标准
- [ ] `hosts/axiom/default.nix` 的剩余内联 shell 显著减少，host 文件不再直接包含 Caelestia JSON migration、HDMI audio readiness、healthcheck predicate 的大段脚本实现。
- [ ] Caelestia Axiom defaults/migration 被移入 `modules/desktop/caelestia.nix` 或 focused companion option，host 只传 favourite app、idle policy、session path/data dirs 等事实。
- [ ] HDMI audio startup workaround 被移入 focused desktop/audio module，host 只传 card/sink/node priority facts。
- [ ] ToDesk runtime service 被抽成 service module，host 只启用并传 package/user/state dir。
- [ ] Axiom healthcheck predicates 被移出 host 或压缩成模块 option，不再在 host 内维护完整 shell script body。
- [ ] 无行为意义的旧兼容字段或 parallel implementation 不保留。
- [ ] `nix build .#nixosConfigurations.axiom.config.system.build.toplevel` 成功。

## 假设 / 约束 / 风险
- **假设**: 当前有效基线是已合并 PR #93 的 `origin/master`。
- **假设**: 用户明确偏好简洁模块化，而不是为了历史 inline shape 兼容而保守。
- **约束**: 不触碰真实 secrets、Cloudflare 外部状态或 live service restart。
- **约束**: 仍保留 Caelestia mutable `shell.json` migration 的行为需求，但不要求它留在 host 文件中。
- **约束**: 仍保留 Hyprland 0.53.x `render.cm_enabled = false` workaround，不把桌面 HDR/color-management 作为本任务目标。
- **风险**: 抽得过宽会变成新 framework；模块必须围绕现有 Axiom 责任边界，不发明泛化平台。
- **风险**: Audio/Caelestia 脚本迁移如果改错 hook ordering，会影响 graphical session；必须用 evaluated service/script facts 和 Nix build 验证。

## 要点
- **Host as facts**: Axiom host 留 facts，不留脚本实现。
- **Focused modules**: Caelestia migration、HDMI audio readiness、ToDesk runtime、Axiom health predicates 各自进负责它们的模块。
- **No compatibility shim**: 旧 inline shape 不保留。
- **Nix proof**: 静态事实 eval + toplevel build 是交付门槛。

## 范围
- `hosts/axiom/default.nix` - 删除内联脚本，改为模块 facts。
- `modules/desktop/caelestia.nix` - 承载 Caelestia mutable config migration/favourite app/idle defaults 的更清晰接口。
- `modules/profiles/hardware/audio.nix` 或新 focused audio module - 承载 HDMI sink readiness/user service 逻辑。
- `modules/services/todesk.nix` - 承载 ToDesk service/tmpfiles。
- `modules/services/healthchecks.nix` / focused check helpers - 继续收束 Axiom predicates。
- `.legion/tasks/axiom-host-script-extraction/**` 和 `.legion/wiki/**` - 记录证据和 durable patterns。

## 非范围
- 不重写 `modules/desktop/hyprland.nix` 的 Axiom-flavored keybind/rule policy；那是单独 desktop cleanup。
- 不改变 Cloudflare tunnel IDs、Access policies、DNS 或 secrets。
- 不做 live reboot/session restart/audio smoke；保留为部署后检查。
- 不升级 Hyprland 或重新启用 color management/HDR。

## 设计索引
> **Design Source of Truth**: design-lite in this plan. If implementation exposes a real trade-off, write `docs/rfc.md` before coding further.

**摘要**:
- 核心流程: 从 `origin/master` worktree 中识别 remaining inline script clusters，按责任边界下沉到 existing/new modules，host 只保留 facts。
- 验证策略: focused `nix eval` 检查生成的 Caelestia/session/audio/todesk/healthcheck/service facts，最终跑 Axiom toplevel build。

## 阶段概览
1. **Contract** - 固化 follow-up scope 和验收。
2. **Implementation** - 抽模块并缩减 host 内联脚本。
3. **Verification** - facts eval + `nix build`。
4. **Review & Delivery** - review-change、walkthrough、wiki、PR lifecycle。

---
*Created: 2026-06-18 | Updated: 2026-06-18*

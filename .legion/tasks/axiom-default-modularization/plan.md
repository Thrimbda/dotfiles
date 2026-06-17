# Axiom Default Modularization

## 目标
把 `hosts/axiom/default.nix` 从混杂的主机脚本整理成更清晰的模块组合：删除明确重复或无效的配置，抽出跨主机/跨服务复用的模块边界，并保持 Axiom 当前 workstation 行为可通过 Nix 构建验证。

## 问题陈述
Axiom host 当前把桌面策略、public service、reverse SSH、healthcheck、虚拟化、音频 workaround、Cloudflared/Gatus/Opencode glue、以及硬件事实集中在单个 `default.nix` 中。结果是重复配置、硬编码用户路径、跨 host 逻辑无法复用、shared module 里反向泄漏 Axiom 命名，后续维护需要在多个位置同步端口、hostname、timer 和 service 参数。

本任务优先追求合理、简洁、高内聚、低耦合的 NixOS 模块化结构。对没有真实消费者或历史数据约束的兼容层不做保留；对已有运行时状态确实需要迁移的部分，必须写清原因并尽量收束到模块接口里。

## 验收标准
- [ ] `hosts/axiom/default.nix` 删除明确重复/无效的配置，例如无效 wallpaper mode、重复 xdg ssh/startAgent/fs/networkmanager 设置、无明确消费者的 firewall 开口。
- [ ] 跨 host 的 reverse SSH tunnel 不再主要以内联 systemd/launchd 块散落在 host 文件里，至少 Axiom 使用新的高内聚模块入口。
- [ ] Opencode server 的 systemd service、Axiom public URL metadata、Gatus endpoint、Cloudflared ingress 的重复事实被收束到单一模块或清晰的单一来源。
- [ ] Axiom healthcheck 的计数、timer、restart 模式被抽成可复用 helper 或模块化结构，避免三份脚本重复骨架。
- [ ] Axiom 仍保留必要的 Caelestia idle persisted-config migration，但职责边界比当前更清楚；不误删已有运行时迁移需求。
- [ ] 明显硬编码的 `c1`/`/home/c1` 在可配置模块或 host-local service 中改用 `config.user.name` / `config.user.home`，除非是明确的外部协议事实。
- [ ] `nix build .#nixosConfigurations.axiom.config.system.build.toplevel` 成功。
- [ ] 修改后的配置保持 Axiom 当前核心能力：Hyprland/Caelestia workstation、Cloudflared public ingress、Gatus status checks、reverse SSH、Opencode server、Clash Verge resilience、HDMI audio startup fix。

## 假设 / 约束 / 风险
- **假设**: 用户希望偏向清晰系统设计，不要求为无现存消费者的旧配置保留兼容路径。
- **假设**: Axiom 当前是 NixOS x86_64 workstation，主用户仍为 `config.user.name = "c1"`，但模块实现不应依赖硬编码用户名。
- **约束**: 必须使用 Nix 构建验证，最终至少跑 `nix build .#nixosConfigurations.axiom.config.system.build.toplevel`。
- **约束**: 不直接删掉历史任务明确要求保留的 Caelestia idle migration；这是已有 mutable `shell.json` 的实际运行时约束。
- **约束**: Hyprland `cm_enabled = false` 当前仍对应 Hyprland 0.53.x workaround，除非验证版本和行为变化，否则不作为本任务清理目标。
- **风险**: Cloudflared/Gatus/Opencode glue 如果抽象过度，可能隐藏实际 ingress/endpoint 的单一真源；模块接口必须保持可读。
- **风险**: reverse SSH healthcheck 涉及远端端口和 host key 校验，重构必须保留现有 restart 语义。
- **风险**: firewall 清理如果误删真实需要的端口范围，可能影响局域网工作流；只删除没有明确消费者且可由服务模块重新声明的开口。

## 要点
- **删除优先**: 对明确重复、无效或无消费者的配置直接删，不加兼容 shim。
- **模块边界**: 把 public service、reverse SSH、healthcheck pattern 抽成服务模块或小 helper，而不是继续扩大 Axiom host 文件。
- **单一真源**: 端口、hostname、service path、user/home 等事实尽量只在一个模块接口中声明。
- **最小必要迁移**: 只对已有 mutable runtime state 保留迁移逻辑，并把原因写清。
- **验证收口**: 用 Nix eval/build 验证最终 Axiom toplevel，而不是只做语法检查。

## 范围
- `hosts/axiom/default.nix` - 主体清理、模块调用、host-specific 事实保留。
- `modules/services/*.nix` - 新增或改造 reverse SSH、Opencode server、healthcheck、Cloudflared/Gatus glue 相关模块。
- `modules/desktop/caelestia.nix` / `modules/desktop/hyprland.nix` - 仅做必要的边界收束，不做大规模桌面产品重写。
- `modules/services/calibre.nix` / small shared modules - 清理明显硬编码或未用 binding。
- `.legion/tasks/axiom-default-modularization/docs/*` - 记录验证和交付证据。

## 非范围
- 不升级 Hyprland 或重新启用 HDR/color management。
- 不重做整个 desktop shell、Caelestia UX、keybinding 系统或 monitor hotplug 架构。
- 不迁移 secrets、不改 Cloudflare 真实 tunnel ID、不触碰外部 DNS/Cloudflare API。
- 不为了兼容旧 host 写双路径模块接口，除非当前仓库内已有 host 立即使用。
- 不做 live suspend/hibernate 或真实远端 autossh 连通性测试；这些保留为部署后 smoke check。

## 设计索引
> **Design Source of Truth**: `docs/rfc.md`

**摘要**:
- 核心流程: 先删除 Axiom host 明确重复/无效项，再抽出 reverse SSH、Opencode public service、healthcheck helper 等高内聚边界，最后回接 Axiom。
- 验证策略: 使用 Nix eval 检查关键配置事实，使用 `nix build .#nixosConfigurations.axiom.config.system.build.toplevel` 作为交付门槛。

## 阶段概览
1. **Contract** - 固化任务契约、风险、验收与范围。
2. **Design** - 通过短 RFC 明确模块边界和非目标。
3. **Implementation** - 在隔离 worktree 中完成模块化和 host 清理。
4. **Verification** - 运行 Nix eval/build，记录测试报告。
5. **Review & Delivery** - 自审变更边界、生成 walkthrough、写回 wiki。

---
*Created: 2026-06-18 | Updated: 2026-06-18*

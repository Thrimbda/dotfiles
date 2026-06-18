# Axiom Host Policy Extraction

## 目标
第三轮继续缩小 `hosts/axiom/default.nix`：把 PR #94 后仍留在 host 内的 service resource policy、status endpoint inventory、LAN firewall allow、Clash GUI drop-in、zram/logrotate/NetworkManager 等剩余 host-local policy 下沉到 focused modules/options，让 Axiom host 更接近 pure facts + enablement。

## 问题陈述
前两轮已把 service mechanics、inline shell、polkit、libvirt、ToDesk、Caelestia migration、HDMI audio、healthcheck predicate 抽出，但 Axiom host 仍有若干较长且不该由 host 文件直接维护的 policy blocks：
- service OOM/restart/resource policy for sshd/cloudflared/clash/user@UID；
- Gatus endpoint inventory and status labels；
- Clash GUI user-service drop-in；
- LAN-only firewall `iptables` extra rule；
- zram/logrotate workstation policy；
- wired NetworkManager profile boilerplate。

本任务继续按“host as facts”收束。能成为 focused module 或 module option 的，就移走；host 只保留端口、CIDR、endpoint name/URL、interface name、memory values 等 facts。

## 验收标准
- [ ] `hosts/axiom/default.nix` 进一步显著缩短，并不再直接维护大段 service resource policy、status endpoint inventory、Clash GUI drop-in、LAN firewall iptables body 或 generic workstation policy。
- [ ] Axiom service resource/OOM policy 进入 reusable/focused module option，而不是散落在 host 的多个 `systemd.services.*.serviceConfig` blocks。
- [ ] Gatus status endpoint definitions 被抽到 status/profile module 或 service helper，host 不再维护 full endpoint list boilerplate。
- [ ] LAN-only firewall allow 被抽成 typed rule/helper，host 只传 CIDR 和 ports。
- [ ] Clash GUI autostart drop-in、zram/logrotate policy、wired NetworkManager profile boilerplate 尽量移到 owning modules；若某项保留在 host，必须在 review 中说明为什么它仍是 irreducible host fact。
- [ ] 不引入 broad compatibility shims；不保留旧 inline shape。
- [ ] `nix build .#nixosConfigurations.axiom.config.system.build.toplevel` 成功。

## 假设 / 约束 / 风险
- **假设**: 当前有效基线是 PR #94 merged `origin/master`。
- **假设**: 用户希望继续 aggressive modularization，而不是停在 451 行 host。
- **约束**: 不修改 secrets、Cloudflare external state、live DNS/Access policies、Hyprland desktop rewrite、hardware disk layout。
- **约束**: 保留已有行为语义：critical service OOM priority、Cloudflared/Clash restart policies、Gatus endpoint names/conditions/labels、LAN allow ports、NetworkManager wired profile。
- **风险**: 过度泛化会制造 framework 噪音；模块边界必须贴合已有 owning domain。
- **风险**: Firewall/resource policy 触及 security/availability，review 必须显式应用安全/operability lens。

## 范围
- `hosts/axiom/default.nix` - 继续移除 policy blocks。
- `modules/services/*` - status/Gatus helpers、resource policy helpers、Cloudflared/Clash/SSH owning options。
- `modules/desktop/apps/clash-verge.nix` - GUI autostart drop-in ownership。
- `modules/profiles/role/workstation.nix` 或 focused system modules - zram/logrotate/LAN firewall helper where appropriate。
- `modules/profiles/network/sh.nix` 或 network profile helper - wired NetworkManager profile where appropriate。
- `.legion/tasks/axiom-host-policy-extraction/**` and `.legion/wiki/**` - evidence and durable knowledge.

## 非范围
- 不改 Hyprland keybind/rules architecture；那仍是 separate desktop cleanup。
- 不改变 healthcheck script internals beyond using existing typed predicates unless needed for module ownership.
- 不改 Cloudflare tunnel IDs/hostnames/secrets or public access policy.
- 不做 live deployment/restart/smoke; keep post-deploy checks in maintenance.

## 设计索引
> **Design Source of Truth**: design-lite in this plan. If implementation discovers cross-module ambiguity or unsafe policy movement, write `docs/rfc.md` before coding further.

**摘要**:
- Keep host facts such as endpoint names, URLs, ports, CIDRs, interface names, and memory thresholds.
- Move behavior ownership to modules: apps own their service drop-ins, service modules own service resource policy, status module owns reusable endpoint patterns, network/firewall helpers own rule generation.
- Validate with focused Nix evals plus full Axiom toplevel build.

## 阶段概览
1. **Contract** - 固化第三轮 scope。
2. **Implementation** - 抽剩余 policy blocks。
3. **Verification** - focused eval + `nix build`。
4. **Review & Delivery** - review-change, walkthrough, wiki, PR lifecycle。

---
*Created: 2026-06-18 | Updated: 2026-06-18*

# Axiom 锁屏后 DPMS 延迟

## 目标

让 Axiom 在任何锁屏路径进入锁定状态 60 秒后关闭显示器，同时保留 15 分钟自动锁屏和现有唤醒、安全边界。

## 问题陈述

当前 DPMS 超时从最后一次输入开始按 1800 秒累计；手动锁屏后仍需等待很久，和 Windows 锁屏后使用独立显示器关闭超时的体验不一致。

## 验收标准

- [ ] 手动触发的锁屏在仍保持锁定时 60 秒后关闭显示器。
- [ ] 15 分钟空闲触发的锁屏也在锁定后 60 秒关闭显示器。
- [ ] 显示器被输入唤醒时保持锁屏；提前解锁会取消待执行的熄屏动作。
- [ ] Axiom 继续只有 Caelestia 作为自动空闲策略所有者，且不引入自动 suspend 或 hibernate。
- [ ] 修改具备可重复的静态验证或定向测试证据。

## 假设 / 约束 / 风险

- **假设**: 用户确认采用 Windows 默认的 60 秒锁屏显示器关闭时长。
- **假设**: 该策略应适用于手动和空闲两种锁屏入口。
- **约束**: 不修改其他主机的默认 Hypridle 行为。
- **约束**: 不改变现有 15 分钟锁屏、音频抑制或手动 Keep Awake 的语义。
- **约束**: 不在 Axiom 启用第二个竞争的 idle daemon。
- **风险**: 延迟任务若未与锁定状态绑定，可能在用户已解锁后错误熄屏。
- **风险**: 多条锁屏入口可能重复调度或无法取消待执行的 DPMS 动作。
- **风险**: DPMS 唤醒与 Caelestia 会话锁定状态可能存在时序竞争。

## 要点

- Windows-style lock display timeout
- Caelestia sole idle owner
- Cancellable post-lock DPMS action

## 范围

- hosts/axiom/modules/caelestia.nix 及其直接支持逻辑
- 必要的 Axiom/Hyprland 会话或锁屏集成文件
- .legion/tasks/axiom-lock-dpms-delay/docs/ 下的设计、验证与交付证据

## 设计索引 (Design Index)

> **Design Source of Truth**: [docs/rfc.md](docs/rfc.md)

**摘要**:
- 核心流程: 锁屏状态成为启动 60 秒 DPMS 延迟的唯一依据，解锁和恢复输入必须安全取消或失效该延迟。
- 验证策略: 审查实际锁屏入口和运行时状态，再用静态断言及可用的会话级检查确认无竞态。

## 阶段概览

1. **设计** - 研究现有锁屏、Caelestia idle 和 DPMS 状态边界并完成 RFC 审查
2. **实现** - 实现锁屏后 60 秒的可取消 DPMS 延迟
3. **验证与交付** - 完成定向验证、变更审查、walkthrough 和 wiki 写回

---

*创建于: 2026-08-20 | 最后更新: 2026-08-20*

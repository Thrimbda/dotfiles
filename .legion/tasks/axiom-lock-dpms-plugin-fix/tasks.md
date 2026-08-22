# Axiom Caelestia 锁屏 DPMS 行为修复 - 任务清单

## 快速恢复

**当前阶段**: 已完成
**当前检查项**: (none)
**进度**: 3/3 任务完成
---

## 阶段 1: 设计修订 ✅ COMPLETE

- [x] 记录 QML wake failure，审查 Axiom native DPMS wake 的全局影响、回滚和验证边界
---

## 阶段 2: 实现 ✅ COMPLETE

- [x] 为 Axiom 配置 Hyprland native key/mouse DPMS wake，并更新定向断言
---

## 阶段 3: 验证与交付 ✅ COMPLETE

- [x] 构建、部署、验证 60 秒 DPMS off / 输入 wake / 解锁恢复，完成 review、walkthrough、wiki 和 PR 生命周期；实现 PR [#197](https://github.com/Thrimbda/dotfiles/pull/197) 已合并为 `b8a57fbc`
---

## 已完成的前置修复

- [x] PR #194 已将 Config 插件与 shell QML runtime closure 对齐；现场证明属性和新插件均已加载。
- [x] secure-gated timer 已在部署后于 65 秒将两块显示器关闭，同时 Hyprland 保持 `LOCK`。
- [x] 严格受控测试已验证 locked pointer wake、同 epoch no-rearm 和 timer-owned DPMS unlock cleanup；临时认证禁用已恢复为 `true`。
---

## 发现的新任务

(暂无)
---

*最后更新: 2026-08-22*

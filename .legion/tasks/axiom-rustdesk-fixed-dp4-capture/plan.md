# Axiom RustDesk fixed DP-4 capture

## 目标

让 Axiom 上无人值守的 RustDesk 入站连接自动捕获实体主显示器 DP-4，不要求本机用户选择屏幕。

## 问题陈述

现有 XDPH custom picker 已声明 DP-4，但实际入站连接仍弹出本机屏幕选择界面，说明运行时捕获链未采用该固定选择。

## 验收标准

- [ ] 在新的无人值守 RustDesk 入站连接中不出现本机屏幕选择器。
- [ ] 连接建立后捕获的内容始终为 DP-4 的实体桌面。
- [ ] 重启受影响服务或重建用户 portal 会话后，固定选择仍有效。
- [ ] 不改变 Hyprland 的显示器布局、RustDesk 认证/中继配置或其他 portal 客户端的屏幕选择行为。

## 假设 / 约束 / 风险

- **假设**: Axiom 的屏幕一是配置中的 Microstep 主显示器 DP-4。
- **假设**: 问题发生在 Axiom 的 Wayland/XDPH/RustDesk 捕获链，而不是远端 RustDesk 客户端的显示界面。
- **约束**: 仅修改 Axiom 相关的 NixOS、Home Manager 或 RustDesk 配置。
- **约束**: 不引入虚拟显示器或独立无头桌面，因为目标是访问现有 DP-4 实体会话。
- **约束**: 保留现有 RustDesk 服务身份、密码和网络配置。
- **风险**: XDPH 的 custom picker 可能对同一用户会话中的其他 portal 请求产生全局影响。
- **风险**: 实际弹窗可能来自 RustDesk 的非-XDPH 路径，需先以运行时日志和进程配置确认。

## 要点

- 先确认活动 XDPH 进程读取的配置、picker 调用和 RustDesk 捕获请求的实际路径。
- 以最小的专用配置或服务包装修复固定输出，并记录其作用范围。
- 验证新连接、服务重启和用户 portal 重启后的无交互捕获。

## 范围

- Axiom 的 RustDesk 服务、Hyprland XDPH 配置和相关运行时验证。
- 任务契约、RFC、验证、评审、交付和 wiki 记录。
- 不包括虚拟显示器、远端客户端设置、显示器布局或 RustDesk 服务端改造。

## 设计索引 (Design Index)

> **Design Source of Truth**: docs/rfc.md

**摘要**:
- 推荐路线是修复实体显示器 DP-4 的 XDPH/RustDesk 选择链，而不是创建虚拟输出。
- 先通过会话级运行时证据区分 XDPH 配置未加载与 RustDesk 走非-XDPH 路径，再选择最小改动。
- 验证覆盖新入站连接以及受影响服务/portal 重启后是否仍无本机交互。

## 阶段概览

1. **设计与运行时诊断** - 确认活动 portal、picker 和 RustDesk 捕获路径
2. **实现** - 应用最小的 Axiom 专用固定 DP-4 捕获修复
3. **验证与交付** - 验证无交互 DP-4 捕获并完成评审、报告和 wiki 写回

---

*创建于: 2026-07-30 | 最后更新: 2026-07-30*

# Axiom Caelestia DPMS 插件修复

## 目标

让 Axiom 的 lock-scoped DPMS 超时同时由打补丁的 Caelestia shell QML 与 Config 插件提供，从而使锁屏后 60 秒熄屏功能实际运行。

## 问题陈述

现场验证表明 shell QML 已含 lockDpmsTimeout 逻辑，但运行中的 caelestia-qml-plugin derivation 的 patches 为空，仍来自未修改源。锁定时 QML 访问的配置属性因此没有由运行时插件提供，60 秒计时无法正确建立。

## 验收标准

- [ ] 主 shell 与 Caelestia.Config 插件分别应用所需补丁，且主 shell 运行时依赖替换为打补丁的插件。
- [ ] Axiom 评估出的 package.plugin 指向带 lockDpmsTimeout 的插件输出，不再是未打补丁的上游插件。
- [ ] 定向构建和二进制/源级断言验证配置属性同时存在于插件、QML 与运行时闭包。
- [ ] 部署后，重启 Caelestia 不丢失该属性；手动锁屏的 60 秒 DPMS 行为可被现场验证。
- [ ] 不改变 900/1800 秒策略、其他主机默认行为、Hypridle 所有权或 suspend/hibernate 语义。

## 假设 / 约束 / 风险

- **假设**: 用户报告的现场复现对应当前 Axiom 运行包。
- **假设**: Config 插件可通过 Nix overrideAttrs 独立应用仅含 C++ 配置属性的补丁。
- **约束**: 必须保留现有 Caelestia shell、CLI 与 session runner 所有权。
- **约束**: 插件补丁不得试图应用依赖 shell modules 的 QML hunk。
- **约束**: 不得以静态 QML 文件存在替代插件闭包验证。
- **风险**: 替换主 package 的 buildInputs 或 passthru.plugin 不完整会继续加载旧插件。
- **风险**: 多个同名 QML 插件在闭包中可能造成导入解析不确定性。
- **风险**: 部署及锁屏现场 smoke 具有会话中断风险，需避免自动解锁。

## 要点

- Caelestia Config plugin closure
- Nix overrideAttrs dependency replacement
- Live lock-scoped DPMS regression

## 范围

- modules/desktop/caelestia.nix 及其专用补丁/测试文件
- 必要的 Axiom 配置验证与任务证据
- .legion/tasks/axiom-lock-dpms-plugin-fix/docs/ 下的设计、验证和交付文档

## 设计索引 (Design Index)

> **Design Source of Truth**: docs/rfc.md（待设计阶段创建）

**摘要**:
- 核心流程: 将 C++ Config 属性与 QML 计时器补丁拆分，使各自应用到实际构建它们的 Caelestia derivation，并令主 shell 明确依赖打补丁的插件。
- 验证策略: 检查 derivation patches、主 shell 的 buildInputs 与 plugin passthru，构建后检测插件二进制属性，最后在部署会话验证。

## 阶段概览

1. **设计** - 记录运行时根因并审查 plugin/shell 补丁组合方案
2. **实现** - 拆分补丁并将打补丁 Config 插件接入 Caelestia shell
3. **验证与交付** - 完成闭包构建、部署后运行时检查、审查、walkthrough 和 wiki 写回

---

*创建于: 2026-08-21 | 最后更新: 2026-08-21*

# cross-platform-compatibility-audit - 任务清单

## 快速恢复

**当前阶段**: 阶段 1 - 问题诊断
**当前任务**: (none)
**进度**: 11/11 任务完成

---

## 阶段 1: 问题诊断 🟡 IN PROGRESS

- [x] 审视项目架构，识别平台兼容性问题 | 验收: 使用 explore agent 完成全面的代码库探索，输出问题清单 ← CURRENT
- [x] 分析 node.nix 环境变量不生效的根本原因 | 验收: 确认是 environment.variables vs sessionVariables 的平台差异问题

---

## 阶段 2: 关键修复 🟡 IN PROGRESS

- [x] 修复 modules/dev/node.nix 环境变量设置 | 验收: 使用平台条件分离 Darwin 和 Linux 的环境变量配置，Darwin 构建成功
- [x] 修复 modules/security.nix 添加 Linux 平台保护 | 验收: 整个模块包裹在 lib.mkIf pkgs.stdenv.isLinux 中
- [x] 修复 modules/services/docker.nix 添加 Linux 平台检查 | 验收: config 条件改为 mkIf (cfg.enable && pkgs.stdenv.isLinux)
- [x] 修复 modules/services/ssh.nix 的 systemd 依赖 | 验收: systemd.user.tmpfiles.rules 包裹在 Linux 检查中
- [x] 更新 modules/services/gnome-keyring.nix 包名 | 验收: gnome.seahorse 改为 seahorse

---

## 阶段 3: 基础设施改进 🟡 IN PROGRESS

- [x] 在 lib/options.nix 创建 mkEnvVars 辅助函数 | 验收: 函数自动根据平台选择 environment.variables 或 sessionVariables
- [x] 编写完整的跨平台模块开发指南 | 验收: 创建 CROSS_PLATFORM.md，包含架构说明、最佳实践、常见模式、完整示例

---

## 阶段 4: 验证测试 🟡 IN PROGRESS

- [x] 构建验证 Darwin 配置 (charlie) | 验收: nix build .#darwinConfigurations.charlie.system 成功
- [x] 清理临时文件并准备提交 | 验收: 删除手动创建的 task/ 目录，使用 legionmind 正式记录

---

## 发现的新任务

(暂无)

---

*最后更新: 2026-01-18 11:29*

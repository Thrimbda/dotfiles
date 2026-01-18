# cross-platform-compatibility-audit

## 目标

确保 dotfiles 项目在 NixOS 和 nix-darwin 两个平台上都能正常工作，修复所有关键的平台兼容性问题


## 要点

- 修复关键模块的平台保护缺失问题（security.nix, docker.nix, ssh.nix）
- 解决 node.nix 环境变量在 Darwin 上不生效的问题
- 创建统一的环境变量设置辅助函数（mkEnvVars）
- 建立标准的跨平台开发模式和最佳实践
- 编写完整的跨平台模块开发指南文档
- 验证两个平台的构建成功


## 范围

- modules/dev/node.nix
- modules/security.nix
- modules/services/docker.nix
- modules/services/ssh.nix
- modules/services/gnome-keyring.nix
- lib/options.nix
- CROSS_PLATFORM.md

## 阶段概览

1. **问题诊断** - 2 个任务
2. **关键修复** - 5 个任务
3. **基础设施改进** - 2 个任务
4. **验证测试** - 2 个任务

---

*创建于: 2026-01-18 | 最后更新: 2026-01-18*

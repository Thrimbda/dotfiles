# Charles 原生访问 Axiom 用户文件

## 目标

部署无需 SSHFS 的顺畅文件访问，并完成实际测试、三台机器 switch 和 PR 合并。

## 要点

- 用户于 2026-10-03 批准此前 SMB3 方案并授权部署、测试和提交合并。
- Axiom 共享 `/home/c1`，SMB3 强制加密；Charles 使用原生 NetFS。
- 默认 FRP XTCP 点对点；Ant 协调打洞，STCP/WireGuard 为中转备用。两端 FRP 流量在 Clash Verge 中 DIRECT。
- Charles 的 `~/Axiom` 登录后自动连接；手动断开会暂停自动挂载。
- 保留主工作区和 Axiom 上已有的 Codex、SSH 配置改动；不混入 PR。

## 范围

Axiom Samba 与加密凭据、Ant 定向转发策略、Charles FRP visitor 和挂载工具、使用文档与验证记录。

## 设计索引

此前批准方案：主工作区 `.legion/tasks/charles-fuse-t-feasibility/docs/proposal.md`。
验收：原生挂载、强制加密、读写哈希、原子保存、远端变化、两种传输对比、失败路径、实际 switch。
撤回：卸载挂载并移除新模块和规则；保留远端项目文件。

## 阶段概览

1. 隔离实施并构建声明配置。
2. switch 三台机器，验证并选择默认路径。
3. 文档、提交、PR checks、squash merge 和安全清理刷新。

## 当前实施范围

按用户要求，将现有共享根目录改为 `/home/c1`，Charles 挂载点保持 `/Users/c1/Axiom`。保留 SMB 共享名 `work` 以兼容现有客户端；传输、凭据、账户和文件权限不变。验收有效 Samba path、用户目录枚举、Work 子目录、根目录中的双向读写及加密；仅 Axiom 需要新系统 switch，Charles 正常卸载后重新挂载。沿用既有提交合并授权。

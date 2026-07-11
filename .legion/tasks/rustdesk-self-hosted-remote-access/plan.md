# RustDesk 自托管远程访问

## 目标

在 acorn 部署自托管 RustDesk OSS 服务端，并在 charlie 与 axiom 部署可控制且可被控制的 RustDesk 客户端，使用独立服务器身份密钥和每台设备独立的永久长密码。

## 问题陈述

当前缺少统一的自托管图形远程访问服务；直接复用 SSH 密钥会混淆信任域，公网端口、永久凭据、macOS TCC 和 Hyprland/Wayland 又引入安全与可用性风险。

## 验收标准

- [ ] acorn 运行 NixOS 原生 hbbs 与 hbbr，使用独立 RustDesk 密钥并通过 agenix 提供私钥
- [ ] acorn 的 NixOS 防火墙和阿里云安全组所需端口已配置或明确验证，RustDesk 服务部署后健康
- [ ] charlie 与 axiom 安装当前锁定的 RustDesk 1.4.8 客户端，固定使用 acorn ID server 与匹配公钥，并启用系统服务
- [ ] charlie 与 axiom 使用不同的高熵永久密码，明文不进入 Git 或 Nix store
- [ ] 配置与安全评审 PR 先合并，三台主机只从 clean merged commit 执行生产 switch
- [ ] acorn、axiom 和 charlie 均完成实际 switch，服务端与客户端运行状态得到验证
- [ ] Nix eval/build、密钥权限、安全审查、回滚说明和部署后人工验收项通过 follow-up evidence PR 留下可追踪证据

## 假设 / 约束 / 风险

- **假设**: rustdesk.0xc1.wang 可作为 DNS-only 服务名指向 acorn 公网地址，若 DNS 尚未存在则客户端可先使用 8.159.128.125
- **假设**: acorn 与 axiom 的 sudo 密码来自工作区未跟踪文件 acorn_password，且不会被记录或提交
- **假设**: charlie 可通过现有反向 SSH 路径访问，但 macOS TCC 权限必须人工授予
- **假设**: axiom 的 Hyprland/Wayland 无人值守能力需要部署后按场景验证
- **假设**: axiom 与 charlie 是 single-owner trusted endpoints；所有本地交互账号及其进程均在 RustDesk 永久密码的可信边界内，RustDesk 不承诺对同机可信进程隐藏该密码
- **假设**: 用户明确接受简化自动部署：正常路径不得把密码写入 Git、Nix store或服务日志，但接受可信个人设备上设置密码时的短暂 argv，以及进程恰在该窗口崩溃时可能留下非核心 crash metadata 的低概率残余
- **约束**: 不得复用 acorn OpenSSH id_ed25519 作为 RustDesk server key
- **约束**: 不得主动把服务器私钥或客户端永久密码写入 Nix store、Git 历史、常规服务日志或 PR；已明确接受的短暂 argv/crash metadata 残余除外
- **约束**: 使用仓库现有 agenix、NixOS 与 nix-darwin 模式，不引入 Docker
- **约束**: 保留现有 SSH、反向 SSH和 ToDesk 回退路径
- **约束**: acorn 必须使用用户指定的 nixos-rebuild switch 命令部署
- **约束**: 生产 switch 只能从已合并并刷新到 origin/master 的 clean commit 执行，不从 feature worktree 部署
- **风险**: 公网暴露 hbbs/hbbr 扩大攻击面并可能产生 relay 带宽费用
- **风险**: 密钥部署或轮换错误会造成所有客户端 key mismatch
- **风险**: macOS TCC、FileVault 和睡眠状态可能阻止无人值守访问
- **风险**: Hyprland/Wayland portal、锁屏和登录屏可能无法可靠被控
- **风险**: 跨三台主机 switch 可能出现部分成功，需要逐台可回滚
- **风险**: RustDesk 上游 CLI 仅支持 argv 设置永久密码；在已接受的简化边界内，极低概率的崩溃可能把该 argv 持久化为非核心 crash metadata

## 要点

- 独立信任域：RustDesk server key 与 SSH key 分离
- 最小暴露：原生客户端仅开放 21115-21117 和 21116/UDP
- 凭据隔离：每台被控设备使用独立 agenix 永久密码；使用有限、无常规日志的上游 CLI 初始化，不维护私有 RustDesk patch或 crash-attestation framework
- 渐进部署：先合并配置 PR，再从 merged baseline 部署服务端和客户端，最后用 evidence PR 收口；全程保留既有回退通道
- 非目标：RustDesk Pro、Web client、复用 SSH 私钥、移除 ToDesk

## 范围

- hosts/acorn/** - RustDesk server、agenix secret、端口与服务配置
- hosts/axiom/** - RustDesk 客户端、系统服务与独立永久密码配置
- hosts/charlie/** - RustDesk 客户端、系统服务与独立永久密码配置
- modules/** - 仅在三端确需复用时增加最小 RustDesk 模块
- .legion/tasks/rustdesk-self-hosted-remote-access/** - RFC、验证、评审和交付证据
- .legion/wiki/** - 收口时写入可复用决策

## 设计索引 (Design Index)

> **Design Source of Truth**: .legion/tasks/rustdesk-self-hosted-remote-access/docs/rfc.md

**摘要**:
- acorn 使用 NixOS services.rustdesk-server，RustDesk 专用密钥由 agenix 解密给最小权限服务
- 客户端使用当前锁定的 1.4.8，固定 ID server 与公钥；永久密码按主机独立生成，并由有限的 runtime-secret oneshot通过上游 CLI 初始化
- 按 acorn、axiom、charlie 分阶段部署与验证，任何失败均保留 SSH/ToDesk 回退

## 阶段概览

1. **设计与安全门禁** - 完成证据调研、RFC 与对抗审查
2. **实现与静态验证** - 在隔离 worktree 实现三台主机配置，完成构建、安全评审并合并配置 PR
3. **生产部署** - 刷新到 merged baseline 后依次 switch acorn、axiom、charlie 并执行运行时验证
4. **证据收口** - 通过 follow-up evidence PR 提交部署证据、walkthrough 与 wiki writeback并完成清理

---

*创建于: 2026-07-11 | 最后更新: 2026-07-11*

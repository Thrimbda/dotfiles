# 部署 Legion Pi Web 并通过 Acorn FRP 安全暴露

## 目标

在 Axiom 持久安装 Legion Pi 与 PI WEB，并通过现有 Auth Mini、FRP 和 Acorn nginx 提供经过认证的 HTTPS 入口 https://pi-axiom.0xc1.wang。

## 问题陈述

Axiom 已有可验证的 Legion Pi 发行骨架和到 Acorn 的 FRP 链路，但尚未部署持久 Pi runtime、PI WEB 用户服务或受认证的公网入口；直接公开 PI WEB 会暴露本机代码、终端和 Agent 能力。

## 验收标准

- [x] Axiom 的持久 Legion Pi profile 安装成功且 setup-pi verify 返回 READY。
- [x] @jmfederico/pi-web@1.202608.1 以 c1 用户服务运行，Web/API 仅监听 127.0.0.1:8504，session daemon 与 Web 服务可跨注销和重启存活。
- [x] Axiom Auth Mini gateway 在回环地址保护 PI WEB；共享 FRPS 的 `18082` listener 保持 wildcard-bound 但不在 Acorn firewall allowlist 中，nginx 仅从 loopback 消费该端口。
- [x] https://pi-axiom.0xc1.wang 使用有效 ACME 证书；未登录请求进入 Auth Mini，认证后 HTTP、API、WebSocket 和长连接可用，foreign/missing Origin 的 WebSocket upgrade 在公网边缘被拒绝。
- [x] Axiom 与 Acorn 激活均有可复查状态、日志、回滚和端到端验证证据，现有 status/opencode/FRP 服务不回退。
- [ ] dotfiles 变更经独立 RFC 审查、验证和变更审查，秘密与本机未跟踪文件不进入提交；PR lifecycle 正在执行。

## 假设 / 约束 / 风险

- **假设**: Axiom 是当前执行主机，Acorn 公网地址与现有 FRP token、Cloudflare DNS ACME、Auth Mini 身份配置继续有效。
- **假设**: pi-axiom.0xc1.wang 沿用 0xc1.wang 的现有 DNS 路由到 Acorn。
- **假设**: PI WEB 使用上游推荐的 per-user systemd 服务，Legion Pi profile 与 PI WEB data/config 保存在 c1 的持久用户目录。
- **约束**: Acorn 的任何 Nix 构建和部署只能从 Axiom 使用规定的 nixos-rebuild switch --flake .#acorn --target-host c1@8.159.128.125 --build-host localhost --sudo --ask-sudo-password --use-substitutes -L 命令执行，禁止在 Acorn 构建。
- **约束**: PI WEB 必须只绑定 127.0.0.1，不得直接暴露到公网；8504、Auth gateway 端口和 FRP remote port 不加入防火墙 allowlist。
- **约束**: 公网 PI WebSocket 只接受 `Origin: https://pi-axiom.0xc1.wang`；foreign 或 missing Origin 必须 fail closed，普通 HTTP/API 不受该检查影响。
- **约束**: 不提交 token、密码、provider/model 凭证、用户私钥或解密后的 age secret。
- **约束**: 不修改现有 OpenCode 服务语义，不把 PI WEB 内部 API 当作 Legion 控制平面 backend。
- **约束**: 所有仓库变更只在 dotfiles 隔离 worktree 中完成，并保持主工作区现有未跟踪任务、文档和秘密文件不变。
- **风险**: 错误的反代或认证配置可能公开本机终端、代码和 Agent 权限。
- **风险**: PI WEB 用户服务的 login-shell PATH、linger 和 PI_CODING_AGENT_DIR 环境若不一致，会导致 doctor 通过但 session daemon 使用错误 profile。
- **风险**: node-pty 原生安装、Pi/PI WEB 版本不匹配或服务升级顺序可能导致运行失败。
- **风险**: Axiom 或 Acorn 激活失败可能影响现有 frpc、nginx、Auth Mini 或其他代理服务，必须 fail closed 并保留回滚路径。
- **风险**: FRPS 的 `proxyBindAddr` 是 server-wide；单个 `18082` proxy 不能独立绑定 loopback，安全边界必须依赖 Acorn firewall deny 与 Auth Mini upstream，而不能误写成 loopback listener。

## 要点

- 推荐固定 @jmfederico/pi-web@1.202608.1，与 Pi core 0.84.2 兼容；后续升级另行复核。
- 复用 Axiom 本地 Auth Mini gateway 模式：PI WEB 8504 -> gateway 7782 -> frpc -> Acorn wildcard-bound/firewall-closed 18082 -> loopback nginx -> 443。
- 由 users.users.c1.linger 或等价受控配置保证用户服务开机常驻；服务环境显式绑定 Legion Pi agent/session 目录。
- 先验证本地 loopback 与认证 gateway，再验证 FRP/Acorn HTTPS；每层失败均不得绕过认证直连公网。

## 范围

- 范围内：Axiom Legion Pi profile、PI WEB 用户服务和必要的持久用户环境。
- 范围内：dotfiles 中 Axiom linger/Auth Mini gateway/frpc 配置与 Acorn ACME/nginx vhost。
- 范围内：本地、FRP、HTTPS、认证、WebSocket、重启持久性和现有服务非回退验证。
- 范围外：PI WEB fleet/federation、Legion 自有 HTTP/SSE API、provider/model 凭证、browser/computer-use 和 Pi Web 上游代码修改。

## 设计索引 (Design Index)

> **Design Source of Truth**: `docs/rfc.md`（Standard RFC）；上游参考为 PI WEB 1.202608.1 官方 install/config 文档、frp 0.66 配置与现有 Axiom/Acorn Auth Mini/FRP 模式。

**摘要**:
- 以最小增量复用现有认证和反代链，不直接公开 PI WEB。
- Legion Pi 与 PI WEB 保持单用户 c1、单主机 Axiom 的运行与状态所有权。
- 部署顺序、服务环境、验证、失败回滚和跨主机激活边界由简洁 Standard RFC 锁定，不引入 Heavy research/implementation-plan 文档链。

## 阶段概览

1. **Contract and upstream review** - Materialize the confirmed contract and recheck PI WEB, FRP, Axiom, and Acorn constraints
2. **Design gate** - Write and independently review the deployment RFC
3. **Declarative configuration** - Implement isolated Axiom and Acorn Nix changes
4. **Local and remote deployment** - Install Legion Pi and PI WEB on Axiom, activate Axiom, then deploy Acorn from Axiom
5. **Verification and review** - Verify loopback, auth gateway, FRP, HTTPS, WebSocket, persistence, and rollback evidence
6. **Delivery closeout** - Generate walkthrough, write Wiki disposition, and complete PR lifecycle

---

*创建于: 2026-08-18 | 最后更新: 2026-08-19*

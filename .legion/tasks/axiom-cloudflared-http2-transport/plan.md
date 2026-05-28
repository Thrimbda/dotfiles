# Axiom Cloudflared HTTP2 Transport Fix

## 目标

让 axiom 上 `opencode-axiom.0xc1.space` 的 cloudflared tunnel 永久使用 HTTP/2 transport，避免当前 Clash/Meta fake-ip 网络下默认 QUIC/UDP 持续超时导致链接断开。

## 问题陈述

现场排查确认 opencode server 本地监听 `127.0.0.1:4096` 且返回正常，cloudflared ingress 也仍指向该端口。断链发生在 cloudflared 出站连接 Cloudflare edge 阶段：`region*.v2.argotunnel.com` 被系统 DNS 解析到 `198.18.0.x` fake-ip，默认 QUIC/UDP 日志持续报 `failed to dial to edge with quic: timeout`。临时用 `cloudflared tunnel --protocol http2` 启动 connector 后已能注册 edge，并且公网 hostname 返回 Cloudflare Access 登录跳转。

## 验收标准

- [ ] `hosts/axiom/default.nix` 的 axiom cloudflared `extraConfig` 声明 `protocol = "http2"`。
- [ ] opencode server、hostname、ingress service、tunnel id 和 credentials 配置保持不变。
- [ ] 本地 Nix/targeted eval 能证明生成的 `/etc/cloudflared/config.yml` 包含 `"protocol":"http2"` 且 cloudflared systemd `ExecStart` 仍读取 `/etc/cloudflared/config.yml`。
- [ ] 变更不读取、不输出、不提交明文 Cloudflare credentials 或 token。
- [ ] Legion 验证、review、walkthrough、wiki 和 PR lifecycle 证据齐全，无法完成的部署/运行态步骤明确记录为 blocker 或人工验证项。

## 假设 / 约束 / 风险

- **假设**: 现场 `--protocol http2` 测试已经足以证明 HTTP/2 transport 能穿过当前 Clash/Meta fake-ip 网络。
- **假设**: 当前 tunnel 的 hostname、ingress、credentials 和 Access policy 仍有效，不需要重新建 tunnel 或改 Cloudflare 控制台策略。
- **约束**: 遵守 Legion workflow 和 `git-worktree-pr`，实现与任务产物只写入 task worktree。
- **约束**: 不直接修改 `/etc/static/cloudflared/config.yml` 或 `/nix/store`，只修改 declarative dotfiles 真源。
- **约束**: 不调整 Clash Verge/Mihomo fake-ip/DNS 规则，不改变 opencode server 监听地址。
- **风险**: HTTP/2 transport 牺牲 QUIC 的部分特性，但对当前单 hostname opencode 访问影响低，且可用 `git revert` 回滚。
- **风险**: 真实恢复仍需要目标机部署并重启 systemd `cloudflared.service`；本任务只能提交 declarative 修复和本地 eval 证据。
- **风险**: 当前临时用户态 HTTP/2 connector 仍在运行以维持服务，部署永久修复后需要人工清理或确认不再需要。

## 要点

- **Task ID**: `axiom-cloudflared-http2-transport`
- **Root cause**: cloudflared 默认 QUIC 在 fake-ip/UDP 代理路径下无法连接 edge。
- **Recommended path**: 在 axiom host 的 cloudflared `extraConfig` 顶层添加 `protocol = "http2"`，由现有模块序列化到 `/etc/cloudflared/config.yml`。
- **Verification**: 用 Nix eval 检查生成配置和 systemd service shape，公网运行态部署作为后续人工验证。

## 范围

- `hosts/axiom/default.nix` - axiom cloudflared host-level transport 配置。
- `.legion/tasks/axiom-cloudflared-http2-transport/**` - task contract、design-lite、验证、review、walkthrough 和 PR 证据。
- `.legion/wiki/**` - closing writeback only。

## 非目标

- 不修改 Clash Verge/Mihomo、systemd-resolved、NetworkManager 或 DNS fake-ip 规则。
- 不重新创建 Cloudflare tunnel、DNS route 或 Access application/policy。
- 不修改 opencode server systemd service、端口、监听地址或认证模型。
- 不读取、解密、展示或重加密 cloudflared credentials。
- 不在本任务中执行 `nixos-rebuild switch` 或直接重启系统 `cloudflared.service`，除非用户另行确认并提供权限。

## 设计索引 (Design Index)

> **Design Source of Truth**: `.legion/tasks/axiom-cloudflared-http2-transport/docs/rfc.md`

**摘要**:
- 核心流程: 保持现有 tunnel/ingress/service 形状不变，只把 cloudflared 到 Cloudflare edge 的 transport 固定为 HTTP/2。
- 验证策略: 用 targeted Nix eval 验证生成配置包含协议字段，并确认 service 继续读取 declarative `/etc/cloudflared/config.yml`。

## 阶段概览

1. **Contract** - 创建稳定任务契约和 design-lite。
2. **Implementation** - 在 worktree 内实施最小 Nix host 配置变更。
3. **Verification** - 运行 targeted eval/build 并写入 test-report。
4. **Review** - 执行 readiness review，确认 scope、风险和安全边界。
5. **Delivery** - 生成 walkthrough/PR body，完成 wiki writeback 与 PR lifecycle。

---

*创建于: 2026-05-28 | 最后更新: 2026-05-28*

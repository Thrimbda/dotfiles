# Axiom Cloudflared HTTP2 Transport Fix - 日志

## 会话进展 (2026-05-28)

### 已完成

- 现场排查确认 opencode 本地服务正常，cloudflared ingress 正确，断链发生在默认 QUIC 出站连接 Cloudflare edge。
- 现场 `--protocol http2` 测试成功注册 tunnel connector，并让公网 hostname 返回 Cloudflare Access 登录跳转。
- 按 Legion workflow 进入 `brainstorm`，创建 follow-up task contract，并进入 `git-worktree-pr` envelope。
- 已在 `hosts/axiom/default.nix` 的 axiom cloudflared `extraConfig` 添加 `protocol = "http2"`。
- 验证通过 targeted config eval、cloudflared service ExecStart eval 和 axiom toplevel dry-run；`nix flake check --no-build` 命中既有 `mkApp` path/string 问题，记录为非本次实现缺口。
- review-change PASS，无阻塞项；security lens 已覆盖 tunnel transport/protocol boundary。

### 进行中

- 生成 reviewer-facing walkthrough 和 PR body，随后进入 wiki writeback。

### 阻塞/待定

- 真实系统部署和 `cloudflared.service` 重启需要 root/sudo 权限；当前会话没有 passwordless sudo。
- 临时用户态 HTTP/2 connector 仍在运行以维持服务，部署永久修复后需要清理或确认保留。

---

## 关键文件

- **`hosts/axiom/default.nix`** [planned]
  - 作用: axiom host-level cloudflared extraConfig 真源。
- **`.legion/tasks/axiom-cloudflared-http2-transport/docs/rfc.md`** [created]
  - 作用: low-risk design-lite source of truth。

---

## 关键决策

| 决策 | 原因 | 替代方案 | 日期 |
|------|------|----------|------|
| 固定 cloudflared transport 为 HTTP/2 | 当前 fake-ip/UDP 路径导致默认 QUIC 持续 timeout，HTTP/2 测试已成功注册 edge | 调整 Clash fake-ip/DNS 或放通 QUIC，但范围更大且影响全局网络 | 2026-05-28 |

---

## 快速交接

**下次继续从这里开始：**

1. 完成 wiki writeback 后提交、rebase、push 并创建/跟进 PR。

**注意事项：**

- 不要直接改 `/etc/static/cloudflared/config.yml`；它由 Nix 生成并指向 `/nix/store`。
- 不要读取或输出 cloudflared credentials 内容。

---

*最后更新: 2026-05-28 14:43*

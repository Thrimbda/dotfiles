# Summary

## What

本 PR 为 `charlie` 声明式启用 `opencode-server`，以 launchd user agent 自启动，并通过 `cloudflared` 将 `opencode-charlie.0xc1.space` 回源到 `http://127.0.0.1:4096`。

同时同步修正 `modules/services/cloudflared.nix`、相关文档和 `bin/cloudflared-setup` 中的 `config` / `extraConfig` 漂移，确保模块实现、示例和操作文档一致。

## Why

目标是把原本依赖手工操作的 charlie 远程访问路径，收敛成一套可声明、可重建、可回滚的最小闭环：localhost 监听 + Cloudflare Tunnel 转发 + Cloudflare Access 鉴权。

这样可以在不直接暴露局域网/公网监听的前提下，为 opencode server 提供受控的外部访问入口，并把上线前置条件写入仓库文档。

## How

- `darwin/default.nix` 导入 cloudflared 模块。
- `hosts/charlie/default.nix` 新增 `opencode-server` launchd agent，固定监听 `127.0.0.1:4096`，并启用 cloudflared ingress 到 localhost。
- `modules/services/cloudflared.nix` / 文档 / setup 脚本统一使用 `extraConfig`，并将日志写入用户日志目录。

# Testing

- 参考：`.legion/tasks/charlie-opencode-server-cloudflare-access/docs/test-report.md`
- ✅ `bash -n bin/cloudflared-setup`
- ✅ `nix-instantiate --parse darwin/default.nix`
- ✅ `nix-instantiate --parse hosts/charlie/default.nix`
- ✅ `nix-instantiate --parse modules/services/cloudflared.nix`
- ✅ `nix eval .#darwinConfigurations.charlie.config.system.build.toplevel.drvPath --raw`
- ✅ `nix eval .#darwinConfigurations.charlie.config.launchd.user.agents.opencode-server.serviceConfig.ProgramArguments --json`
- ✅ `nix eval .#darwinConfigurations.charlie.config.launchd.user.agents.cloudflared.serviceConfig.ProgramArguments --json`
- ✅ `nix build .#darwinConfigurations.charlie.config.system.build.toplevel`

# Risks / Follow-ups

- 安全审查结论为 **CONCERNS**（见 `docs/review-security.md`），主要风险是：
  - 当前主要依赖单层 Cloudflare Access 鉴权，尚无应用层第二道认证；
  - browser SSH 临时密码流程仍可能被误用；
  - 日志权限/留存/敏感信息治理仍需上线前补齐。
- 代码审查结论为 **PASS**（见 `docs/review-code.md`）；剩余仅有 `tunnelName` 双入口语义、`age/agenix` 提示文案不一致两个非阻塞建议。
- 已修复先前阻塞 `charlie` 求值/构建的 Darwin 导入缺失问题：`darwin/default.nix` 现已导入 `../modules/dev/playwright.nix`。
- 仍需在真实 `charlie` 主机上执行 `darwin-rebuild switch` 做运行态验证。

# Manual steps

1. 在 `charlie` 上执行 `sudo darwin-rebuild switch --flake .#charlie`。
2. 验证本机服务：
   - `launchctl list | grep opencode-server`
   - `curl -I http://127.0.0.1:4096`
   - `launchctl list | grep cloudflared`
3. 在 Cloudflare Zero Trust 控制台为 `opencode-charlie.0xc1.space` 创建 **Access self-hosted application**。
4. 在控制台配置目标**邮箱**策略并启用 **MFA**。
5. 分别验证：授权邮箱可访问、未授权邮箱被拒绝，并保留审计记录。

# Links

- Plan: `.legion/tasks/charlie-opencode-server-cloudflare-access/plan.md`
- RFC: `.legion/tasks/charlie-opencode-server-cloudflare-access/docs/rfc.md`
- Test report: `.legion/tasks/charlie-opencode-server-cloudflare-access/docs/test-report.md`
- Code review: `.legion/tasks/charlie-opencode-server-cloudflare-access/docs/review-code.md`
- Security review: `.legion/tasks/charlie-opencode-server-cloudflare-access/docs/review-security.md`
- Walkthrough: `.legion/tasks/charlie-opencode-server-cloudflare-access/docs/report-walkthrough.md`

# 交付 walkthrough：charlie 上声明式启用 opencode-server 并通过 Cloudflare Access 暴露

## 建议 PR 标题

- `feat(charlie): declaratively expose opencode-server via Cloudflare Access`

## 目标与范围

本次改动面向 `charlie` 主机，为 `opencode serve` 增加可声明、可重建的 Darwin 自启动配置，并通过 `cloudflared` 将 `opencode-charlie.0xc1.space` 回源到 `http://127.0.0.1:4096`，把对外访问收敛到 Cloudflare Tunnel + Access 链路。

绑定 scope（见 `plan.md`）：

- `darwin/default.nix`
- `hosts/charlie/default.nix`
- `modules/services/cloudflared.nix`
- `docs/cloudflare-zero-trust.md`
- `docs/charlie-macos-ssh-config.md`
- `bin/cloudflared-setup`

## 设计摘要

设计结论来自 `plan.md` 与 `docs/rfc.md`：

- `opencode-server` 以 `launchd.user.agents.opencode-server` 运行，固定监听 `127.0.0.1:4096`，避免直接监听局域网/公网接口。
- `cloudflared` 继续复用 Darwin user agent 方案，将单一 hostname `opencode-charlie.0xc1.space` 转发到 `http://127.0.0.1:4096`，并保留 `http_status:404` 兜底。
- Cloudflare Access 不是可选增强，而是上线前置门禁；必须在控制台创建 self-hosted application，并配置目标邮箱 + MFA 后，才算真正对外发布。
- 本次同时消除了本任务范围内 `config` / `extraConfig` 的文档与脚本漂移，降低后续误配风险。

参考：

- 任务契约：`/Users/c1/dotfiles/.legion/tasks/charlie-opencode-server-cloudflare-access/plan.md`
- 详细设计：`/Users/c1/dotfiles/.legion/tasks/charlie-opencode-server-cloudflare-access/docs/rfc.md`

## 改动清单

### 1. Darwin 主链路接通

- `darwin/default.nix`
  - 导入 `../modules/services/cloudflared.nix`，让 Darwin 侧可以正式启用 cloudflared 模块。

### 2. charlie 主机新增 opencode-server 自启动与 tunnel 配置

- `hosts/charlie/default.nix`
  - 新增 `launchd.user.agents.opencode-server`。
  - 以绝对路径 `/Users/c1/.opencode/bin/opencode serve --hostname 127.0.0.1 --port 4096` 启动，避免 launchd PATH 漂移。
  - 显式注入 `HOME`、`OPENCODE_ENABLE_EXA`、`OPENCODE_EXPERIMENTAL`。
  - 日志输出落到 `/Users/c1/Library/Logs/`，不再写入 `/tmp`。
  - 启用 `modules.services.cloudflared`，声明 tunnel ID、凭证文件、`warpRouting.enabled = false`，并将 `opencode-charlie.0xc1.space` 回源到 localhost。

### 3. cloudflared 模块与示例一致性修正

- `modules/services/cloudflared.nix`
  - 保持 Darwin user agent 写入用户日志目录。
  - 注释与示例统一使用 `extraConfig`，与模块实际行为对齐。

### 4. 文档与脚本同步

- `docs/cloudflare-zero-trust.md`
  - 补齐 charlie 的部署/验证主流程，并把 Access 明确写成上线门禁。
- `docs/charlie-macos-ssh-config.md`
  - 补齐 `opencode-server` launchd 示例，和主机实际配置保持一致。
  - 明确 Access self-hosted application + 邮箱 + MFA 是外部必做步骤。
- `bin/cloudflared-setup`
  - 生成/示例片段改为 `extraConfig`，避免继续传播旧字段名。

## 评审结论吸收

- `docs/review-code.md`：结论为 **PASS**。主链路配置、文档和示例已基本对齐；仅剩 `tunnelName` 双入口语义、`age/agenix` 提示文案不一致两个非阻塞建议。
- `docs/review-security.md`：结论为 **CONCERNS**，但不是阻塞合入。当前主要风险：
  - 现在主要依赖单层 Cloudflare Access 鉴权，尚无应用层第二道认证；
  - browser SSH 的临时密码流程仍可能被误当成常规流程；
  - 日志权限、留存与敏感信息治理仍需上线前补齐约定。

## 如何验证

测试结论见：`/Users/c1/dotfiles/.legion/tasks/charlie-opencode-server-cloudflare-access/docs/test-report.md`

### 已完成的静态验证

- `bash -n bin/cloudflared-setup`
  - 预期：通过。
- `nix-instantiate --parse darwin/default.nix`
- `nix-instantiate --parse hosts/charlie/default.nix`
- `nix-instantiate --parse modules/services/cloudflared.nix`
  - 预期：以上 3 个文件均通过语法解析。

### 已补齐的构建阻塞修复

- 在继续调试后，定位到 `charlie` 构建失败的首个直接根因是：`darwin/default.nix` 未导入 `../modules/dev/playwright.nix`，导致 `hosts/charlie/default.nix` 中的 `modules.dev.playwright.enable = true;` 缺少选项定义。
- 通过补导入该模块后，以下命令已通过：
  - `nix eval .#darwinConfigurations.charlie.config.system.build.toplevel.drvPath --raw`
  - `nix eval .#darwinConfigurations.charlie.config.launchd.user.agents.opencode-server.serviceConfig.ProgramArguments --json`
  - `nix eval .#darwinConfigurations.charlie.config.launchd.user.agents.cloudflared.serviceConfig.ProgramArguments --json`
  - `nix build .#darwinConfigurations.charlie.config.system.build.toplevel`

### 建议的人工验证

在 `charlie` 上执行：

```bash
sudo darwin-rebuild switch --flake .#charlie
launchctl list | grep opencode-server
curl -I http://127.0.0.1:4096
launchctl list | grep cloudflared
```

预期：

- `opencode-server` 与 `cloudflared` 均已注册并运行；
- `curl -I http://127.0.0.1:4096` 返回 opencode server 响应；
- 外部访问仍需依赖 Cloudflare Access 放行后才可用。

然后在 Cloudflare Zero Trust 控制台完成：

1. 为 `opencode-charlie.0xc1.space` 创建 self-hosted Access application。
2. 配置目标邮箱策略并启用 MFA。
3. 验证授权邮箱可访问、未授权邮箱被拒绝，并保留审计记录。

## 风险与回滚

### 主要风险

- 安全审查结论仍为 **CONCERNS**：当前主要依赖单层 Access 鉴权，若 Access 漏配、误放宽或会话被盗用，暴露面会直接扩大。
- `docs/charlie-macos-ssh-config.md` 中的 browser SSH 临时密码流程仍有误用风险，应视为 break-glass 而非常规路径。
- 虽然 `nix build` 已通过，但仍未在真实 `charlie` 主机上执行 `darwin-rebuild switch` 与运行态验证。

### 回滚方式

按 RFC 建议顺序执行：

1. 先在 Cloudflare 侧禁用/移除 `opencode-charlie.0xc1.space` 的 Access 应用或公网入口。
2. 在仓库中撤销 `opencode-server` 与 `modules.services.cloudflared` 的启用配置，并重新 `darwin-rebuild switch --flake .#charlie`。
3. 验证公网 hostname 不可访问，且本机不再保留对应 agent/监听。

## 未决项与下一步

- 在 Cloudflare 控制台补完 Access self-hosted application、目标邮箱、MFA 与拒绝测试。
- 明确签收安全审查里的 CONCERNS，尤其是：
  - 是否为 opencode 增加第二层认证；
  - 是否把 browser SSH 临时密码流程单独降级为 break-glass 文档；
  - 是否补齐日志权限、留存与敏感信息治理要求。

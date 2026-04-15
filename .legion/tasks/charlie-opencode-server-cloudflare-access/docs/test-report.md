# 测试报告

## 范围

- `darwin/default.nix`
- `hosts/charlie/default.nix`
- `modules/services/cloudflared.nix`
- `docs/cloudflare-zero-trust.md`
- `docs/charlie-macos-ssh-config.md`
- `bin/cloudflared-setup`

## 执行命令

```bash
git diff -- darwin/default.nix hosts/charlie/default.nix modules/services/cloudflared.nix docs/cloudflare-zero-trust.md docs/charlie-macos-ssh-config.md bin/cloudflared-setup
git status --short -- darwin/default.nix hosts/charlie/default.nix modules/services/cloudflared.nix docs/cloudflare-zero-trust.md docs/charlie-macos-ssh-config.md bin/cloudflared-setup
bash -n bin/cloudflared-setup
nix-instantiate --parse darwin/default.nix >/dev/null
nix-instantiate --parse hosts/charlie/default.nix >/dev/null
nix-instantiate --parse modules/services/cloudflared.nix >/dev/null
nix eval .#darwinConfigurations.charlie.config.system.build.toplevel.drvPath --raw
nix eval .#darwinConfigurations.charlie.config.launchd.user.agents.opencode-server.serviceConfig.ProgramArguments --json
nix eval .#darwinConfigurations.charlie.config.launchd.user.agents.cloudflared.serviceConfig.ProgramArguments --json
```

## 结果

- ✅ `bash -n bin/cloudflared-setup` 通过
- ✅ `nix-instantiate --parse` 对 3 个 Nix 文件均通过
- ✅ 目标改动保持在预期 scope 内
- ✅ `nix eval .#darwinConfigurations.charlie.config.system.build.toplevel.drvPath --raw` 通过
- ✅ `nix eval .#darwinConfigurations.charlie.config.launchd.user.agents.opencode-server.serviceConfig.ProgramArguments --json` 通过
- ✅ `nix eval .#darwinConfigurations.charlie.config.launchd.user.agents.cloudflared.serviceConfig.ProgramArguments --json` 通过
- ✅ `nix build .#darwinConfigurations.charlie.config.system.build.toplevel` 通过

## 修复项

- 先前阻塞 `darwinConfigurations.charlie` 求值的错误是 Darwin 导入链缺少 `../modules/dev/playwright.nix`，导致 `hosts/charlie/default.nix` 中的 `modules.dev.playwright.enable = true;` 找不到选项定义。
- 通过在 `darwin/default.nix` 中补导入该模块后，相关 `nix eval` 与 `nix build` 已恢复通过。

## 结论

- 本次变更的语法级静态检查通过。
- shell 脚本与 Nix 文件在当前 scope 内未发现语法错误。
- `charlie` 的主机级 Nix 求值与 `system.build.toplevel` 构建现已通过。
- 仍未在真实 `charlie` 主机上执行 `darwin-rebuild switch`，因此运行态验证仍需人工完成。

## 建议的人工验证

1. 在 `charlie` 上执行：
   ```bash
   sudo darwin-rebuild switch --flake .#charlie
   launchctl list | grep opencode-server
   curl -I http://127.0.0.1:4096
   launchctl list | grep cloudflared
   ```
3. 在 Cloudflare Zero Trust 中完成：
   - 为 `opencode-charlie.0xc1.space` 创建 self-hosted Access application
   - 配置目标邮箱 + MFA
   - 分别验证授权邮箱可访问、未授权邮箱被拒绝

## 备注

- 本次优先选择 `bash -n` 与 `nix-instantiate --parse`，因为仓库中没有与本任务直接对应的统一测试入口。
- 本次还补充了 `nix eval` 与 `nix build`，用于确认 `charlie` 的声明式配置已能完成主机级求值与 toplevel 构建。

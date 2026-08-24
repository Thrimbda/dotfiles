# Test Report: acorn-cybion-ingress

## 执行的命令

```sh
# worktree: .worktrees/acorn-cybion-ingress（Axiom 上构建，符合 AGENTS.md 禁令）
nix-instantiate --parse hosts/acorn/modules/{cybion,platform}.nix hosts/acorn/default.nix
nix build '.#nixosConfigurations.acorn.config.system.build.toplevel' -L
nix eval --raw '.#nixosConfigurations.acorn.config.systemd.services.nginx.serviceConfig.ExecStart'
grep/awk inspect /nix/store/qi3vwwrgvmd49a4vi50c9jp8cpiliddk-nginx.conf
nix eval '.#nixosConfigurations.acorn.config.programs.nix-ld.enable'
ls <toplevel>/etc/systemd/system/ | grep acme
```

## 结果

全部通过：

1. **语法**：三个改动文件 `nix-instantiate --parse` OK。
2. **构建**：acorn toplevel 在 Axiom 上评估+构建成功（`nixos-system-acorn-26.05.7813.0dd31db7e6db`）。
3. **nix-ld**：`programs.nix-ld.enable = true`（acorn 的 `mkForce false` 已移除，继承仓库基础配置；同一基础配置在 axiom 上已实证可运行 cybion 官方二进制）。
4. **nginx vhost**：生成的 nginx.conf 中 `server_name cybion.0xc1.wang` 块包含：`proxy_pass http://127.0.0.1:1858`、`Host`/`X-Forwarded-Proto https` 头、`proxy_buffering off`、`gzip off`、24h 超时、`client_max_body_size 0`，证书指向 `/var/lib/acme/cybion.0xc1.wang/`。
5. **ACME**：`acme-cybion.0xc1.wang.service` 单元存在于新 system closure（DNS-01 cloudflare，环境文件来自 agenix `cloudflare-dns-env`）。
6. **爆炸半径**：nginx.conf 中既有 8 个 vhost（1ex-portfolio、auth、auth-gateway、frps-acorn、opencode-axiom、pi-axiom、status-axiom、vault）全部保持原样。

## 为什么选择这些命令

改动是纯 NixOS 声明式配置，最强证据是"目标主机的 system closure 能构建 + 生成的 nginx.conf 内容正确 + 既有 vhost 未被扰动"，比单元测试更直接。端到端公网验证（https health、证书签发、worker 隧道）只能在部署后发生，已列入 RFC Verification 3-7 并在 rollout/validate 阶段执行。

## 跳过/遗留

- 公网验证（证书签发、https://cybion.0xc1.wang/health、worker 隧道）待 rollout 后按 RFC Verification 执行。

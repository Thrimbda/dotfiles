# 验证报告：Acorn Auth Mini 最新发布部署

## 发布来源与固定输出验证

- 官方 GitHub release API（通过 Axiom 已认证 `gh` 仅读取公开 metadata）报告当前 `latest` Linux x86_64 asset：
  - asset ID：`525860183`
  - asset 更新时间：`2026-08-23T05:19:25Z`
  - SHA-256：`12abb29b97abd5579760dfcd3761235d5beeb53de806403124a79db470562b36`
- 上述 SHA-256 转换为 Nix SRI：
  ```text
  sha256-Equym5er1VeXYN/NN2EjXVvutT3oBkAxJKedtHBWKzY=
  ```
- 下载的公开 release asset 与官方 SHA-256 一致；其 Nix fixed-output store path 为：
  ```text
  /nix/store/x1lq1dwbq3cbf50lcja22pswnfm8ygkn-525860183
  ```
- 匿名 GitHub REST API 在 Axiom 的共享出口达到 `core` rate limit（HTTP 403）；因此本次验证将已校验的公开 asset 注册为相同 fixed-output store path 后构建。该操作不读取或存储凭据，不改变声明中的 GitHub asset-ID URL；实际 `nixos-rebuild` 会复用 Axiom 的该 store source。

## Axiom 构建

通过：

```sh
nix build .#packages.x86_64-linux.auth-mini --no-link -L
nix build .#nixosConfigurations.acorn.config.system.build.toplevel --no-link -L
```

关键产物：

```text
/nix/store/8f078awxrgyb9qhk0igxfk5w03nzz0q7-auth-mini-latest-2026-08-23
/nix/store/9wbw949nhjs2g7jr0gjlxwy4bj5v8shi-nixos-system-acorn-26.05.7813.0dd31db7e6db
```

评估后的服务命令保持运行参数不变：

```text
.../auth-mini-latest-2026-08-23/bin/auth-mini --host 127.0.0.1 --port 7777 --db /var/lib/auth-mini/auth-mini.sqlite
```

## 部署前 Acorn 健康基线

只读检查结果：

```text
auth-mini.service = active
http://127.0.0.1:7777/web/ = HTTP 200
https://auth.0xc1.wang/ = HTTP 302 → /web/
```

本地 loopback `/` 的 API 404 为既有行为；公开 Nginx vhost 负责将根路径重定向到 `/web/`。

## 部署门禁

所需受支持命令为：

```sh
nixos-rebuild switch --flake .#acorn \
  --target-host c1@8.159.128.125 \
  --build-host localhost \
  --sudo --ask-sudo-password --use-substitutes -L
```

当前 Cybion executor 没有可用的交互 TTY/批准通道供 `--ask-sudo-password` 输入 Acorn sudo 密码。根据任务安全边界，未读取、复制、显示或注入任何 dotfiles 中的密码文件，因此部署尚未执行。

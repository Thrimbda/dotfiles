# RFC: acorn cybion ingress（cybion.0xc1.wang + nix-ld）

## 背景

cybion（控制端 + worker）已通过手工方式迁移到 acorn：二进制用 patchelf 指向捆绑在 `~/.cybion/lib/` 的 glibc/libgcc，因为 acorn 在 `hosts/acorn/modules/platform.nix` 里 `programs.nix-ld.enable = lib.mkForce false`。该方案有三个问题：

1. cybion 内置自更新会下载官方未补丁二进制，替换后无法启动（只能回滚，永远升不了级）；
2. 服务只能通过 SSH 隧道访问，没有公网入口，worker 配对 URL 也只能是 localhost；
3. 捆绑库是仓库之外的隐形状态，重装时不可复现。

axiom 与 acorn 共用仓库根 `default.nix` 的 nix-ld 基础配置（`programs.nix-ld.enable = true`，libraries 含 `stdenv.cc.cc.lib` 等），cybion 官方二进制在 axiom 上零补丁直接运行——已在本次迁移前的本地部署中实证。

## Options

### A. 启用 nix-ld + nginx vhost + Cloudflare DNS-01（推荐）

- 删除 acorn `platform.nix` 中的 `mkForce false` 覆盖，继承仓库基础 nix-ld 配置；
- 新增 `hosts/acorn/modules/cybion.nix`：`cybion.0xc1.wang` vhost 反代 `127.0.0.1:1858`，ACME 走现有 `modules.services.nginx.cloudflareDnsAcme`（token 来自 `hosts/acorn/secrets/cloudflare-dns.env.age`，agenix 解密到 `/run/agenix/cloudflare-dns-env`）；
- 用同一 token 调 Cloudflare API 创建 DNS-only A 记录 `cybion.0xc1.wang → 8.159.128.125`（与 `auth.0xc1.wang` 等现有记录一致；wiki 决策要求新公网 hostname 的 DNS 记录属于交付物）；
- 部署后把 acorn 上的 patchelf 二进制换回官方原版，删除 `lib/` 捆绑目录，重启两个进程。

优点：自更新恢复正常；DNS/证书/反代全部走仓库既有模式（vaultwarden.nix、auth-mini.nix 先例）；无新增基础设施。
缺点：nginx 配置变更与 auth/vault 同机同进程，存在共享爆炸半径（用纯增量 vhost + switch 时 nginx config test 缓解）。

### B. 保持 patchelf 方案，仅加 nginx 暴露

优点：不动平台配置。
缺点：自更新永久失效；捆绑库不可复现；违背仓库"以 Nix 声明式管理主机"的原则。用户已明确否决。

### C. 把 cybion 打进 Nix 包（buildRustPackage + npm web 构建）

优点：完全声明式，二进制进 nix store。
缺点：需要在仓库维护 Cargo.lock/vendor 与前端构建，clone 私有源码进仓库；与上游"单二进制 + 自更新"的分发模型冲突（store 路径只读，自更新不可用）；工作量与后续维护成本远超收益。用户已明确否决（不做 systemd/声明式服务）。

## Decision

选 A。具体形态：

- `platform.nix`：仅删除一行 `programs.nix-ld.enable = lib.mkForce false;`。
- `cybion.nix`（新文件，仿 vaultwarden.nix 的模块内聚模式）：
  - `modules.services.nginx.cloudflareDnsAcme.hosts = [ "cybion.0xc1.wang" ];`（listOf 语义与 auth-mini/vaultwarden 的列表自动合并）
  - vhost：`onlySSL = true; useACMEHost`，`client_max_body_size 0`（对齐 mkNodeProxyVhost 先例：cybion 文件对象上传应用层不设限，低于应用的代理上限会制造意外 413）
  - 反代 `http://127.0.0.1:1858`，SSE 关键参数：`proxy_buffering off`、`proxy_request_buffering off`、`proxy_cache off`、`gzip off`、`proxy_read/send_timeout 24h`（完整复制 mkNodeProxyVhost 的 extraConfig 形态，与 status/opencode/pi 三个既有长连接 vhost 一致）
  - 头：`Host $host`（Auth Mini audience 绑定 host）、`X-Forwarded-Proto https`（控制端据此生成 https 配对 URL）
  - 不设置 Upgrade/Connection：cybion 服务端只有 SSE，没有 WebSocket（tungstenite 仅用于访问本机 Chrome CDP 的客户端侧）
- `default.nix`：imports 加 `./modules/cybion.nix`。
- 认证边界：cybion 自带 Auth Mini JWT + root_user_id + 设备 token，nginx 直通，不套 auth-mini-gateway（gateway 的 cookie/browser 流程会挡住 `/api/executors/*` 机器接口；vaultwarden 先例）。
- 防火墙不动：443 已在 `platform.nix` mkForce 列表中开放，80 保持关闭（DNS-01 不需要 80）。

## Rollback

- 配置层：`git revert` PR 后用同一 nixos-rebuild 命令重新部署，或在 acorn 上切到上一代 generation（`nixos-rebuild switch --rollback` 等价操作）；nix-ld 重新被禁用后官方二进制停止工作，需重新应用 patchelf 兜底（步骤已在本任务 log 留存）。
- DNS 层：CF API 删除 A 记录。
- 服务层：acorn 上换回 patchelf 二进制即可继续以 SSH 隧道方式运行，数据目录不受影响。

## Verification

部署前（Axiom 上）：

1. `nix build` acorn 的 `system.build.toplevel`（只允许在 Axiom 构建），确认评估与构建通过；
2. 检查生成的 `nginx.conf` 含 `cybion.0xc1.wang` server 块、`client_max_body_size 64m`、SSE 相关指令，且既有 vhost 不受影响。

部署后：

3. acorn 上 `systemctl status acme-cybion.0xc1.wang.service` 证书签发成功；`nginx -t` 通过（switch 自带）；
4. acorn 上官方原版二进制直接启动（验证 nix-ld 生效），`/health` 返回 ok；
5. 从 Axiom：`curl --resolve cybion.0xc1.wang:443:8.159.128.125 https://cybion.0xc1.wang/health` 与公网 DNS 解析后的 `https://cybion.0xc1.wang/health` 均返回 ok（wiki patterns 要求同时验证 API/DoH 解析与 `--resolve` 直连）；
6. worker 日志确认 executor tunnel 仍连接 `http://localhost:1858`；
7. 既有 vhost 抽查：`https://auth.0xc1.wang/` 仍 302 到 `/web/`。

## 交付顺序

PR 合并 → 主工作区刷新 → CF DNS 记录 → AGENTS.md 规定的 nixos-rebuild 命令部署 → 换官方二进制并重启 → 公网验证 → walkthrough + wiki 写回。

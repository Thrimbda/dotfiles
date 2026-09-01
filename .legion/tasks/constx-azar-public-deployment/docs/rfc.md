# RFC: Const X on Azar at `constx.0xc1.wang`

## Executive Summary

在 Azar/Acorn 上将 `constxd` 运行在受限 systemd service 中，只绑定 `127.0.0.1:3210`。`constx.0xc1.wang` 通过现有 Auth Mini gateway 做同源浏览器认证，再由 Nginx 反代到该 loopback 服务。Cloudflare API token 只创建并核对 DNS-only A record，Acorn 现有 age 管理 DNS token 继续负责 DNS-01 ACME。不会写入应用 API key 或扩大任何 allowlist。

## Context / Evidence

- Const X 默认 open-by-loopback，不能直接暴露；外部入口必须自行提供 TLS 与认证。
- Acorn 的 Nginx、Auth Mini、gateway、443 listener 和 Cloudflare DNS-01 ACME 已处于运行状态；同一主机的 Cybion ingress 是已验证的 loopback/SSE/TLS 先例。
- 当前 Cloudflare token 可验证并可读 `0xc1.wang` zone，且 `constx.0xc1.wang` 无 A record。
- `constxd` binary 需要 Node `>=22.19.0`；目标 Nix configuration 提供 `nodejs_22` 22.23.2。编译需要 Node、Cargo 与 lockfile，运行时不需要 NPM/Cargo。

## Goals / Non-goals

目标：发布可回滚的 x86_64 Linux `constxd`、保护其公网访问、签发 TLS、创建精确 DNS record，并给出可验证的 runtime evidence。

非目标：修改 Const X 产品、预置模型凭据、执行真实模型任务、增删 Auth Mini 用户/allowlist、迁移至 Cloudflare Tunnel/Access，或重构其他 Acorn service。

## Decision

选择 Research 中的方案 A。

### Service

新增 `hosts/acorn/modules/constx.nix` 并由 `hosts/acorn/default.nix` 导入。

- 固定 release identity 为 `45c21f0a2f437cb11cb5e316c29d5ff08cbef471`，service `ExecStart` 指向 `/home/c1/.local/share/constx/releases/<sha>/constxd serve`；不能使用含糊的 latest path 或 `current` symlink。NixOS generation 是唯一的 service release / rollback 权威。
- release 先在 Azar 的 `c1` home 构建与 `doctor`，写入 SHA-256 后才允许 NixOS switch；binary 不含 token 或模型 key。
- `constxd.service` 以 `c1:users` 运行，使用 `/var/lib/constx` StateDirectory、`HOME` / `XDG_CONFIG_HOME` / `XDG_DATA_HOME` 指向该 state，`path = [ pkgs.nodejs_22 ]`，并以 `ExecStartPre` 确认可执行 binary 存在。
- 保持最小 hardening：`NoNewPrivileges`、`PrivateTmp`、`ProtectSystem=strict`、`ProtectHome=read-only`、受限 address families、`UMask=0077`、`Restart=on-failure`。不启用 native `[auth]`，因为 gateway 承担公网认证。

### Auth gateway and Nginx

在 `hosts/acorn/modules/auth-mini.nix` 添加一个 `constx` instance：

- public host `constx.0xc1.wang`，loopback gateway port `7782`，独立 `constx.sqlite` gateway state；依赖既有 `auth-mini.service` 与同一个加密 gateway environment。
- protected upstream `http://127.0.0.1:3210`，不启用 WebSocket。
- 对通用 helper 做向后兼容的可选 per-instance vhost / upstream extra config 扩展；既有 instance 不得到行为改动。
- Const X instance 使用 `client_max_body_size 22m`（应用仍限制每文件 20 MiB），`proxy_http_version 1.1`、`proxy_request_buffering off`、`proxy_buffering off`、`proxy_cache off`、`gzip off`、`proxy_connect_timeout 10s`、`proxy_send_timeout 24h`、`proxy_read_timeout 24h`、`proxy_intercept_errors off` 与 `proxy_next_upstream off`，并传递 Host / HTTPS forwarded headers。
- 所有 `/` upstream 请求保留既有 `auth_request /_auth`；匿名用户只会进入 gateway login redirect，不能到达 constxd。`/healthz` 是 gateway health endpoint，不转发到 constxd。
- 将 hostname 追加到现有 `modules.services.nginx.cloudflareDnsAcme.hosts`，使用 `onlySSL` / `useACMEHost`。443 firewall 不变，80 不开放。

### DNS / TLS

使用已验证的 `CF_DNS_API_TOKEN` 以幂等方式管理 `constx.0xc1.wang`：

1. switch 后确认 `constxd` loopback health、gateway unit 和 Nginx config 均健康；DNS-01 签证书不依赖公开 A record。
2. 若 Cloudflare API 查询没有同名 A record，创建 DNS-only `A constx.0xc1.wang → 8.159.128.125`；若有 record，只接受相同 IP 与 DNS-only 设置，否则停止并报告冲突。
3. 用 Cloudflare API、direct `curl --resolve` 与正常 hostname 三路核对，避免本地 Clash fake-IP DNS 误判。

Token 只存在于短生命周期 shell variable / curl config pipe 中；不通过命令行参数、文件、Nix expression、环境 dump 或 task evidence 写出。

## Milestones

1. 构建设计：写 Nix service/gateway 模块和严格 release staging procedure；先做 Nix evaluation，不做远端切换。
2. 发布 artifact：将精确 Git tree 传到 Azar `c1` home，单 job build，运行 `constxd doctor`，保存 release SHA-256 和构建输出摘要。
3. 系统切换：用户已指定 `axiom-tunnel` 为 build host、`azar` 为 target host；在本机把 owner-only password 文件交给 `nixos-rebuild --ask-sudo-password --sudo --build-host axiom-tunnel --target-host azar switch`，以新 system closure switch；确认 constxd/gateway/Nginx/ACME。
4. DNS and canary：创建/校验记录，验证 direct TLS、unauth redirect、已有用户 Browser login，最后由用户在 Settings 保存其自身 OpenAI configuration。

## Verification

| Claim | Evidence and negative path | Blocking policy |
| --- | --- | --- |
| C1 | Evaluate generated systemd/Nginx closure; inspect no public `3210`; post-switch check listener, service state, unauth redirect and direct loopback health. A public `3210`, bypassed `auth_request` or direct anonymous app response fails. | block-merge |
| C2 | Cloudflare API query/create result, ACME unit + certificate, `curl --resolve` to `8.159.128.125`, external hostname, and unchanged existing vhost samples. Existing conflicting DNS record or bad TLS fails. | block-merge |
| C3 | Generated Nginx config proves 22m + no buffering/long timeout; authenticated manual browser upload/SSE smoke proves runtime path. Missing directives or 413/buffered stream fails. | block-merge |
| C4 | Existing authorized user completes Browser login and sees the workbench; Settings initially reports no key until the user configures one. No user session is INCONCLUSIVE, not success. | block-stage |
| C5 | `rage` decryption remains in-process; Cloudflare verify / zone / record calls succeed; source/log/task grep and diff prove no plaintext credential. API failure or secret marker is a fail. | block-merge |

## Rollback

- 这是首次 Const X system service 部署，不存在前一个 Const X release。若 binary startup 失败，停止/移除新 `constxd` service 或回滚至前一 NixOS generation；不尝试切换不存在的 release symlink。
- 后续升级时，service SHA 与 NixOS generation 一起升级；回滚仍以先前 generation 为唯一权威，release 目录仅作为保留的 binary artifact，不承担 activation。
- If gateway or Nginx configuration fails, switch back to the previous generation; no existing vhost should be edited in place.
- If public DNS must be withdrawn, delete only the Cloudflare record ID created by this task after service rollback; do not touch same-name records that predate the task.
- Const X state is isolated under `/var/lib/constx`; rollback never deletes SQLite, workspace, blobs or logs.

## Observability

- `systemctl status constxd auth-mini-gateway-constx nginx acme-constx.0xc1.wang`
- `journalctl -u constxd -u auth-mini-gateway-constx -u nginx -u acme-constx.0xc1.wang`
- local `/api/health` and `/api/ready`; direct TLS `--resolve`; unauth gateway redirect; authenticated browser route.

## Open Questions

- The existing Auth Mini user must perform the actual Browser sign-in during Milestone 4. No surrogate user or test bypass will be created.

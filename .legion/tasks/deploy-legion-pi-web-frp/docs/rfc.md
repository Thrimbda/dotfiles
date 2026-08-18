# RFC: Axiom Legion Pi Web 经 Acorn FRP 暴露

> **Profile**: Standard
> **Status**: Approved
> **Created**: 2026-08-18

## Decision

在 Axiom 安装固定 Legion Pi profile 与 upstream PI WEB user services，复用现有 Auth Mini gateway、FRP 和 Acorn nginx，以 `https://pi-axiom.0xc1.wang` 提供经过认证的入口。

这是一项已有模式上的增量部署：不新增认证实现、secret、协议或 Nix 模块。

## Context

- Axiom 已运行 `frpc 0.66.0`，现有 Gatus/OpenCode 采用“本机 Auth Mini gateway -> FRP -> Acorn nginx”。
- Acorn 已运行 `frps`、nginx、Cloudflare DNS ACME 和 Auth Mini。
- Axiom 为 Node `v26.7.0`、npm `11.19.0`，但尚未安装 `pi` 或 `pi-web`；`c1` 当前 `Linger=no`。
- 固定版本：Pi core `0.84.2`，`@jmfederico/pi-web@1.202608.1`。PI WEB 要求 Pi `>=0.84.0`、Node `>=22.19.0`。
- PI WEB 官方要求只通过 trusted tunnel/VPN/authenticated reverse proxy 远程访问，不直接公开公网。

## Goals

- Axiom 上 Pi `verify` 返回 `READY`，PI WEB user services 持久运行。
- PI WEB 只监听 `127.0.0.1:8504`，公网流量必须经过 Auth Mini。
- Acorn 提供有效 HTTPS，HTTP/API/WebSocket/长连接可用。
- 现有 FRP、OpenCode、Gatus 和 Acorn 服务不回退。

## Non-goals

- PI WEB fleet/federation、Legion 自有 API、provider/model 凭证。
- browser/computer-use、PI WEB 上游修改、FRP PKI 迁移。
- 把 PI WEB package、config、data、sessions 或 Pi profile 提交到 Git。

## Topology

```text
Browser
  -> Acorn nginx :443 (pi-axiom.0xc1.wang + ACME)
  -> Acorn shared FRPS :18082
  -> Axiom frpc
  -> Axiom auth-mini-gateway :7782
  -> Axiom PI WEB :8504
  -> Axiom pi-web-sessiond
  -> /home/c1/.local/share/legion-pi/profile
```

边界说明：

- PI WEB `8504` 与 gateway `7782` 只绑定 loopback。
- FRPS `proxyBindAddr` 是共享的 server-wide 配置；`18082` 预期 wildcard-bound，但不加入 Acorn firewall allowlist。nginx 从 `127.0.0.1:18082` 访问。
- FRP 只映射 Auth Mini gateway，不映射 PI WEB；因此 Acorn 本机访问 `18082` 也不能绕过认证。
- Acorn nginx 仅允许 `Origin: https://pi-axiom.0xc1.wang` 的 PI WebSocket upgrade；foreign 或 missing Origin 在进入 Auth Mini gateway 前返回 `403`。普通 HTTP/API 不应用该检查。
- 公网仍只使用现有 `443`，不新增 firewall port。

## Axiom Runtime

持久路径：

- Pi profile：`/home/c1/.local/share/legion-pi/profile`
- PI WEB package prefix：`/home/c1/.local`
- PI WEB config：`/home/c1/.config/pi-web/config.json`，保持用户可写
- PI WEB data：`/home/c1/.local/share/legion-pi/pi-web`

`hosts/axiom/default.nix` 负责：

- 设置 `user.linger = true`；
- 通过 `modules.shell.zsh.envInit` 固定 profile runtime PATH、`PI_CODING_AGENT_DIR`、`PI_CODING_AGENT_SESSION_DIR`、`PI_SUBAGENT_PI_BINARY`、`PI_LENS_HOME`、`PI_WEB_DATA_DIR`、`PI_WEB_HOST=127.0.0.1`、`PI_WEB_PORT=8504`；
- 新增 `auth-mini-gateway-pi-axiom`，监听 `127.0.0.1:7782`，upstream 为 `http://127.0.0.1:8504`；
- 新增 FRP proxy `axiom-pi-web-http`：`127.0.0.1:7782 -> Acorn :18082`。

PI WEB unit 继续由 `pi-web install` 管理。Nix 不自建或覆盖 upstream units；unit 通过 `zsh -lc` 读取受管 login-shell 环境，避免升级和 `pi-web doctor` 漂移。

## Acorn Entry

- `hosts/acorn/default.nix` 新增 `pi-axiom.0xc1.wang` Cloudflare DNS ACME cert。
- `hosts/acorn/modules/auth-mini.nix` 复用 `mkNodeProxyVhost`，将该域名代理到 `127.0.0.1:18082`。
- 现有 helper 保留 Cookie、forwarded headers、WebSocket upgrade、无 buffering 与长超时。
- nginx HTTP `map` 将 PI WebSocket upgrade 分为 exact-origin allow 与 foreign/missing-origin deny；PI vhost 在 proxy 前 fail closed，其他 vhost 与非 WebSocket 请求不受影响。
- `18082` 不加入 firewall allowlist，并以 Nix 断言锁定。

## Deployment Order

1. 对 Axiom/Acorn 做 targeted `nix eval`，确认 env、linger、gateway、FRP proxy、vhost、cert 和 firewall。
2. 在 Axiom 从当前 worktree 执行 `nixos-rebuild switch --flake .#axiom --sudo --ask-sudo-password -L`。
3. 从 `/home/c1/Work/legion-mind` 安装并 verify `/home/c1/.local/share/legion-pi/profile`。
4. 以 `/home/c1/.local` prefix 安装 `@jmfederico/pi-web@1.202608.1`，运行 `pi-web install`、`doctor`、`status`、`version`。
5. 本机 PI WEB、Auth Mini gateway 和 frpc 全部通过后，才部署 Acorn。
6. Acorn 只允许从 Axiom 执行：

   ```bash
   nixos-rebuild switch --flake .#acorn --target-host c1@8.159.128.125 --build-host localhost --sudo --ask-sudo-password --use-substitutes -L
   ```

7. 验证 HTTPS、未登录 Auth Mini redirect，以及 `c1` 登录后的页面/API/WebSocket。

Acorn build、closure transfer 或 activation 任一步失败都立即停止；不在 Acorn build，不改用 SSH 或其他部署路径。

## Verification

- `nix eval`：Axiom linger/env/gateway/frpc/firewall；Acorn cert/vhost/firewall；两台 host toplevel derivation 可求值。
- Pi：首次 install、幂等复跑、`verify -> READY`。
- PI WEB：`doctor/status/version`；两个 user units active；service restart 后保持 active profile。
- Profile：只从 active `pi-web-sessiond` `/proc/<MainPID>/environ` 输出 exact-name allowlist，与 `zsh -lc` 和 canonical paths 对比，不输出其他环境变量。
- Listener：`8504/7782` 仅 loopback；`18082` wildcard listener 存在但 Acorn firewall deny。
- FRP：新 proxy 和既有三个 proxy 均 start success。
- Public：未登录请求进入 Auth Mini，不返回 PI WEB 内容；带 sentinel Cookie 的 foreign/missing-Origin WebSocket handshake 在 nginx edge 返回 `403`，证明拒绝发生在 gateway/PI WEB 前且不依赖认证状态；`c1` 作为 operator 登录后验证页面/API/exact-origin WebSocket 持续消息和一个无 provider call session view。证据不记录 Cookie、token 或 session 内容。
- Regression：现有 `status-axiom`、`opencode-axiom` 和 FRP 服务继续可用。

## Rollback

- PI WEB 失败：`pi-web uninstall` 停止并移除 user units，保留 config/data/profile 诊断。
- Axiom 失败：切回前一 Nix generation；恢复旧 gateway/frpc/env/linger。
- Acorn command 失败：停止并报告，不 fallback。
- Acorn 激活成功但新入口失败：撤销本任务 Acorn增量并重新执行同一规定命令。
- PR 若被关闭/放弃且配置已部署，先撤销 Axiom/Acorn 增量并验证旧服务，再清理 worktree。

## Risks and Residuals

- PI WEB 以 `c1` 权限运行，不是 sandbox；Auth Mini 之后的 operator 拥有该用户可及的 Agent/terminal 能力。
- WebSocket 只在握手时鉴权；已建立连接不会因后续 logout/session expiry 自动终止，疑似 session 泄露时必须主动断开连接。
- FRP 0.66 默认 TLS 加密并使用 token auth，但当前链不验证 frps certificate identity；主动 MITM 不在本任务 threat model 内，且本任务不把该链称为 mTLS。
- `node-pty` native install、Nix privilege、DNS/ACME 和交互式 Auth Mini 登录是执行期 gates；失败时阻塞，不降低验收。

## Alternatives

- **自建 Nix PI WEB service/package**：更声明式，但需维护 npm/native build 与 upstream 双服务/doctor contract，当前不采用。
- **独立 loopback FRPS**：可让 `18082` 真正 loopback-only，但会新增第二 control port、token、service 和 failure surface；host firewall 已提供所需隔离，当前不采用。
- **FRP 直连 PI WEB**：少一层组件，但会绕过认证，禁止。

## References

- `.legion/tasks/deploy-legion-pi-web-frp/plan.md`
- `hosts/axiom/default.nix`
- `hosts/acorn/default.nix`
- `hosts/acorn/modules/auth-mini.nix`
- `modules/services/frp.nix`
- `modules/shell/zsh.nix`
- `https://pi-web.dev/install`
- `https://pi-web.dev/config`
- `https://gofrp.org/en/docs/features/common/network/network-tls/`

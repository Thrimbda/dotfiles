# FRP Agenix Deploy

## Goal

为本仓库新增声明式 `frps` / `frpc` 部署：`aliyun-acorn` 运行 `frps`，`axiom` 运行 `frpc`，两端使用同一个强随机 token 做认证，并通过 agenix 加密保存。

## Problem

当前 `axiom` 已经有 autossh 反向 SSH 通道，但用户要求新增基于 frp 的部署路径。frp token 属于共享认证凭据，不能明文进入 Git 或 Nix store；同时服务配置需要纳入现有 dotfiles module 与 host 配置风格，避免手工维护运行时配置文件。

## Acceptance

- 新增可复用的 Linux `modules.services.frp` module，支持启用 `server` 或 `client`。
- `aliyun-acorn` 启用 `frps`，监听默认 `7000` 控制端口，并开放 `2225` 作为 `axiom` SSH proxy 端口。
- `axiom` 启用 `frpc`，连接 `8.159.128.125:7000`，将本机 `127.0.0.1:22` 暴露为远端 TCP `2225`。
- frp token 使用强随机字符串生成，写入 host-local agenix secret；两台 host 的 secret 解密后 token 一致。
- Nix store 中不能包含 token 明文；token 只能在 systemd 启动时从 `/run/agenix/frp-token` 注入运行时 TOML。
- `axiom` 和 `aliyun-acorn` 的 NixOS 配置能通过 eval / dry-run build；frp TOML 模板能通过 `frpc verify` / `frps verify`。
- 变更通过 Legion worktree/PR workflow 交付，不混入主工作区已有无关 dirty 改动。

## Scope

- 新增 `modules/services/frp.nix`。
- 更新 `hosts/aliyun-acorn/default.nix` 与 `hosts/axiom/default.nix` 的 frp 相关配置。
- 新增 `hosts/aliyun-acorn/secrets/*` 与 `hosts/axiom/secrets/frp-token.age` / `secrets.nix`。
- 新增 `.gitattributes` 将 `*.age` 标记为 binary，避免 Git whitespace checks 把密文当作文本解析。
- 新增本任务的 Legion contract、设计、验证、review、walkthrough 与 wiki evidence。

## Non-goals

- 不替换或删除现有 autossh reverse SSH 配置。
- 不为 frp dashboard、metrics、TLS 或多 proxy 拓扑做额外设计。
- 不修改 Cloudflare Tunnel、Gatus 或 opencode-server 配置。
- 不整理主工作区已有 unrelated dirty 改动。

## Assumptions

- `aliyun-acorn` 的公网地址仍是 `8.159.128.125`。
- `aliyun-acorn` 的 agenix identity 使用 `/home/c1/.ssh/id_ed25519`，`axiom` 使用 `/etc/ssh/ssh_host_ed25519_key`。
- frp 0.65.0 的 TOML 配置支持 `[auth] method = "token"` 与 `token = "..."`。
- 远端 `2225` 避开现有 autossh 端口 `2222`、`2223`、`2224`。

## Constraints

- token 明文不得写入仓库、日志、PR body 或最终回复。
- token 不能通过 Nix 字符串插值进入 store。
- 保持模块最小化，遵循现有 `modules.services.*` 风格。
- 所有提交必须来自 `.worktrees/frp-agenix-deploy` 分支，不直接提交主工作区。

## Risks

- 开放 `7000` 和 `2225` 是公网入口，认证 token 强度和 secret 解密链路是主要安全边界。
- systemd 启动时渲染 TOML 若权限或 RuntimeDirectory 设置错误，服务会启动失败。
- 当前本地用户不能读取 `axiom` host 私钥，无法直接用该私钥做解密验收，只能验证 recipient 已写入并用用户私钥验证两份 age 内容一致。

## Design Summary

采用一个轻量 `modules.services.frp` module，使用 `pkgs.formats.toml` 生成包含 `@FRP_TOKEN@` 占位符的 TOML 模板。systemd `ExecStartPre` 从 agenix 解密后的 `/run/agenix/frp-token` 读取 token，渲染到 `/run/frps/frps.toml` 或 `/run/frpc/frpc.toml`，再启动 frp。这样 Nix store 只保存模板和渲染脚本，不保存 token 明文。

## Phases

1. 建立 Legion task contract 与 design-lite RFC。
2. 在 isolated worktree 内实现 frp module、host 配置和 age secret。
3. 验证两台 host 配置、frp TOML 与 secret 一致性。
4. 进行实现 review、安全边界检查与 walkthrough。
5. 完成 wiki writeback、commit、push 和 PR lifecycle。

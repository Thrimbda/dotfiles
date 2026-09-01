# Const X Azar Public Deployment

## 元数据

- `name`: Const X Azar Public Deployment
- `task-id`: `constx-azar-public-deployment`
- `status`: active
- `risk`: high
- `profile`: Strict
- `contract`: 用户于 2026-09-01 明确授权，将当前 Const X 部署到 SSH 别名 `azar` 对应机器，并通过 `constx.0xc1.wang` 对外提供服务；可使用 dotfiles 中受 age 保护的 Cloudflare API 凭据。

## 目标

在 `azar`（运行时主机名 `aliyun-acorn`）部署来自 Const X 已合并源码 `45c21f0a2f437cb11cb5e316c29d5ff08cbef471` 的 `constxd`，使其仅监听 loopback，并通过现有 Acorn Nginx + Auth Mini gateway 在 `https://constx.0xc1.wang` 提供受保护的访问。

## 问题陈述

Const X 当前只在本机的 loopback LaunchAgent 中运行。Azar 已有 Nginx、Auth Mini、gateway 和 Cloudflare DNS-01 证书能力，但没有 `constxd`、Node、构建工具、公开 vhost 或目标 DNS 记录。不能用裸露的端口、未认证的反代或明文凭据替代这些边界。

## 验收标准

- [ ] `constxd` 以受 systemd 监督的 `c1` 服务运行，使用 x86_64 Linux release binary，监听 `127.0.0.1:3210`；重启后 `/api/health` 与 `/api/ready` 成功。
- [ ] `constx.0xc1.wang` 有指向 Azar 的 Cloudflare DNS-only A 记录，Nginx 通过现有 age 管理的 Cloudflare DNS-01 凭据签发并加载 TLS 证书。
- [ ] 公开 vhost 先经过独立的现有 Auth Mini gateway；未认证请求不会到达 Const X，已认证请求可保留 SSE、长响应和单文件 20 MiB 附件所需的代理语义。
- [ ] 不把 Cloudflare token、Auth Mini gateway 环境、OpenAI API key、认证 cookie 或 SQLite 数据写入 Git、Nix store、日志或任务文档。
- [ ] 记录唯一、可执行的回滚路径：service 固定绑定本次 SHA，NixOS generation 是唯一的服务回滚权威；首次部署失败时停止/移除新 service，任何场景均按创建者 record ID 删除新增 DNS record，现有 Acorn 入口不受影响。

## 假设 / 约束 / 风险

- 假设：`constx.0xc1.wang` 是用户指定的 hostname，现有 Auth Mini 的 allowlist 已包含目标操作者；不新增用户或放宽 allowlist。
- 约束：Const X 本身不公开监听；不复制或打印 age 密文/明文 token；不预置 OpenAI API key，操作者首次登录后可在 Settings 配置。
- 约束：本地 dotfiles 主工作区已有用户修改；所有本任务写入仅在 `.worktrees/constx-azar-public-deployment`。
- 约束：用户已授权使用本机 owner-only 的非版本化 sudo password 文件；NixOS 只能在 Axiom 作为 build host、Azar 作为 target host 的 `--ask-sudo-password --sudo` 路径执行。密码绝不进入 worktree、Nix store、argv、日志或 Git。
- 风险：远端仅 1.8 GiB RAM；release build 必须限制并行度，并在切换前验证完整性和 Node 版本。
- 风险：认证后的浏览器/OTP 路径需要真实既有用户会话；不能把未登录浏览器截图当作认证成功证据。

## 要点

- 复用 Acorn 已运行的 Auth Mini gateway，而不是公开未认证 constxd 或引入第二套 Access policy；每个 hostname 保持独立 gateway instance 与 host-only cookie。
- 将 `constxd` 作为 loopback systemd 服务；持久数据放在 systemd `StateDirectory`，service 固定指向本次 SHA 的 `c1` release 目录；NixOS generation 是唯一的服务版本和回滚权威，不使用 `current` symlink。
- Nginx vhost 要显式关闭 upstream buffering、保留长 timeout，并将 request body 上限提升至与 Const X 附件边界相容的大小。
- 使用 Cloudflare API token 仅创建/核对目标 DNS record；现有 Acorn age secret 仅由 ACME 使用，二者均不落盘到变更中。

## 范围

包含：Acorn 的最小 Nix service/ingress 配置、受保护 gateway instance、release 构建与文件完整性、Cloudflare DNS record、NixOS switch、TLS/loopback/public 无认证 smoke、运行时与回滚证据。

不包含：Const X 产品功能改动、OpenAI key 配置或真实模型调用、Auth Mini allowlist/策略扩张、Cloudflare Tunnel/Access 拓扑修改、其他 Acorn 服务重构、将凭据迁入仓库。

## 设计索引

- 现状与风险：`docs/research.md`
- 发布设计、验证与回滚：`docs/rfc.md`
- 对抗式设计审查：`docs/review-rfc.md`

## 关键主张

| Claim | 主张 | 类型 / 时机 | criticality / policy |
| --- | --- | --- | --- |
| C1 | Const X 只在 Azar loopback 可达，公网入口必须先经独立 Auth Mini gateway。 | objective / now | critical / block-merge |
| C2 | `constx.0xc1.wang` DNS、TLS 和反代准确指向目标服务，且不影响现有 Acorn vhost。 | objective / now | high / block-merge |
| C3 | Nginx/gateway 保持 SSE、长响应与 20 MiB 单文件上传所需的代理边界。 | formal + objective / now | high / block-merge |
| C4 | 已认证真实用户可进入工作台；首次 OpenAI Settings 配置由该用户完成，不伪造模型可用性。 | objective / now | high / block-stage |
| C5 | 现有 Cloudflare age token 被安全使用且不会泄漏。 | objective / now | critical / block-merge |

## 阶段概览

1. `brainstorm`：完成稳定 contract 与运行时摸底。
2. `spec-rfc -> review-rfc`：确定 auth、service、DNS/TLS、验证与回滚设计。
3. `engineer`：在隔离 worktree 实现最小 Nix 配置与发布脚本/证据入口。
4. `verify-change -> review-change`：执行 Nix、release、DNS、运行时和安全验证。
5. `delivery`：提交、PR、合并、远端切换、真实 canary、清理 worktree 与刷新主工作区。

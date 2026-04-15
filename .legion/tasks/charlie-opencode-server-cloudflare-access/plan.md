# charlie 上 opencode server Cloudflare Access 暴露与自启动

## 任务契约

### 问题定义

当前仓库里 `charlie` 已具备 opencode 运行环境变量与 cloudflared 相关素材，但还没有一套可声明、可重建、可回滚的方案，让 opencode server 在 macOS 上随重启自动拉起，并且仅通过 Cloudflare Tunnel + Access 以邮箱策略暴露出去。

### 验收标准

1. `charlie` 上存在可由 Nix 管理的 `opencode-server` 自启动配置，监听 `127.0.0.1:4096`。
2. Darwin 侧可导入并启用 `modules/services/cloudflared.nix`，将单一 hostname 转发到 `http://127.0.0.1:4096`。
3. 任务文档明确 Cloudflare Access 邮箱策略的上线前置步骤、验证方式与回滚方式。
4. `config` / `extraConfig` 漂移在本次涉及文件中被消除，避免后续误配。
5. 产出 `test-report.md`、`review-code.md`、`review-security.md`、`report-walkthrough.md`、`pr-body.md`。

### 假设

- `charlie` 已存在可用的 Cloudflare tunnel 凭证文件：`hosts/charlie/secrets/cloudflared-credentials.age`。
- opencode 二进制位于 `/Users/c1/.opencode/bin/opencode`，并可在 `charlie` 上由用户级 launchd 直接执行。
- Cloudflare Zero Trust / Access 组织已存在，后续可手工创建按邮箱控制的 Access 应用。
- `127.0.0.1:4096` 当前无关键冲突服务。

### 约束

- `plan.md` 是唯一任务契约；详细设计放到 `docs/rfc.md`。
- 服务不得监听 `0.0.0.0`，避免绕过 Access。
- 改动尽量限制在 `charlie` 与 cloudflared 文档/示例一致性修正上，不扩散到 atlas。
- 不等待设计批准，按 PR 驱动延迟批准推进。

### 风险

- **分级**：High
- **标签**：`risk:high`
- **理由**：本次变更会把本机能力通过 Cloudflare 入口暴露给外部，并涉及 launchd、自定义隧道 ingress、Access 前置配置与回滚路径；虽然服务仅监听 localhost，但安全边界与故障面都明显扩大，因此按 High 处理并补齐 RFC、安全评审与回滚说明。

## 目标

为 charlie 主机增加一个随重启自动启动的 opencode server，并通过 Cloudflare Access 以邮箱访问控制方式暴露，同时修复阻塞 charlie Nix 求值/构建的相关配置问题。


## 要点

- 在现有 Darwin/launchd 与 cloudflared 模式上最小增量实现 opencode server 的声明式配置。
- 把 Cloudflare Access 暴露所需的 tunnel ingress、服务端口与运行方式写入主机配置和任务文档。
- 补齐验证、评审与可直接用于 PR 的交付文档，尽量减少后续人工操作。
- 在不扩大不必要变更面的前提下，修复阻塞 charlie Nix 求值/构建的 pre-existing 问题。


## 范围

- darwin/default.nix
- hosts/charlie/default.nix
- modules/services/cloudflared.nix
- docs/cloudflare-zero-trust.md
- docs/charlie-macos-ssh-config.md
- bin/cloudflared-setup

## Design Index

- RFC: `.legion/tasks/charlie-opencode-server-cloudflare-access/docs/rfc.md`
- RFC 审查: `.legion/tasks/charlie-opencode-server-cloudflare-access/docs/review-rfc.md`

## 阶段概览

1. **设计** - 明确风险、可执行路径、Cloudflare Access 上线门禁与回滚方案
2. **实现** - 落地 `opencode-server` launchd、自启动 cloudflared 配置与文档修正
3. **验证与交付** - 运行验证/评审并生成 walkthrough 与 PR body

---

*创建于: 2026-04-12 | 最后更新: 2026-04-12*

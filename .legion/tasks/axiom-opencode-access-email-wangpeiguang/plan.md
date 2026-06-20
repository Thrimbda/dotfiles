# Axiom Opencode Access Email Allowlist

## Contract

- **name**: Axiom opencode Cloudflare Access email allowlist update
- **taskId**: `axiom-opencode-access-email-wangpeiguang`
- **goal**: 将 `wangpeiguangwpg@gmail.com` 纳入 `opencode-axiom.0xc1.space` 的 Cloudflare Access 可访问邮箱集合，并同步仓库中的当前真源记录。
- **problem**: `opencode-axiom.0xc1.space` 通过 Cloudflare Access 暴露 opencode，但当前记录的 exact-email allowlist 只包含 `c1@ntnl.io`、`siyuan.arc@gmail.com` 和 `froggy2818@gmail.com`，新增用户邮箱无法通过 Access 登录。

## Acceptance

- `docs/cloudflare-zero-trust.md` 中 `opencode-axiom.0xc1.space` 的 allowlist 包含 `wangpeiguangwpg@gmail.com`，并保留既有邮箱。
- `.legion/wiki` 中关于 opencode-axiom Access allowlist 的当前真源更新为包含该邮箱。
- 若存在 Access-capable Cloudflare API token，则通过 API 更新 `opencode-axiom.0xc1.space` 的 Access allow policy，并验证 Google-only、exact-email、无 broad/bypass policy。
- 若本地没有可用 Access-capable token，则不得声称 Cloudflare 控制面已更新；必须在验证报告和 walkthrough 中明确记录阻塞与手工执行项。
- 不提交任何明文 API token、tunnel credential、OIDC secret 或临时 secret 文件。

## Assumptions

- 目标 hostname 是 `opencode-axiom.0xc1.space`，不是 `opencode-charlie.0xc1.space`。
- 新增的是 exact email rule：`wangpeiguangwpg@gmail.com`。
- 现有安全边界保持为 Cloudflare Access Google IdP + exact-email allowlist。
- 仓库没有 Terraform 或其他声明式 Access policy 资源；文档与 wiki 是 repo 内当前真源。

## Constraints

- 使用 Legion 工作流完成并保留 raw evidence。
- 修改型仓库工作在稳定 contract 后进入 isolated git worktree。
- 不扩大 Access 策略到 domain、everyone、bypass 或非 Google IdP。
- 不修改 cloudflared tunnel runtime credential 或 opencode runtime 配置，除非验证证明必须。

## Risks

- Cloudflare Access 控制面不是仓库声明式管理；如果缺少 Access-capable token，本次只能完成 repo 真源更新，实际授权需控制台/API 后续执行。
- 修改 Access policy 时若替换 payload 不完整，可能误删既有邮箱或 IdP requirement；更新前后必须读回验证。
- 本地 ignored secret（如 `API_TOKEN.env`）若存在也不能提交或打印。

## Scope

- 更新 `docs/cloudflare-zero-trust.md` 的 `opencode-axiom.0xc1.space` allowlist。
- 更新 task-local Legion docs 与相关 `.legion/wiki` 当前真源。
- 安全检查本地是否存在可用 Cloudflare Access API token；可用时执行 API 更新与读回断言。
- 记录验证证据、变更 review 和 reviewer-facing walkthrough。

## Non-Goals

- 不改变 `opencode-charlie.0xc1.space` allowlist。
- 不新增 Cloudflare Terraform/IaC 管理面。
- 不修改 tunnel DNS、cloudflared ingress、opencode server、Gatus/status page 或其他 hostname。
- 不轮换 Cloudflare API token 或 tunnel credential。

## Design Summary

- 采用最小变更：仅把新邮箱追加到 `opencode-axiom` exact-email allowlist 的文档真源和 Cloudflare policy（若凭证可用）。
- Cloudflare Access 仍是 authentication boundary；cloudflared ingress 只是 transport，不承载授权逻辑。
- 更新 Cloudflare policy 时必须先读当前 app/policy，再保留既有邮箱追加新邮箱，最后读回验证 policy shape。

## Phases

- Brainstorm: 收敛本 contract，确认 scope、风险、验收和凭证边界。
- Engineer: 在 worktree 内更新 repo 真源，并在凭证可用时执行 Cloudflare API 变更。
- Verify: 运行文本/shape 验证、`git diff --check`，并读回 Cloudflare policy 或记录缺 token 阻塞。
- Review: 检查是否有安全策略扩大、secret 泄露或未验证声明。
- Report/Wiki: 写 walkthrough、PR body（如适用）和 wiki 当前真源。

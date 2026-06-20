# Axiom Opencode Access Email Allowlist - Log

## 2026-06-20

- 用户要求使用 Legion 给 `axiom` 的 opencode Cloudflare Access 增加可访问邮箱 `wangpeiguangwpg@gmail.com`。
- 入口判断：仓库存在 `.legion/`，请求是修改型工程工作且没有指定恢复 task id/path，因此进入 `brainstorm`。
- 仓库探索发现：`docs/cloudflare-zero-trust.md` 记录 `opencode-axiom.0xc1.space` 当前 allowlist 为 `c1@ntnl.io`、`siyuan.arc@gmail.com`、`froggy2818@gmail.com`；没有 Terraform/Cloudflare Access IaC 文件。
- 历史 Legion 记录显示此前 Access API 操作依赖本地 `API_TOKEN.env`，而 `hosts/charlie/secrets/cloudflare-api-token.age` 曾被记录为 Access 权限不足。
- 当前 glob 未发现 `/home/c1/dotfiles/API_TOKEN.env`；后续实现阶段需重新安全检查 token 可用性，不能输出或提交 token。
- 已通过 `ctx7` 读取官方 Cloudflare docs，确认 Access application/policy 可使用 exact email allow policy 模式。
- 新建 task contract，并在 worktree `.worktrees/axiom-opencode-access-email-wangpeiguang` 中落盘。
- Git envelope：base ref `origin/master` at `b386c5b2`，branch `legion/axiom-opencode-access-email-wangpeiguang-allow-email`，worktree `.worktrees/axiom-opencode-access-email-wangpeiguang`。
- Engineer: 已更新 `docs/cloudflare-zero-trust.md` 中 `opencode-axiom.0xc1.space` allowlist，追加 `wangpeiguangwpg@gmail.com` 并保留既有邮箱。
- Engineer: 已更新 `.legion/wiki` 的 opencode Access 当前真源，记录 axiom allowlist 包含 `wangpeiguangwpg@gmail.com`，charlie allowlist 不变。
- Credential check: `API_TOKEN.env`、`CLOUDFLARE_API_TOKEN`、`CF_API_TOKEN` 和 `CLOUDFLARE_ACCOUNT_ID` 均不存在。
- Credential check: `hosts/charlie/secrets/cloudflare-api-token.age` 使用 `agenix -d cloudflare-api-token.age -i ~/.ssh/id_ed25519` 可解密为 env key `API_TOKEN`；此前无 `-i` 或参数顺序错误的探测只返回失败/help，不代表 secret 不可用。
- Credential check: 仓库内 axiom 相关 `.age` 只有 `hosts/axiom/secrets/cloudflared-credentials.age` 和 `hosts/axiom/secrets/frp-token.age`；没有 axiom-local Cloudflare API token age secret。
- Credential check: `/etc/ssh/ssh_host_ed25519_key` 存在但当前用户不可读，非交互 sudo 不可用；无法解密 axiom cloudflared credential。即便该 credential 可解密，历史验证和文件用途也表明它是 tunnel runtime JSON，不是 Access API bearer token。
- Cloudflare read-before-write: `opencode-axiom.0xc1.space` app 唯一，app id `d4fbde13-f314-43e8-9cc8-6243935569c6`，Google IdP `399adc69-d770-4685-8acf-cdea3acca230`，现有 allow policy `5593f601-c883-4bb8-8e76-1ba02b6c7b4a` 原包含 `c1@ntnl.io`、`siyuan.arc@gmail.com`、`froggy2818@gmail.com`。
- Cloudflare update: 已将 policy `5593f601-c883-4bb8-8e76-1ba02b6c7b4a` 更新为 `allow-c1-siyuan-froggy-wang-google`，include exact emails `c1@ntnl.io`、`siyuan.arc@gmail.com`、`froggy2818@gmail.com`、`wangpeiguangwpg@gmail.com`，require Google login method `399adc69-d770-4685-8acf-cdea3acca230`。
- Cloudflare verification: readback 断言通过，`appCount=1`，`appShapeOk=true`，`exactAllowPolicyCount=1`，`unsafeAllowOrBypassCount=0`。
- Consistency fix: `status-axiom` 的文档/wiki 现在说明其 Access policy 是创建时匹配当时的 opencode pattern，未来 opencode allowlist 变更不会自动扩展到 status page；本任务未修改 `status-axiom` live policy。

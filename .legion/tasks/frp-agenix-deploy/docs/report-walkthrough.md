# Report Walkthrough

## Profile

implementation

## Reviewer Summary

- 本 PR 新增声明式 `modules.services.frp`，让 `aliyun-acorn` 运行 `frps`，`axiom` 运行 `frpc`。
- frp token 使用 host-local agenix secret 保存，运行时从 `/run/agenix/frp-token` 注入 TOML，避免明文进入 Git 或 Nix store。
- 验证与 review 均为 PASS；PR lifecycle 尚未完成，本文档只是 reviewer-facing artifact。

## Scope

In scope:

- 新增 `modules/services/frp.nix`。
- 更新 `hosts/aliyun-acorn/default.nix` 的 `frps` enable 和 TCP `7000` / `2225` 防火墙放行。
- 更新 `hosts/axiom/default.nix` 的 `frpc` client proxy，转发本机 SSH 到远端 `2225`。
- 新增两台 host 的 `frp-token.age` 和 `secrets.nix`。
- 新增 `.gitattributes` 的 `*.age binary` 规则，防止 encrypted age payload 被 Git 当作文本检查。

Out of scope:

- 不替换现有 autossh reverse SSH。
- 不新增 frp dashboard、metrics、TLS、多 proxy 或 Cloudflare/Gatus 集成。
- 不整理主工作区已有 unrelated dirty 改动。

## Evidence Map

| Claim | Evidence | Status |
|---|---|---|
| 任务契约稳定且 scope 明确 | `plan.md` | PASS |
| 设计门通过 | `docs/rfc.md`, `docs/review-rfc.md` | PASS |
| 两台 host eval 与 dry-run build 通过 | `docs/test-report.md` | PASS |
| frp TOML 模板通过 `frpc verify` / `frps verify` | `docs/test-report.md` | PASS |
| token 未进入 Nix store 模板或渲染脚本 | `docs/test-report.md` | PASS |
| age 密文按 binary 处理，`git diff --check` 不误报 | `docs/test-report.md` | PASS |
| 实现 review 和 security lens 通过 | `docs/review-change.md` | PASS |

## What Changed / What Was Decided

新增 module 使用 `pkgs.formats.toml` 生成带 `@FRP_TOKEN@` 占位符的 TOML 模板。systemd 在 `ExecStartPre` 中读取 agenix 解密后的 token，写入 `/run/frpc/frpc.toml` 或 `/run/frps/frps.toml`，再启动 frp。这样 store 内只包含模板、渲染脚本和占位符，不包含 token 明文。

review 后移除了无效的 `age-secrets-frp-token.service` systemd 依赖，因为当前 agenix 配置没有生成该 per-secret unit。修正后服务只排序在 `network-online.target` 之后，并完成二次验证。

## Verification / Review Status

- Secret consistency: PASS，两个 host-local age 文件解密为同一个 96 位 hex token，未打印明文。
- Nix eval: PASS，`axiom` 和 `aliyun-acorn` 均能生成 toplevel drv path。
- Dry-run build: PASS，两台 host 均完成 dry-run。
- Template verify: PASS，`frpc verify` 与 `frps verify` 均报告 syntax ok。
- Review-change: PASS，无 blocking finding，security lens 已应用。

## Risks and Limits

- `7000` 与 `2225` 是公网入口，风险边界依赖强 token 和 SSH key-only auth。
- 当前本地用户不能读取 `/etc/ssh/ssh_host_ed25519_key`，因此不能直接用 axiom 私钥验收解密，但 age recipient 已写入。
- 本地验证不能证明目标机部署后的网络可达性和 systemd runtime health。

## Reviewer Checklist

- [ ] 确认公网端口 `7000` / `2225` 符合预期。
- [ ] 确认 token runtime rendering 方案足以避免 Nix store 明文泄露。
- [ ] 确认保留 autossh reverse SSH 符合迁移策略。
- [ ] 确认验证证据覆盖 eval、dry-run、frp 模板和 secret 一致性。

## Next Stage

PR-backed lifecycle 仍需创建 PR、尝试 auto-merge、跟进 checks/review、达到 PR 终态，然后 cleanup worktree 并刷新主工作区。Render handoff 记录为 artifact-only/blocker：仓库当前没有现成 Pages PR preview 配置，新增 preview workflow 会扩大本任务 scope；reviewer 可直接查看 PR 中的 `docs/report-walkthrough.html` artifact，若需要稳定 rendered URL 应另开任务配置 `pr-html-render` workflow。

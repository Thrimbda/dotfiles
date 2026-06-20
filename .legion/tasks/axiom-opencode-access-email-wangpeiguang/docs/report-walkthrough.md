# Report Walkthrough

## Profile

implementation

## Reviewer Summary

- `opencode-axiom.0xc1.space` 的 Cloudflare Access allow policy 已追加 `wangpeiguangwpg@gmail.com`。
- API 读回确认 app 仍为 Google-only，exact-email allow policy 包含 4 个邮箱，unsafe allow/bypass policy 数量为 0。
- Repo 文档与 Legion wiki 已同步当前 allowlist。
- `status-axiom` 没有被修改；文档已明确它不会自动继承未来 opencode allowlist 变更。

## Scope

In scope:

- 更新 `docs/cloudflare-zero-trust.md` 的 `opencode-axiom.0xc1.space` allowlist。
- 更新 live Cloudflare Access policy `5593f601-c883-4bb8-8e76-1ba02b6c7b4a`。
- 更新 task evidence 与 `.legion/wiki` 当前真源。

Out of scope:

- 不修改 `opencode-charlie.0xc1.space`。
- 不修改 `status-axiom.0xc1.space` live policy。
- 不修改 cloudflared ingress、DNS、opencode runtime、tunnel credentials 或 API token storage。

## Evidence Map

| Claim | Evidence | Status |
|---|---|---|
| Axiom allowlist includes `wangpeiguangwpg@gmail.com` | `docs/test-report.md` repo assertions | PASS |
| Live Cloudflare policy contains the 4 exact emails | `docs/test-report.md` API update/readback | PASS |
| Google IdP boundary remains enforced | `docs/test-report.md`, `docs/review-change.md` | PASS |
| No broad/bypass/non-identity allow added | `docs/test-report.md`, `docs/review-change.md` | PASS |
| Charlie allowlist unchanged | `docs/test-report.md` charlie assertions | PASS |
| Status page not implicitly expanded | `docs/gatus-status.md`, `.legion/wiki/tasks/gatus-axiom-cloudflare-access.md` | PASS |

## What Changed

- Updated Cloudflare Access policy `5593f601-c883-4bb8-8e76-1ba02b6c7b4a` to `allow-c1-siyuan-froggy-wang-google`.
- The policy now includes exact emails `c1@ntnl.io`, `siyuan.arc@gmail.com`, `froggy2818@gmail.com`, and `wangpeiguangwpg@gmail.com`.
- The policy still requires Google login method `399adc69-d770-4685-8acf-cdea3acca230`.
- Updated docs/wiki to reflect the verified current opencode-axiom Access state.

## Verification / Review Status

- PASS: repo text assertions for axiom and charlie allowlists.
- PASS: Cloudflare API readback: `appCount=1`, `appShapeOk=true`, `exactAllowPolicyCount=1`, `unsafeAllowOrBypassCount=0`.
- PASS: `git diff --check`.
- PASS: security review with no blocking findings.

## Risks And Limits

- Browser smoke as `wangpeiguangwpg@gmail.com` was not run in this environment; API state is verified and manual browser smoke remains recommended.
- Existing Cloudflare API token rotation follow-up remains outside this task.

## Reviewer Checklist

- [ ] Confirm the diff only updates opencode-axiom Access truth and evidence.
- [ ] Confirm no `opencode-charlie` or `status-axiom` live policy expansion is claimed.
- [ ] Confirm API evidence is sufficient for the Access policy change.
- [ ] Optionally run browser smoke for `wangpeiguangwpg@gmail.com` and an unlisted Google account.

## Next Stage

- `docs/report-walkthrough.html` is the main reviewer artifact.
- Render handoff: pending PR preview handling after PR creation.
- Continue to `legion-wiki`, then PR lifecycle.

# 安全审查报告

## 结论
CONCERNS

本轮终审确认：

- `opencode-server` 绑定 `127.0.0.1:4096`，未看到直接监听公网/局域网接口的路径。
- `cloudflared` 仅回源 `http://127.0.0.1:4096`，并带有 `http_status:404` 兜底。
- 上一轮 `/tmp` 日志问题已修正为用户日志目录，风险明显下降。
- `Cloudflare Access` 已被写成上线前置门禁。

当前未发现足以阻止合入的新增阻塞项；但仍存在需要上线前明确签收或补强的安全关注，主要是 **Access 仍是唯一外层鉴权**，以及 **browser SSH 临时密码流程仍容易被误用**。

## 阻塞问题
- [ ] （本轮未发现新的 blocking 问题）

## 主要风险
- [ ] `[STRIDE:Elevation of Privilege / Spoofing]` `hosts/charlie/default.nix:140-155` `docs/cloudflare-zero-trust.md:185-194` `.legion/tasks/charlie-opencode-server-cloudflare-access/docs/rfc.md:112-123,196-204` - 当前对外暴露链路默认依赖 Cloudflare Access 作为唯一外层鉴权边界，仓库内没有第二层应用认证，也没有技术性“未配 Access 即禁止上线”的硬闸门。若 Access policy 漏配、误放宽、会话被盗用，或后续维护者误复用 hostname/ingress，则会直接扩大 `opencode` 暴露面。修复建议：若 `opencode` 支持，优先启用独立应用层口令/令牌；至少把“授权可访问 + 未授权被拒绝 + 审计日志可查”固化为上线硬门禁。

- [ ] `[STRIDE:Information Disclosure / Elevation of Privilege]` `docs/charlie-macos-ssh-config.md:14-35,211-245` `docs/cloudflare-zero-trust.md:210-289` - 浏览器 SSH 文档仍保留“创建临时密码”“必要时临时启用 PasswordAuthentication”路径。虽然默认值已回到更安全配置，但该流程仍可能被执行者误当成常规步骤，导致 SSH 基线被短时弱化，并引入额外凭证面。修复建议：把该流程明确标记为 break-glass，仅允许短时启用；补充责任人、时限、回退步骤与审计要求，并强调测试完成后立即恢复 `PasswordAuthentication no`。

- [ ] `[STRIDE:Repudiation / Information Disclosure]` `hosts/charlie/default.nix:122-123` `modules/services/cloudflared.nix:231-232` - 日志路径已迁移到用户日志目录，方向正确；但当前文档尚未明确日志权限、轮转、留存与敏感字段脱敏策略。若服务错误输出包含 header、token、cookie、prompt 或内部路径，仍可能形成本机信息泄露与审计噪音。修复建议：上线前补充日志权限/留存约定，并确认错误日志不会记录敏感认证材料。

## 建议（非阻塞）
- 保持 `opencode-server` 仅监听 `127.0.0.1:4096`，上线前再次验证未监听 `0.0.0.0`、局域网 IP 或其他意外接口。
- 保持 `warpRouting.enabled = false`，避免引入与本次 HTTP 暴露无关的额外网络入口。
- 为 Access 策略增加最小权限约束：仅目标邮箱、强制 MFA、短会话时长、避免宽泛组/域名规则。
- 为 Access 增加监控项：未授权访问拒绝事件、策略变更审计、异常来源地/设备登录告警。
- 对 `opencode`/`cloudflared` 日志做一次敏感信息抽查，确认不会把认证材料直接打入日志。
- 若继续保留 browser SSH，应与本次 opencode 发布路径分开维护，避免应急流程覆盖默认运行手册。
- 本次未执行依赖版本/CVE 扫描；建议上线前补做 `cloudflared`、`opencode` 及其关键依赖版本核验。

## 缓解建议
1. **把 Access 变成硬门禁**：上线前必须同时验证“授权放行 / 未授权拒绝 / 审计可追溯”。
2. **评估第二层认证**：若 `opencode` 支持密码、token 或类似机制，建议在正式暴露前启用。
3. **收紧 break-glass SSH 流程**：将临时密码流程降级为紧急例外，而非常规操作说明。
4. **补齐日志治理**：明确日志目录权限、轮转、留存周期与敏感内容处理策略。

## 上线前检查
- [ ] `opencode-server` 仍仅绑定 `127.0.0.1:4096`。
- [ ] `cloudflared` ingress 仍只回源 `http://127.0.0.1:4096`，且存在 `http_status:404` 兜底。
- [ ] `warpRouting.enabled = false`，未额外引入私网路由暴露。
- [ ] Cloudflare Access self-hosted application 已创建并绑定正确 hostname。
- [ ] Access policy 仅允许目标邮箱，已启用 MFA，且未使用宽泛规则。
- [ ] 已验证：授权账号可访问；未授权账号被拒绝；对应审计日志可回溯。
- [ ] 已确认日志目录权限、留存与敏感信息处理策略。
- [ ] 已确认是否启用第二层应用认证；若未启用，已显式签收该风险。
- [ ] browser SSH / 临时密码认证当前未开启；若做过测试，已恢复安全默认并保留审计记录。

## 修复指导
- 不必因上一轮 `/tmp` 问题继续阻塞；该项已修正。
- 继续把“Access 未完成不算上线”从文档约定提升为发布流程硬门禁。
- 若 `opencode` 支持独立认证，建议在正式发布前补上第二层防线。
- 将 browser SSH 临时密码流程显式标注为 break-glass，并补充回退与审计要求。

[Handoff]
summary:
  - 本轮确认 localhost 绑定、用户日志目录修正、Access 门禁文档化均已到位。
  - 未发现新的 blocking，整体结论为 CONCERNS 而非 FAIL。
  - 剩余重点风险是 Access 单层鉴权与 browser SSH 临时密码流程误用。
decisions:
  - (none)
risks:
  - Access 漏配或策略放宽时，当前缺少应用层第二道认证。
  - browser SSH 的临时密码流程仍可能被误当作常规操作。
  - 日志目录虽已修正，但仍需补齐权限、留存与敏感信息治理。
files_touched:
  - path: /Users/c1/dotfiles/.legion/tasks/charlie-opencode-server-cloudflare-access/docs/review-security.md
commands:
  - (none)
next:
  - 将 Access 验证与未授权拒绝测试纳入上线硬门禁。
  - 确认是否为 opencode 增加第二层认证，或显式签收该风险。
  - 将 browser SSH 临时密码流程收紧为 break-glass 文档。
open_questions:
  - (none)

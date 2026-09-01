# RFC Review: Const X Azar Public Deployment

审查方式：独立、只读的 Codex CLI 会话；未修改文件、未读取 password/secret、未调用远端或外部服务。

## Verdict

PASS

## Re-review Conclusion

前次的两个阻塞项均已修复。设计现在具有唯一的 root 执行路径、唯一的 release / rollback 权威，以及覆盖认证、SSE、附件和 DNS/TLS 的正负验证方案，可以进入实现阶段。

### Root execution path

用户的决定已一致地记录为：

- Axiom SSH alias `axiom-tunnel` 是 build host；
- Azar SSH alias `azar` 是 target / activation host；
- 使用 `nixos-rebuild --ask-sudo-password --sudo --build-host axiom-tunnel --target-host azar switch`；
- password 仅来自本机 owner-only、非版本化文件，不进入 worktree、Nix store、argv、日志或 Git。

这使 switch、systemd/Nginx activation 与 ACME activation 具有明确授权与执行入口。

### Release and rollback

release / rollback 已统一为：

- service 固定引用 source SHA `45c21f0a2f437cb11cb5e316c29d5ff08cbef471` 对应的 release directory；
- staging 后另行核验 binary SHA-256；
- 不创建或使用 `current` symlink；
- NixOS generation 是 activation、升级和 rollback 的唯一权威；
- 首次部署失败时停止/移除新 service 或回滚到部署前 generation，不能假设存在前一 Const X release；
- release directory 仅为保留 artifact，不承担 activation。

### Key boundary review

- `auth_request /_auth`、internal login redirect、403 handling 使匿名流量不直达 protected upstream；login/callback/logout/`/healthz` 是明确 gateway endpoint。实现后仍须检查生成的 Nginx location 合并结果。
- 每 hostname 独立 gateway state 和 `publicHost` 与现有模式一致。真实 callback/cookie origin 与既有用户 browser login 仍需运行时 canary。
- `client_max_body_size 22m`、HTTP/1.1、关闭 request/response buffering、cache/gzip/retry，以及长 timeout 足以表达 SSE 与 20 MiB 单文件上传的代理边界。静态 config 与已认证 runtime smoke 都是 C3 的必需证据。
- DNS-01 在公开 A record 前签证书的顺序合理；DNS record 仅在 absent 时创建，冲突停止，rollback 仅删除本任务记录的 ID。

## Non-blocking Notes

- 将 research 中旧的“root 尚未授权”标记为已由 `D-ROOT-001` 取代，避免后续执行误读。
- 必须在生成配置中证明 `auth_request` 和 Const X 专属 proxy directives 同时存在，且既有 gateway instances 的有效默认行为没有变化。
- binary SHA-256、Nix generation、Cloudflare DNS record ID 和 verification result 需在后续证据中建立明确映射；hash 只证明 artifact integrity，generation 才是 activation authority。

## 会话注意力摘要

- 阶段：review-rfc
- 阶段结论：PASS
- 注意力等级：skim
- 判断变化：root execution authority 与 release/rollback 双重权威均已解决，RFC 可进入 engineer。
- 关键发现：
  1. Axiom build host、Azar target host 和 `--ask-sudo-password --sudo` 已形成唯一执行路径。
  2. 固定 source SHA、binary integrity hash 与 NixOS generation rollback 已明确分工。
  3. 匿名认证、SSE/22 MiB、DNS/ACME sequencing 均有可实施的正负验证路径。
- 阻塞项：无。
- 残余风险：生成 Nginx location 的实际合并结果、真实已认证 SSE/20 MiB 上传、ACME activation 与既有用户 browser login 仍须在部署后验证。
- 人类动作：知悉设计门已解除；C4 时由既有授权用户完成实际 browser login 与 Settings 检查。
- 自动下一步：进入 `engineer`；完成实现后执行 `verify-change -> review-change`，在阻塞性 runtime evidence 齐备前不得声明交付完成。
- 完整证据：
  - `.legion/tasks/constx-azar-public-deployment/plan.md`
  - `.legion/tasks/constx-azar-public-deployment/docs/research.md`
  - `.legion/tasks/constx-azar-public-deployment/docs/rfc.md`
  - `.legion/tasks/constx-azar-public-deployment/docs/implementation-plan.md`
  - `hosts/acorn/modules/auth-mini.nix`

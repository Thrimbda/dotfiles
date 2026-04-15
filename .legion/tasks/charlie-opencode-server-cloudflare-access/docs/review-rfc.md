# RFC 审查：charlie 上 opencode server Cloudflare Access 暴露与自启动

## 结论

- 初审：FAIL
- 收敛后结论：PASS WITH CONCERNS

## 关键意见与收敛结果

1. **Blocking：opencode 启动路径不能依赖 launchd PATH**
   - 收敛：RFC 已改为使用绝对路径 `/Users/c1/.opencode/bin/opencode`，并显式设置 `HOME` 与必要环境变量。

2. **Blocking：cloudflared ingress 与 Access 的职责需要闭环**
   - 收敛：RFC 已明确“ingress 负责转发，Access 负责鉴权”，并把 Access 应用创建与邮箱 allow policy 定义为上线门禁，而非可选后置步骤。

3. **Blocking：回滚需要最小可执行路径与验证信号**
   - 收敛：RFC 已改为三步回滚：先撤公网入口，再 `darwin-rebuild switch` 下线本地服务，最后验证 hostname 与 launchd agent 均失效。

4. **Non-blocking：日志目录仍偏临时**
   - 处理：首版接受 `/tmp` 作为快速排障日志位置，但在 RFC 中记录为后续可加固项。

5. **Non-blocking：是否必须维持 High 分级**
   - 处理：当前仍按 High 执行，因为本次变更涉及远程暴露与访问控制边界变化；同时通过安全评审与回滚说明降低实施风险。

## 审查后建议

- 可以继续实现。
- 实现时优先确保 hostname / tunnel / Access 文案一致，避免 PR 与文档出现不同默认值。
- 安全评审应重点检查：localhost 绑定是否被破坏、warpRouting 是否被错误打开、Access 前置条件是否在 PR body 中被强调。

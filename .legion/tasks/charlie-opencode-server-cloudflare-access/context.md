# charlie 上 opencode server Cloudflare Access 暴露与自启动 - 上下文

## 会话进展 (2026-04-12)

### ✅ 已完成

- 读取现有 .legion 状态并为本次工作创建独立任务
- 完成风险分级与任务契约 plan.md
- 产出 RFC 并根据 review-rfc 反馈收敛到可执行方案
- 在 darwin/default.nix 导入 cloudflared 模块
- 在 hosts/charlie/default.nix 增加 opencode-server launchd 自启动配置并启用 cloudflared ingress
- 同步修正文档与脚本中的 config/extraConfig 漂移
- 产出 test-report、review-code、review-security
- 生成 report-walkthrough 与可直接用于 PR 的 pr-body
- 本次任务 6/6 checklist 已完成
- 定位到 charlie 构建失败的首个直接根因：Darwin 导入链缺少 modules/dev/playwright.nix，导致 hosts/charlie/default.nix 中的 modules.dev.playwright.enable 无法求值
- 在 darwin/default.nix 导入 modules/dev/playwright.nix 后，charlie 的 nix eval 与 system build 已通过
- 更新 test-report、walkthrough 与 pr-body，使其反映 charlie 的 nix eval / nix build 已通过
- 已通过 Cloudflare API 为 opencode-charlie.0xc1.space 创建/确认 Access self-hosted application
- 已通过 Cloudflare API 为 Access app 创建允许邮箱 c1@ntnl.io 的 allow policy
- 定位到 launchd 下 opencode HTTP 卡住的根因：launchd 未设置 WorkingDirectory，opencode 以 '/' 作为默认目录启动并建立错误的默认实例/ watcher
- 在 hosts/charlie/default.nix 的 opencode-server agent 中新增 WorkingDirectory = /Users/c1
- 通过前台隔离验证确认：在 /Users/c1 工作目录下启动 opencode serve 可恢复正常 HTTP 200 响应


### 🟡 进行中

- 等待 root 执行 darwin-rebuild switch 以将修复真正激活到 launchd 运行态


### ⚠️ 阻塞/待定

- darwin-rebuild switch 需要 root；当前会话只能完成构建与前台隔离验证，不能直接激活系统配置


---

## 关键文件

(暂无)

---

## 关键决策

| 决策 | 原因 | 替代方案 | 日期 |
|------|------|----------|------|
| 首版采用本地 localhost 监听 + Cloudflare ingress + Access 邮箱策略的最小闭环，并使用绝对路径 /Users/c1/.opencode/bin/opencode 作为 launchd 执行入口。 | 避免 launchd PATH 漂移，同时将公网暴露限定在 Cloudflare Access 鉴权之后。 | 依赖 PATH 直接调用 opencode；让服务监听 0.0.0.0；同步自动化 Access/Terraform（超出本次 scope）。 | 2026-04-12 |
| 将 opencode-server 与 cloudflared 的 Darwin 日志从 /tmp 改为用户日志目录 /Users/c1/Library/Logs 与 ~/Library/Logs。 | 降低 /tmp 临时目录带来的信息泄露与审计留存风险，并回应安全评审关切。 | 继续使用 /tmp；额外引入更复杂的日志目录初始化逻辑。 | 2026-04-12 |
| 接受安全评审的 CONCERNS 作为已知风险继续交付，不在本次 scope 内引入第二层应用认证。 | 当前任务目标是最小可用且可回滚的 localhost + Cloudflare Access 闭环；增加应用层认证需要新的 secret 管理与发布流程设计。 | 在本次变更中额外引入 OPENCODE_SERVER_PASSWORD 或其他二次认证方案。 | 2026-04-12 |
| 接受用户追加的“调试到 nix build 通过”为同一任务的后续阶段，并扩展 scope 纳入与 charlie 构建直接相关的 pre-existing 阻塞修复。 | 构建阻塞已成为本次端到端交付的关键闭环；若不修复，charlie 上的声明式服务无法真正部署验证。 | 保持原任务只交付静态文档与配置，把构建问题拆成新任务。 | 2026-04-12 |
| 采用最小修复：仅在 darwin/default.nix 补导入 ../modules/dev/playwright.nix，而不重构 modules/dev/default.nix。 | 错误根因是 Darwin import 链缺失；补导入即可让 charlie eval/build 通过，且变更面最小。 | 删除 hosts/charlie/default.nix 中的 modules.dev.playwright.enable；重构 dev 模块聚合方式。 | 2026-04-12 |
| 在交付文档中保留“nix build 已通过，但 darwin-rebuild 运行态验证仍需在真实主机完成”的表述。 | 仓库内静态/构建闭环已完成，但切换系统配置与 Cloudflare Access 验证需要真实环境执行。 | 把未执行的运行态验证也表述为已完成（不准确）。 | 2026-04-12 |
| 执行 Cloudflare API 自动化时，因用户提供的 cloudflare 文件中 TUNNEL_ID 长度异常，回退使用仓库中 hosts/charlie/default.nix 的完整 tunnelId。 | 提供的 TUNNEL_ID 只有 35 位，明显少于标准 UUID 长度 36 位；仓库声明式配置中存在完整值，可作为更可靠来源。 | 中断等待用户修正 cloudflare 文件；直接使用异常值并导致 DNS/Access 配置失败。 | 2026-04-12 |
| 采用最小修复：仅为 opencode-server 的 launchd 配置增加 WorkingDirectory，而不修改 opencode 配置文件或禁用插件。 | 内部日志显示 launchd 环境下默认实例目录为 '/'；同样参数在 /Users/c1 工作目录前台启动即可恢复正常，说明根因是工作目录而不是插件本身。 | 移除/禁用插件；修改 PATH；增加更多环境变量。 | 2026-04-15 |

---

## 快速交接

**下次继续从这里开始：**

1. 以 root 执行 darwin-rebuild switch --flake .#charlie。
2. 切换后重启/检查 org.nixos.opencode-server，并验证 curl http://127.0.0.1:4096 返回 200。
3. 完成后再观察 cloudflared 与 Access 访问链路。

**注意事项：**

- 前台隔离测试命令已证明修复方向正确。
- 当前 launchd 里运行的仍是旧配置，因此 4096 现状未自动变好。

---

*最后更新: 2026-04-15 17:25 by Claude*

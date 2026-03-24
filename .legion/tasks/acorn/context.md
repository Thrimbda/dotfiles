# acorn 新配置适配与构建修复 - 上下文

## 会话进展 (2026-03-24)

### ✅ 已完成

- 定位 acorn 构建阻塞为 server profile 对已移除的 linux_6_9_hardened 引用
- 完成 Medium 风险短 RFC，并经 review-rfc 收敛到 PASS WITH NOTES
- 完成共享 server profile 的 hardened kernel 入口替换
- 为 acorn 补齐 host 级 build 前置，并将失效主题设置收敛为 null
- 将 agenix 主机 key 断言改为仅在可获取 currentSystem 且为目标平台本机构建时强校验
- 完成 eval/build 验证，确认旧 kernel attr 错误消失且当前仅受 darwin 缺少 x86_64-linux builder 阻断
- 完成 test-report、review-code、review-security 文档产出
- 确认项目根目录的 `ssh_host_ed25519_key` 已恢复为可解密 `vaultwarden-env.age` 的旧私钥
- 将 `hosts/acorn/secrets/vaultwarden-env.age` 重新按当前 host key rekey
- 为 `age.secrets.vaultwarden-env` 明确设置 `owner/group/mode` 以收紧 vaultwarden 环境文件权限
- 确认 acorn 实际应使用 `/home/c1/.ssh/id_ed25519` 作为 agenix 解密身份，而不是 `/etc/ssh/ssh_host_ed25519_key`
- 通过 SSH 登录 acorn，定位 cloud-init 失败根因为其 service PATH 中缺少 `resize2fs`，导致 `cc_resizefs` 在 switch 后报错


### 🟡 进行中

- 已确认项目根目录 `ssh_host_ed25519_key` 的公钥与 acorn 当前 secrets recipient 不匹配，正在切换 recipient 并等待 secret 重新加密


### ⚠️ 阻塞/待定

(暂无)


---

## 关键文件

(暂无)

---

## 关键决策

| 决策 | 原因 | 替代方案 | 日期 |
|------|------|----------|------|
| 先以构建失败信号驱动 design-lite，而不是预先扩展到完整 RFC | 当前任务目标是让 acorn 尽快适配新配置并达到可构建，优先以最小设计收敛问题边界；仅在发现公共接口/高风险改动时升级为 RFC。 | 直接先写完整 RFC；但在问题尚未定位前会增加成本。 | 2026-03-24 |
| 任务按 Medium 风险处理，先补短 RFC 再实现 | 修复点触及共享 server profile 与系统内核安全基线，虽当前实际主要影响 acorn，但仍需在实现前明确验证口径和回滚策略。 | 按 Low 风险直接改代码；但不利于记录 darwin/Linux/目标机三段式验证与运行时回滚策略。 | 2026-03-24 |
| 不在 acorn 上永久关闭 agenix host key 校验，而是将例外收敛到纯求值/无 currentSystem 场景 | 这样既能让 darwin 侧的 flake 评估继续推进，又不削弱目标机上 age secrets/vaultwarden 的 secure-by-default 边界。 | 在 acorn 上设置 checkSshKey = false；但会把 host key 配置错误推迟到运行时。 | 2026-03-24 |
| 优先按 secrets 解密链路排查 vaultwarden 启动失败，而不是先改 vaultwarden 服务参数 | systemd 报错是 environmentFile 不存在，首先应确认 agenix 是否成功产出 secret 文件；若 secret 未解密，调整 vaultwarden service 本身不能根治问题。 | 先修改 vaultwarden 服务依赖/重启策略；但无法解决缺失的 secret 文件。 | 2026-03-24 |
| 先把 acorn secrets recipient 对齐到项目根目录提供的 host key 公钥 | 这样可以让仓库声明和目标机解密身份保持一致，避免后续继续把 secret 加密到错误 recipient。 | 保持旧 recipient；但当前已确认本地和目标机都无匹配私钥，无法恢复解密链路。 | 2026-03-24 |
| 在恢复 vaultwarden secret 解密链路的同时为环境文件显式收紧权限 | 当前故障点虽是 environmentFile 缺失，但补上 owner/group/mode 可以让 `/run/agenix/vaultwarden-env` 的归属更符合 vaultwarden 运行边界。 | 仅 rekey secret 文件；但会继续依赖 agenix 默认 owner。 | 2026-03-24 |
| 将 acorn 的 `modules.agenix.sshKey` 改回用户密钥 `/home/c1/.ssh/id_ed25519` | 用户确认目标机的真实解密身份是用户私钥，agenix 激活报错也说明当前 host key 路径与 secrets recipient 不匹配。 | 继续使用 `/etc/ssh/ssh_host_ed25519_key`；但已被目标机日志证伪。 | 2026-03-24 |
| 为 acorn 的 `cloud-init` / `cloud-config` / `cloud-final` systemd 单元显式注入 `pkgs.e2fsprogs` 到 PATH | 目标机日志显示 `resize2fs` 已存在于系统 profile，但 cloud-init unit 自带 PATH 未包含它；通过 host 级 unit path 覆盖可以最小修复 Azure cloud-init resizefs 失败。 | 禁用 cloud-init resizefs 模块；但会改变 Azure 首次扩容行为。 | 2026-03-24 |

---

## 快速交接

**下次继续从这里开始：**

1. 在具备 x86_64-linux builder 的环境或 acorn 目标机上重新执行 `nix build .#nixosConfigurations.acorn.config.system.build.toplevel`
2. 若准备部署，先记录当前 generation，再验证 Azure 启动、vaultwarden/nginx/fail2ban 状态与 age secrets 解密链路
3. 将 `.legion/tasks/acorn/docs/pr-body.md` 作为 PR 描述发起 review

**注意事项：**

- 当前 `nix eval` 已通过，旧的 `linux_6_9_hardened` blocker 已消失。
- 当前 `nix build` 停在 builder 平台不匹配，而不是配置求值错误。
- vaultwarden 功能配置未修改；后续需补运行时证据而非仅依赖静态审查。

---

*最后更新: 2026-03-24 22:22 by Claude*

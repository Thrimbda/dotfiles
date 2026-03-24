# 安全审查报告

## 结论
PASS WITH NOTES

## 审查范围
- `modules/profiles/role/server.nix`
- `hosts/acorn/default.nix`
- `modules/agenix.nix`
- `hosts/acorn/modules/vaultwarden.nix`
- `modules/services/vaultwarden.nix`
- `modules/services/nginx.nix`
- `modules/services/fail2ban.nix`
- `hosts/acorn/secrets/secrets.nix`

## 阻塞问题
- 无。

## 之前 blocking 的复核结论
- 已解除：`hosts/acorn/default.nix` 已移除无条件 `modules.agenix.checkSshKey = false`，`acorn` 不再把“为了 darwin 求值方便而关闭 host key 校验”的例外带入最终主机配置。
- 已解除：`modules/agenix.nix:22-30` 现在仅在 `builtins ? currentSystem` 缺失的纯求值场景放宽断言；当能够判断为目标平台本机构建时，仍要求 `pathExists cfg.sshKey`。这恢复了生产/真实构建路径上的 secure-by-default 行为，之前关于 age secrets 完整性边界被无条件削弱的 blocking 已不成立。

## 可接受风险
- `[STRIDE: Tampering/DoS]` `modules/profiles/role/server.nix:36` - 从固定 `linux_6_9_hardened` 切到 `pkgs.linuxPackages_hardened` 没有看到安全基线回退，且避免了失效 attr 导致的构建失败或被迫退回普通 kernel 的风险。剩余风险在于它跟随 nixpkgs 受支持集合演进，内核/驱动/Azure 兼容性问题更可能在运行时暴露，而不是在静态审查阶段暴露。
- `[STRIDE: Spoofing/Tampering]` `modules/agenix.nix:24-28` - 纯求值场景下允许跳过 `sshKey` 存在性断言是有边界的、目的明确的折中；从当前代码看，该放宽不再直接弱化目标主机构建路径。但 PR 仍应披露：纯求值通过不代表目标机 secrets 解密链路已被验证，不能把它表述成“secrets 已验证正常”。
- `[STRIDE: Information Disclosure/Repudiation]` `hosts/acorn/modules/vaultwarden.nix`、`modules/services/vaultwarden.nix`、`modules/services/nginx.nix`、`modules/services/fail2ban.nix` - 这些配置本次未改，静态上未见认证、TLS、反代、封禁或 secret 注入边界被弱化；不过目前仍缺少切换后运行证据，日志与服务状态检查需要在 PR 中单独披露，避免把“代码未改”误解为“运行时已证实无回归”。

## 建议（非阻塞）
- 在 PR 中明确区分“纯求值放宽断言”与“目标机构建/切换校验仍然严格执行”，避免 reviewer 误以为 host key 校验被整体拿掉。
- 把 `sshKey = "/etc/ssh/ssh_host_ed25519_key"` 与 `hosts/acorn/secrets/secrets.nix` 的 recipient 关系列入部署前 checklist，确保 key 轮换时不会出现 age recipient 漂移。
- 为 kernel 切换补充可观测性结果：尤其是 Azure 串口/控制台、bootloader 回滚入口、以及切换后 15 分钟内的关键服务日志。
- 在 PR 中声明 vaultwarden/nginx/fail2ban 本次“未改代码、仅需验证未回归”，这样 reviewer 可以把注意力放在运行时证据而不是不存在的配置变更上。

## 需要在 PR 中明确披露的剩余运行时验证项
- 目标机首次切换到 `pkgs.linuxPackages_hardened` 后，确认 Azure 虚机能正常启动，并验证上一代 generation / bootloader rollback 可用。
- 确认目标机 `/etc/ssh/ssh_host_ed25519_key` 存在且权限正确；`age.secrets.vaultwarden-env` 能成功解密与下发，`vaultwarden` 可正常读取 `environmentFile`。
- 确认 `systemctl status vaultwarden nginx fail2ban` 正常，且 `journalctl -u vaultwarden -u nginx -u fail2ban --since "-15m"` 中没有新增的 secret 路径、token、解密失败或 websocket 反代错误。
- 验证 `vault.0xc1.space` 的 HTTPS / `forceSSL` / websocket (`/notifications/hub` 与 `/notifications/hub/negotiate`) / 8000 与 3012 后端转发均正常。
- 验证 fail2ban jail 已加载 `vaultwarden` 与 `vaultwarden-admin`，并至少完成一次规则命中或最小封禁链路抽样，确认日志格式与过滤器仍匹配。

## 修复指导
1. 当前无需新增阻塞修复；重点转为补齐运行时验证证据。
2. 若后续再调整 `modules/agenix.nix`，应继续保持“纯求值放宽、真实目标构建严格校验”的边界，不要回到主机侧无条件关闭断言的模式。
3. 合并前把剩余运行时验证项写进 PR，确保该变更的安全结论建立在“静态审查 + 实机验证”两部分证据上。

[Handoff]
summary:
  - 已基于最新代码重新完成 acorn 安全审查并覆盖报告。
  - 之前关于 `checkSshKey = false` 的 blocking 已解除。
  - 当前结论为 PASS WITH NOTES，剩余风险集中在 kernel 切换与 secrets 链路的运行时验证。
decisions:
  - 将结论从 FAIL 调整为 PASS WITH NOTES，因为生产路径上的 host key 存在性校验已恢复。
risks:
  - `linuxPackages_hardened` 的运行时兼容性仍需在 Azure 目标机验证。
  - 纯求值放宽断言不应被误解为 secrets 运行时链路已验证通过。
files_touched:
  - path: /Users/c1/dotfiles/.legion/tasks/acorn/docs/review-security.md
commands:
  - (none)
next:
  - 在 PR 中补齐剩余运行时验证项与结果。
  - 切换后核实 vaultwarden/nginx/fail2ban/age secrets 未回归。
open_questions:
  - (none)

# 代码审查报告

## 结论
PASS WITH NOTES

## 阻塞问题
- [ ] (none)

## 建议（非阻塞）
- `modules/agenix.nix:24-28` - 目前断言语义已比上一版安全得多，且解决了 darwin 纯求值场景的问题；但它仍会在“本地 Linux builder 与目标平台同架构、但并非目标机本身”的场景下要求 `cfg.sshKey` 本地存在。若后续仓库确实依赖独立 Linux builder，这里的语义可能偏紧，建议后续补一条注释明确这是有意为之，避免使用者误判为构建回归。
- `modules/agenix.nix:18` - 默认值 `/etc/ssh/host_ed25519` 仍不像常见的 OpenSSH host key 路径。acorn 已显式覆盖，因此本次不构成问题，但从可维护性看，后续最好统一成更符合约定的默认值，或补充注释说明该默认值的适用背景。
- `modules/profiles/role/server.nix:36` - 这次改为 `pkgs.linuxPackages_hardened` 与 RFC 一致，改动也足够小。建议补一行注释说明“为什么使用受支持集合入口而不是固定版本 attr”，防止未来维护再次回到易过期的版本绑定。

## 修复指导
1. 当前上一轮 blocking 已解除，可继续进入验证阶段。
2. 建议在后续提交里补充两类文档性修正：
   - 为 `modules/agenix.nix` 的断言增加注释，明确“纯求值/跨平台评估可跳过，本机同平台仍强制校验”的设计意图；
   - 为 `server.nix` 的 hardened kernel 入口增加注释，固定 RFC 里的决策背景。
3. 后续验证时重点关注两件事：
   - Linux 真实构建是否在你预期的执行环境中进行；如果不是目标机本身，确认该环境是否具备 `cfg.sshKey`；
   - acorn 上 `vaultwarden-env` 的 secrets 路径、nginx/fail2ban 依赖边界是否保持不变。

[Handoff]
summary:
  - 本轮未发现 blocking，结论更新为 PASS WITH NOTES。
  - 上一轮两个阻塞项已解除：`${system}` 未定义问题已改为 `${pkgs.system}`，acorn 侧也不再通过 `checkSshKey = false` 关闭断言。
  - 共享 kernel 修复与 RFC 保持一致，vaultwarden 配置边界未被扩散修改。
decisions:
  - (none)
risks:
  - `modules/agenix.nix` 的断言对“同平台但非目标机”的 Linux builder 仍较严格，后续若引入独立 builder 需再次确认语义是否合适。
files_touched:
  - path: /Users/c1/dotfiles/.legion/tasks/acorn/docs/review-code.md
commands:
  - (none)
next:
  - 进入 Linux 构建与目标机运行时验证。
  - 补充必要注释，固化 agenix 断言与 hardened kernel 入口的设计意图。
open_questions:
  - (none)

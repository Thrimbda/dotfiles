# 代码审查报告

## 结论

PASS

上一轮提出的两项 concern 已确认修复：

- `docs/cloudflare-zero-trust.md:160-194` 已把 Darwin / charlie 的部署与验证主流程单独列出，并明确 Access 是上线前置条件。
- `docs/charlie-macos-ssh-config.md:128-160` 的 `opencode-server` launchd 示例已补齐 `HOME`、`OPENCODE_*` 与日志路径，和 `hosts/charlie/default.nix:105-124` 的实际配置一致。

基于当前最终改动，未发现会阻塞本次 `charlie + opencode server + Cloudflare Access` 合入的缺陷；主链路配置、文档和示例已经基本对齐。

## 阻塞问题

- [ ] （未发现 blocking 问题）

## 建议（非阻塞）

- `modules/services/cloudflared.nix:111,152,209` - `tunnelName` 目前仍有两个语义入口：顶层 `modules.services.cloudflared.tunnelName` 与 `extraConfig.tunnelName`。当前 `charlie` 关闭了 `warpRouting`，因此不影响本次上线，但后续若重新启用路由配置，仍可能出现“配置写在一处、运行读另一处”的维护性问题。

- `bin/cloudflared-setup:88-90` - 脚本实际检查的是 `age` 命令，但报错文案提示“未找到 agenix”并建议安装 `nixpkgs.agenix`。这不会影响本次已存在凭证文件的主路径，但会给首次执行 setup 的维护者带来排障歧义。

## 修复指导 / 接受理由

1. `modules/services/cloudflared.nix`
   - 建议收敛为单一入口：
     - 要么统一只使用顶层 `tunnelName`；
     - 要么删除顶层选项，全部通过 `extraConfig.tunnelName` 传递，并让路由命令也读取同一处。
   - 如果暂不调整，可接受理由是：本次 `hosts/charlie/default.nix:140-155` 明确设置了 `warpRouting.enabled = false`，当前发布路径不会触发该分歧。

2. `bin/cloudflared-setup`
   - 建议把先决条件文案改成与实际一致：
     - 若依赖的是 `age`，就提示安装 `age`；
     - 若希望依赖 `agenix`，则脚本中的检测和后续命令也应切换为 `agenix`。
   - 当前可接受理由是：本任务交付并不依赖重新生成凭证，`hosts/charlie/secrets/cloudflared-credentials.age` 已存在，脚本问题不会阻塞本次 charlie 最终配置落地。

3. 本次改动可接受的核心依据
   - `darwin/default.nix:37-64` 已导入 `../modules/services/cloudflared.nix`，Darwin 主链路接通。
   - `hosts/charlie/default.nix:105-155` 中 `opencode-server` 仅监听 `127.0.0.1:4096`，`cloudflared` 仅回源 localhost，且保留 `http_status:404` 兜底。
   - `docs/cloudflare-zero-trust.md:185-194` 与 `docs/charlie-macos-ssh-config.md:152-160` 已把 Cloudflare Access 明确为上线前置门禁，避免“隧道已通即视为上线”的误判。

[Handoff]
summary:
  - 终审结论为 PASS；上一轮两个 concern 已确认修复。
  - 当前未发现阻塞本次合入的代码或文档问题。
  - 剩余仅有两个非阻塞改进点：`tunnelName` 双入口语义、`age/agenix` 文案不一致。
decisions:
  - 接受当前实现合入，不将上述两项非阻塞建议升级为 blocking。
risks:
  - 后续若启用 warp routing，`tunnelName` 双入口可能再次引入配置漂移。
  - 首次使用 `bin/cloudflared-setup` 的维护者可能被 `age/agenix` 提示误导。
files_touched:
  - path: /Users/c1/dotfiles/.legion/tasks/charlie-opencode-server-cloudflare-access/docs/review-code.md
commands:
  - (none)
next:
  - 如有后续整理窗口，可统一 `tunnelName` 配置入口。
  - 顺手修正 `cloudflared-setup` 的依赖检测/提示文案一致性。
open_questions:
  - (none)

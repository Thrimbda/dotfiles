# acorn 新配置适配与构建修复

## 问题定义

acorn 当前需要适配仓库升级后的配置体系，并通过新的 flake / nixpkgs 组合完成系统构建。已确认 acorn 的构建链路会进入 `modules/profiles/role/server.nix`，而该处仍强制引用已在当前 nixpkgs 中移除的 `linux_6_9_hardened`，导致 `nix build .#nixosConfigurations.acorn.config.system.build.toplevel` 直接失败。

## 验收标准

- `nix build .#nixosConfigurations.acorn.config.system.build.toplevel` 在当前 darwin 开发机上评估/构建通过。
- 变更保持在 acorn 相关路径与最小必要共享模块内，不引入额外行为漂移。
- vaultwarden 相关模块若无明确构建/安全问题，不做功能性回归修改；若有调整，必须保持 secrets、备份目录权限、fail2ban 与 nginx 反代边界不退化。
- 任务产物完整落盘到 `.legion/tasks/acorn/docs/`，包含 RFC、测试报告、代码评审、安全评审与 PR body。

## 假设

- darwin 主机可以完成 NixOS 配置的求值与大部分构建验证，但无法替代在目标 NixOS 主机上的运行时切换验证。
- 当前目标优先是“让 acorn 在新配置下可构建”，不是顺带重构所有 server profile 使用者。
- `pkgs.linuxPackages_hardened` 或等价的受支持 hardened kernel 集合可作为 `linux_6_9_hardened` 的安全替代。

## 约束

- `plan.md` 是唯一任务契约；详细设计单独放在 `docs/rfc.md`。
- 过程产物统一存放到 `.legion/tasks/acorn/docs/`，不污染根目录 `docs/`。
- 仅允许修改 acorn 主机配置、最小必要共享模块和对应 LegionMind 文档。

## 风险分级

- **等级**: Medium
- **标签**: `continue`, `risk:medium`
- **理由**: 修复点虽小，但触及共享 `server` profile 与系统内核安全基线，影响多台 server 主机的默认行为；同时任务要求优先保障 vaultwarden 稳定安全，因此在实现前需要一份简短 RFC 明确替代策略与不改动边界。

## 目标

让 acorn 主机配置适配当前仓库的新配置方式，并在 darwin 环境下尽可能验证到 nix build 通过，同时优先保障 vaultwarden 相关服务稳定安全。

## 要点

- 先定位 acorn 在当前 flake 下的真实构建阻塞，再决定最小修复面。
- 对共享 server profile 的修改要选择“持续受支持”的 hardened kernel 入口，避免再次因版本淘汰失效。
- vaultwarden 相关配置优先保持现状，仅在构建或安全边界需要时做最小调整。
- 交付包含可直接用于 PR 的说明文档，减少后续人工整理。

## 允许 Scope

- `hosts/acorn/**`
- `modules/profiles/role/server.nix`
- `modules/agenix.nix`（仅允许为 acorn 的跨平台求值增加最小可控开关）
- `modules/services/vaultwarden.nix`（仅当构建/安全验证证明有必要）
- `flake.nix`（仅当 acorn 构建入口需要最小修复时）
- `.legion/tasks/acorn/**`

## Design Index

- RFC: `.legion/tasks/acorn/docs/rfc.md`（Medium 风险，先收敛共享内核替代策略与 vaultwarden 不变更边界）

## Phase Map

1. **阶段 1 - 设计与现状确认**：确认构建入口、故障根因、风险等级，并形成 RFC。
2. **阶段 2 - 实现与构建修复**：按 RFC 修复 acorn/共享配置，迭代到 `nix build` 通过。
3. **阶段 3 - 验证与交付文档**：产出测试、评审、walkthrough 与 PR body。

---

*创建于: 2026-03-24 | 最后更新: 2026-03-24*

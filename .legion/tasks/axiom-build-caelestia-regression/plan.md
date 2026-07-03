# Axiom Build And Caelestia Regression

## 目标

让 Axiom 在当前 flake 输入下重新可 build、可 switch，并修复 switch 重启后暴露的桌面回归：Caelestia 无法启动、Foot/terminal 字体异常。

## 问题

Axiom build 先后被 insecure `pnpm-10.29.2` 和 `docker-28.5.2` 阻断。局部 package override 后 build 已恢复，但真实 switch 重启暴露运行时问题：Caelestia shell 启动失败，terminal 字体不符合当前桌面基线。

## 验收标准

- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel` 通过。
- Axiom 不再依赖 insecure `pnpm-10.29.2` 或 `docker-28.5.2` 才能求值。
- Caelestia session runner 的 evaluated command/path 能解析到有效 binary，并与当前 flake 输入兼容。
- Foot/terminal evaluated font 配置回到 `modules.desktop.term.font` 负责的字体真源。
- 文档只保留轻量 contract、过程日志和验证摘要。

## 范围

- Axiom host-local Vesktop pnpm override。
- Reusable Docker module package option，以及 Axiom host-local Docker 29 选择。
- Axiom Caelestia 启动回归的最小修复。
- Axiom terminal 字体回归的最小修复。
- 针对 Axiom 的 Nix evaluation/build 验证。

## 非范围

- 不做全量 flake input 升级策略。
- 不重写 Caelestia 架构或恢复旧 end4/Quickshell 产品路径。
- 不扩大到所有 hosts 的 Docker 版本迁移，除非模块默认行为必须修正。
- 不做 live GUI 深度测试；本轮以 evaluated config、build 和用户后续 switch smoke 为准。

## 假设与约束

- 当前仓库可能已有用户修改的 `flake.lock`，本任务不主动回滚。
- 修复应优先使用 host-local override，而不是 `permittedInsecurePackages`。
- Terminal 字体真源是 `.legion/wiki` 已记录的 `modules.desktop.term.font` / `hey.info.term.font`，不是旧 theme terminal font。
- Caelestia 当前路线仍是 upstream `caelestia-dots/shell` flake package + repo-owned session runner。

## 风险

- 更新后的 Caelestia/Quickshell package 输出或 binary 名称可能变化，导致已有 runner path 失效。
- Terminal 字体异常可能来自 evaluated config、font package 缺失、Foot cache/runtime state 或 user override；需要先定位再改。
- Docker 29 切换可能影响已有本地 Docker daemon 行为，但比允许 unmaintained Docker 28 更安全。

## 推荐方向

保持低风险、最小修复：先修 package selection 和 evaluated config，再通过 Axiom build 验证；如果运行时仍有 user-state 问题，只记录明确的手动 smoke/cleanup 建议，不把 mutable state 纳入 Nix ownership。

## 阶段

1. 建立轻量 Legion task 文档。
2. 复核 build package overrides。
3. 诊断 Caelestia evaluated startup path。
4. 诊断 Foot/terminal evaluated font 配置。
5. 实施最小修复并验证。
6. 写简短验证与交付文档。

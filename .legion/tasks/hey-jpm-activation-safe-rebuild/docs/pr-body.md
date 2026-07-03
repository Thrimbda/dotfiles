## 交付摘要

- 修复 `hey` activation 的 JPM rebuild 可靠性。
- Janet 版本、`project.janet` hash 变化或 active runtime 不可用时，先在 staging JPM tree 中重建。
- 只有 staging rebuild 和 `hey path home` smoke 成功后才替换 active JPM artifacts。
- 如果 staging rebuild 失败但旧 runtime 仍可用，保留旧 tree；如果旧 runtime 也不可用，activation 明确失败。

## 范围

**In scope**

- `modules/hey.nix` activation rebuild logic。
- 轻量 Legion docs 和验证记录。

**Out of scope**

- 不迁移 `hey hook` 到 `c1ctl`。
- 不重写 `hey` Janet 模块。
- 不迁移 `sync/build/gc/profile` 等命令。

## 验证

- Activation script: `zsh -n` pass。
- Focused eval markers: staging/runtime probe/project hash present。
- `git diff --check` pass。
- `nix build --impure --no-link '.#nixosConfigurations.axiom.config.system.build.toplevel'` pass。

## 风险与限制

- 当前 live machine 已经处于 JPM tree 缺模块状态；本 PR 防止后续 activation 再破坏旧 runtime，并会在下一次成功 switch/activation 时重建。
- 如果 switch 时仍无法访问 GitHub 且没有 usable old runtime，activation 会明确失败；这是比静默留下坏 `hey` 更安全的行为。

# Hey JPM Activation Safe Rebuild

## 目标

修复 `hey` activation 在 Janet 版本变化或 JPM 依赖重建时的可靠性：即使 boot/switch 时 GitHub 或 DNS 不可用，也不能把当前可用的 `hey` runtime 清空到不可启动状态。

## 问题

上一轮修复会在 Janet 版本变化时先删除 `${JANET_TREE}/lib`、`build` 和 `bin/hey`，再运行 `jpm deps` / `jpm run deploy`。如果 activation 当时无法访问 GitHub，重建失败后 `hey` 缺少 `spork/path` 等模块，Hyprland `exec-once = hey hook startup` 仍会失败，Caelestia 不能自启。

## 验收标准

- `modules/hey.nix` 不再先破坏 active JPM tree 后尝试联网重建。
- 重建失败时，旧的可用 runtime 会保留；如果旧 runtime 已不可用，activation 明确失败但不制造半替换状态。
- `hey` 仍可在重建成功后使用当前 Janet ABI 的依赖。
- 不迁移 `hey hook` 到 `c1ctl`；这是后续任务。

## 范围

- `modules/hey.nix` activation rebuild logic。
- 轻量验证和任务文档。

## 非范围

- 不实现 native `c1ctl hook`。
- 不重写 `hey` 的 Janet 模块结构。
- 不迁移 `sync/build/gc/profile` 等命令。

## 推荐方向

使用 staging JPM tree：在临时 tree 中运行 `jpm deps` 和 `jpm run deploy`，成功后再替换 active `build/lib/bin/hey` 和 Janet version marker。失败时保留现有 active tree。

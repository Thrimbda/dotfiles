# Review Change

## 结论

PASS。

## Blocking Findings

无。

## Scope Check

- 只修改 `modules/hey.nix` 的 activation rebuild logic。
- 未迁移 `hey hook` 到 `c1ctl`。
- 未触碰 Caelestia、Hyprland keybind/session runner、Docker/Vesktop 或 flake lock。

## Security / Safety Lens

触发点：activation 会替换 user-local JPM artifacts。

判断：非阻塞。替换范围仍限定在既有 `${JANET_TREE}` 下的 `build`、`lib`、`man` 和 `bin/hey`。新逻辑先在 staging tree 中重建并通过 `hey path home` smoke，再替换 active artifacts；失败时保留可用旧 runtime 或明确 fail，避免半坏状态。

## Notes

- 该修复仍依赖 `jpm deps` 能在需要 rebuild 时访问 GitHub；长期方向仍是把 desktop-critical hook 从 Janet/JPM 上移走，或把 `hey` dependencies Nix 化。

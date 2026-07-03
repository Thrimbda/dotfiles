# Hey JPM Activation Safe Rebuild - 日志

- 用户确认暂不迁移 `hey` 到 `c1ctl`，先修 `hey` 本身。
- Live 根因：`nixos-activation.service` boot 时运行 `jpm deps`，DNS 无法解析 `github.com`，上一轮逻辑已清掉 active JPM `lib`，导致 `hey` 后续缺 `spork/path`。
- 实现：`modules/hey.nix` 现在只在 Janet version、`project.janet` hash 变化或 active runtime 不可用时重建；重建在 staging JPM tree 内完成并通过 `hey path home` smoke 后才替换 active tree。
- 失败语义：staged rebuild 失败时，如果旧 `hey` runtime 仍可用则保留旧 tree 并继续；如果旧 runtime 也不可用则 activation 明确失败，避免静默进入半坏状态。

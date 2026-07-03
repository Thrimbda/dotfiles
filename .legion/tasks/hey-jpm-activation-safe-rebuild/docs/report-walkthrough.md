# Report Walkthrough

## Mode

implementation

## Reviewer Summary

- 修复 `hey` activation 的 JPM rebuild 可靠性，避免 GitHub/DNS 短暂不可用时清空 active runtime。
- 新逻辑只在 Janet version、`project.janet` hash 变化或 active `hey` runtime 不可用时重建。
- 重建使用 staging JPM tree，成功并通过 `hey path home` smoke 后才替换 active artifacts。
- 不迁移 `hey hook` 到 `c1ctl`；该方向留给后续任务。

## Evidence

- 验证: `docs/test-report.md`
- 审查: `docs/review-change.md`
- 任务契约: `plan.md`

## Risks

- 如果必须 rebuild 且 GitHub 仍不可达，同时旧 runtime 已不可用，activation 会失败。这是有意行为，比静默留下坏 `hey` 更安全。
- 当前 live broken tree 需要下一次成功 switch/activation 或手动确认后的 repair 才恢复。

## Next

提交 PR 并合并后，重新 switch；若想立即修当前 session，可手动触发一次 safe rebuild/activation。

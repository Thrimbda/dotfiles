# Report Walkthrough

## Profile

implementation

## Reviewer Summary

- 本任务为 `aliyun-acorn` 增加 host-level Nix binary cache mirror。
- 最终 substituter 顺序已验证为 TUNA、nix-community Cachix、Hyprland Cachix、官方 cache。
- `aliyun-acorn` NixOS toplevel derivation 求值成功。
- 变更审查 PASS，未发现 blocking finding。

## Scope

In scope:
- `hosts/aliyun-acorn/default.nix`
- `.legion/tasks/aliyun-acorn-nix-cache-mirror/`

Out of scope:
- 不改 `flake.nix` / `flake.lock` 的 input 来源。
- 不改其他 hosts 或全局 Nix cache 策略。
- 不新增 trusted public key、私有 cache 或代理配置。

## Evidence Map

| Claim | Evidence | Status |
|---|---|---|
| TUNA mirror 位于最终 substituter 列表第一位 | `docs/test-report.md` | PASS |
| Cachix 和官方 cache 仍保留 fallback | `docs/test-report.md` | PASS |
| `aliyun-acorn` 配置仍可求值 | `docs/test-report.md` | PASS |
| 变更符合 scope 且无 blocker | `docs/review-change.md` | PASS |
| 设计选择和回滚路径明确 | `docs/rfc.md` | PASS |

## What Changed / What Was Decided

`hosts/aliyun-acorn/default.nix` 新增：

```nix
nix.settings.substituters = lib.mkBefore [
  "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
];
```

采用 `lib.mkBefore` 的原因是只调整 `aliyun-acorn` 的优先级，不覆盖现有 Cachix 和官方 cache fallback。

## Verification / Review Status

- `nix eval '.#nixosConfigurations.aliyun-acorn.config.nix.settings.substituters' --json`: PASS
- `nix eval '.#nixosConfigurations.aliyun-acorn.config.system.build.toplevel.drvPath'`: PASS
- `docs/review-change.md`: PASS

## Risks and Limits

- 国内 dynamic cache 可能缺少个别 nar，fallback 已保留。
- 该变更不解决 GitHub flake input 首次拉取或 update 慢的问题。
- 未执行 `nixos-rebuild switch`，避免修改当前机器系统状态。

## Reviewer Checklist

- [ ] 确认只希望 `aliyun-acorn` 使用该 mirror 优先级。
- [ ] 确认不需要把该策略提升为全局默认。
- [ ] 确认保留官方 cache fallback 符合预期。

## Next Stage

PR-backed lifecycle 仍需 commit、push、PR、checks/review、merge/blocked handoff、worktree cleanup 和主工作区 refresh。`docs/pr-body.md` 只是 PR 创建输入，不代表 lifecycle 完成。

## Render Handoff

HTML artifact 已生成在 `docs/report-walkthrough.html`。`pr-html-render` 检查后记录为 artifact-only/blocker：当前任务没有配置 Pages preview workflow，也尚无 PR URL 可挂载 preview；本任务不扩 scope 新增 workflow。Reviewer 可通过 PR 文件或 artifact 打开 HTML。

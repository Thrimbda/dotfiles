# Report Walkthrough

## Profile

implementation

## Reviewer Summary

- 本任务只在 `aliyun-acorn` host scope 内扩展 Nix/NixOS binary cache 优先级。
- 最终 substituter 顺序已验证为 TUNA、USTC、SJTU、nix-community Cachix、Hyprland Cachix、官方 cache。
- 官方 `cache.nixos.org` trusted public key 已验证保留。
- `aliyun-acorn` NixOS firewall 最终 TCP ports 已验证包含 `2222`。
- `./hosts/aliyun-acorn/image#aliyun-image` 已通过 drvPath 求值验证。
- 变更审查 PASS，安全视角已覆盖 Nix cache trust chain 与 TCP 2222 暴露面。

## Scope

In scope:

- `hosts/aliyun-acorn/default.nix`
- `.legion/tasks/aliyun-acorn-nix-cache-mirror/`

Out of scope:

- 不改 `flake.nix` / `flake.lock` 的 input 来源。
- 不改其他 hosts、Darwin 配置或全局 Nix cache 策略。
- 不新增私有 cache、Cachix token、代理配置或新的 trusted public key。
- 不修改 Aliyun 安全组、TCP 2222 背后的服务、认证方式或 SSH 监听端口。

## Evidence Map

| Claim | Evidence | Status |
|---|---|---|
| Domestic mirrors 位于最终 substituter 列表前部 | `docs/test-report.md` | PASS |
| Cachix 和官方 cache 仍保留 fallback | `docs/test-report.md` | PASS |
| 官方 `cache.nixos.org` key 仍保留 | `docs/test-report.md` | PASS |
| TCP 2222 已被 NixOS firewall 允许 | `docs/test-report.md` | PASS |
| `./hosts/aliyun-acorn/image#aliyun-image` 可求值 | `docs/test-report.md` | PASS |
| 变更符合 scope 且无 blocker | `docs/review-change.md` | PASS |
| 设计选择和回滚路径明确 | `docs/rfc.md` | PASS |

## What Changed / What Was Decided

`hosts/aliyun-acorn/default.nix` 中的 host-level Nix settings 现在 prepend 三个国内 mirrors：

```nix
nix.settings.substituters = lib.mkBefore [
  "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
  "https://mirrors.ustc.edu.cn/nix-channels/store"
  "https://mirror.sjtu.edu.cn/nix-channels/store"
];
```

采用 `lib.mkBefore` 的原因是只调整 `aliyun-acorn` 的优先级，不覆盖既有 Cachix 和 NixOS 默认官方 cache fallback。

同一 host 的 NixOS firewall TCP allow-list 增加 `2222`：

```nix
allowedTCPPorts = [ 22 80 443 2222 2225 7000 34197 ];
```

## Verification / Review Status

- `nix eval --option eval-cache false '.#nixosConfigurations.aliyun-acorn.config.nix.settings.substituters' --json`: PASS
- `nix eval --option eval-cache false '.#nixosConfigurations.aliyun-acorn.config.nix.settings.trusted-public-keys' --json`: PASS
- `nix eval --option eval-cache false '.#nixosConfigurations.aliyun-acorn.config.networking.firewall.allowedTCPPorts' --json`: PASS
- `nix eval --option eval-cache false './hosts/aliyun-acorn/image#aliyun-image.drvPath'`: PASS
- `docs/review-change.md`: PASS

## Risks and Limits

- 国内 dynamic cache 可能缺少个别 nar，fallback 已保留。
- 该变更不解决 GitHub flake input 首次拉取或 update 慢的问题。
- TCP 2222 只在 NixOS firewall 层放行；Aliyun 安全组、服务监听和认证策略仍需由对应运维配置控制。
- 未执行完整 image build，避免生成 QCOW2 image；本次使用 drvPath eval 覆盖用户指定 image target。

## Reviewer Checklist

- [ ] 确认只希望 `aliyun-acorn` 使用该 domestic mirror 优先级。
- [ ] 确认 TCP 2222 的 NixOS firewall 放行符合预期。
- [ ] 确认不需要把该 cache 策略提升为全局默认。
- [ ] 确认保留官方 cache fallback 和 trusted key 符合预期。

## Next Stage

PR-backed lifecycle 仍需 commit、push、PR、checks/review、merge/blocked handoff、worktree cleanup 和主工作区 refresh。`docs/pr-body.md` 只是 PR 创建输入，不代表 lifecycle 完成。

# Review Change: Aliyun Acorn Nix Cache Mirror

## 结论

PASS

当前变更可以进入交付阶段。

## Blocking Findings

无。

## Scope Review

- 允许范围: `hosts/aliyun-acorn/default.nix` 与 `.legion/tasks/aliyun-acorn-nix-cache-mirror/`。
- 实际实现 diff: `hosts/aliyun-acorn/default.nix` 新增 4 行 host-level `nix.settings.substituters`。
- 未修改 `flake.nix`、`flake.lock`、全局 `default.nix`、其他 hosts 或 trusted public keys。
- 结论: 符合 scope。

## Correctness Review

- 使用 `lib.mkBefore` prepend TUNA mirror，不覆盖已有 global substituters。
- 验证结果显示最终顺序为 TUNA、nix-community Cachix、Hyprland Cachix、官方 cache。
- `aliyun-acorn` toplevel derivation 求值成功。
- 结论: 行为符合任务目标。

## Maintainability Review

- 改动保持在 host config 内，读者可以从 `aliyun-acorn` 配置直接理解这是机器特定网络优化。
- 没有新增 helper、module abstraction 或全局 option，避免为单 host 需求引入过度抽象。
- 结论: 可维护性可接受。

## Security Review

安全触发项: 未命中。

理由：本变更不涉及认证、权限、身份、会话、密钥、签名、加密、webhook、隐私数据或用户输入进入高权限路径。新增的是公开 Nix binary cache substituter，且未新增 trusted public key；仍依赖现有 Nix cache 签名校验和 fallback。

## Residual Risks

- TUNA dynamic cache 可能偶发缺少 nar；已有 Cachix 和官方 cache fallback 缓解。
- GitHub flake inputs 首次拉取或更新仍可能慢；这是非目标范围，需要后续代理或 input mirror 策略处理。

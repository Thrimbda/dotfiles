# Review Change: Aliyun Acorn Nix Cache Mirror

## 结论

PASS

当前变更可以进入交付阶段。

## Blocking Findings

无。

## Scope Review

- 允许范围: `hosts/aliyun-acorn/**` 与 `.legion/tasks/aliyun-acorn-nix-cache-mirror/`。
- 实际实现 diff: `hosts/aliyun-acorn/default.nix` 扩展 host-level domestic substituters，并在该 host 的 firewall TCP ports 中加入 `2222`。
- 未修改 `flake.nix`、`flake.lock`、全局 `default.nix`、其他 hosts、Darwin 配置、Aliyun 安全组或端口背后的服务。
- 结论: 符合 scope。

## Correctness Review

- `lib.mkBefore` 保持国内 mirrors 位于最终 substituter 列表前部，不覆盖既有 global Cachix 或 NixOS 默认官方 cache fallback。
- 验证结果显示最终顺序为 TUNA、USTC、SJTU、nix-community Cachix、Hyprland Cachix、官方 cache。
- 验证结果显示官方 `cache.nixos.org` trusted public key 仍在最终配置中。
- 验证结果显示 `networking.firewall.allowedTCPPorts` 包含 `2222`。
- `./hosts/aliyun-acorn/image#aliyun-image.drvPath` 求值成功。
- 结论: 行为符合任务目标。

## Maintainability Review

- 改动保持在 `aliyun-acorn` host config 内，读者可以从该 host 配置直接理解这是机器特定网络优化和端口放行。
- 没有新增 helper、module abstraction 或全局 option，避免为单 host 需求引入过度抽象。
- 结论: 可维护性可接受。

## Security Review

安全触发项: 命中。

原因：本变更涉及 Nix binary cache 信任链结果检查和 firewall TCP port exposure。

安全判断：

- Domestic mirrors 只新增 substituter URL，不新增 trusted public key；最终配置仍依赖官方 `cache.nixos.org` key 和既有 Cachix keys 验证 nar 签名。
- `https://cache.nixos.org/` fallback 和官方 public key 均由 `nix eval` 证明仍保留。
- TCP 2222 只加入 NixOS firewall allow-list；本任务没有启动新服务、改变 SSH 监听端口、放宽认证或修改云安全组。
- 残余暴露面是用户明确要求的端口放行；若 Aliyun 安全组也放行且本机有服务监听 2222，该端口会对对应网络边界开放。

安全结论: 无 blocking 安全问题。残余风险已记录，后续如需控制公网入口应在 Aliyun 安全组或服务配置任务中处理。

## Residual Risks

- 国内 mirror 可能偶发缺少 nar；既有 Cachix 和官方 cache fallback 缓解。
- GitHub flake inputs 首次拉取或更新仍可能慢；这是非目标范围，需要后续代理或 input mirror 策略处理。
- TCP 2222 的云侧安全组、服务监听与认证策略未在本任务中管理；这是用户要求的 scope 边界。

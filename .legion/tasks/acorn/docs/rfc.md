# acorn 构建修复短 RFC：移除已失效的固定 hardened 内核版本依赖

## 摘要 / 背景

`acorn` 是一个 NixOS host，当前在新 `nixpkgs/flake` 下执行 `nix build .#nixosConfigurations.acorn.config.system.build.toplevel` 失败。已确认根因是 `modules/profiles/role/server.nix:36` 强制设置 `boot.kernelPackages = mkForce pkgs.linuxKernel.packages.linux_6_9_hardened;`，而 `nixpkgs 25.11` 已移除该固定版本入口。`hosts/acorn/default.nix:7-10` 通过 `role = "server"` 间接命中此共享配置。

本 RFC 的优先目标是让 `acorn` 恢复可构建，同时保持 server profile 的安全意图不退化，并明确本次对 vaultwarden 的边界：默认不改功能配置，只验证其依赖边界未因内核入口调整而回归。

## 问题

- 共享 `server` profile 依赖了已下线的内核包入口，导致任何命中该 profile 的主机构建都可能失败。
- 该问题不是 `acorn` 私有业务配置错误，而是共享基线与新 `nixpkgs` 不兼容。
- `acorn` 承载 vaultwarden，修复应优先保证“先恢复构建，再验证安全边界未回退”，避免顺带修改 vaultwarden 行为。

## 目标 / 非目标

### 目标

- 恢复 `acorn` 在当前 flake 下的 `nix build` 能力。
- 保持 `server` profile 使用受支持的 hardened kernel 入口，而不是继续绑定会过期的具体版本名。
- 对 vaultwarden 保持最小扰动：不改功能配置，只验证其 service、nginx、fail2ban、secret 依赖边界未因本次变更退化。

### 非目标

- 不在本次任务中重构所有 server 主机的内核策略。
- 不主动修改 `modules/services/vaultwarden.nix` 或 `hosts/acorn/modules/vaultwarden.nix` 的功能参数。
- 不扩展到 scope 外的 flake、镜像、部署流水线或运行时切换方案。

## 定义 / 约束

- **共享 server profile**：`modules/profiles/role/server.nix`，对所有 `role = "server"` 的主机生效。
- **受支持入口**：指当前 `nixpkgs` 仍维护的 hardened kernel package set，例如 `pkgs.linuxPackages_hardened` 或仓库内等价受支持入口。
- **约束**：仅在 `hosts/acorn/**`、`modules/profiles/role/server.nix`、以及“若后续证明必要”的 vaultwarden/flake 范围内行动；不修改 `.legion` 三文件。

## 执行摘要

- **改什么**：把 `modules/profiles/role/server.nix` 中已失效的 `linux_6_9_hardened` 替换为当前受支持的 hardened kernel 入口，首选 `pkgs.linuxPackages_hardened`。
- **不改什么**：默认不改 vaultwarden 功能配置，不扩展到部署流水线、镜像或无直接证据的问题修复。
- **怎么验**：分三段验证——darwin 侧求值检查、Linux 侧构建检查、目标机切换后的运行时检查。
- **怎么回滚**：保留仓库 patch 回退，同时补充 generation / bootloader / `nixos-rebuild switch --rollback` 的主机级回滚路径。

## 影响面（blast radius）

- 当前 repo 内可见命中 `role = "server"` 的主机：`acorn`。
- 代码变更点预计仅 1 处：`modules/profiles/role/server.nix`。
- 真实风险面主要在运行时：Azure 虚机启动兼容性、内核/模块兼容性、以及切换后 vaultwarden 连续性。
- 因此推荐共享修复的理由应理解为“当前最小且与架构一致”，而不是“顺带覆盖多主机”。

## 方案候选

### 方案 A：修复共享 server profile，改为受支持的 hardened kernel 入口

做法：将 `modules/profiles/role/server.nix:36` 从固定版本 `pkgs.linuxKernel.packages.linux_6_9_hardened` 改为当前受支持的 `pkgs.linuxPackages_hardened`（或仓库里等价、同语义的支持入口）。继续由共享 profile 统一定义 server 主机默认 hardened 内核策略。

优点：

- 直接修复根因，避免其他 `role=server` 主机继续踩同类问题。
- 从“固定版本名”切换到“受支持集合入口”，更符合“新配置可用配置”的持续维护目标。
- 保留原有安全意图：server 默认仍走 hardened 内核，而不是静默退回普通 kernel。

代价 / 风险：

- 共享 profile 变更可能影响其他 server 主机的求值结果，需要至少做一次 repo 内引用面检查与基础评估。
- `linuxPackages_hardened` 的具体底层版本会随 `nixpkgs` 演进，需要接受“跟随 channel 更新”的维护模型。

### 方案 B：仅在 `hosts/acorn` 做主机级覆盖，绕过共享 profile

做法：在 `hosts/acorn/default.nix` 或其局部模块里覆盖 `boot.kernelPackages`，让 `acorn` 使用受支持入口或直接回退到普通默认 kernel，从而规避共享 profile 的失效配置。

优点：

- 改动面最小，短期内只影响 `acorn`。
- 若担心共享变更影响其他主机，可更快落地验证。

代价 / 风险：

- 没有修复真正根因；其他 `role=server` 主机仍可能在升级时失败。
- 形成“共享 profile 失效 + 单主机打补丁”的漂移，后续维护成本更高。
- 若 acorn 覆盖为非 hardened kernel，会弱化原有安全基线；即使仍使用 hardened，也会把通用策略分散到主机层。

## 推荐方案

推荐采用 **方案 A：在共享 `server` profile 中改为受支持的 hardened kernel 入口**。

原因：

1. 它直接修复与新 `nixpkgs` 的接口失配，而不是把问题藏到单主机覆盖里。
2. 它保留“server 默认启用 hardened kernel”的安全意图，与现有 profile 设计一致。
3. 它更符合“新配置可用配置”的持续维护目标：后续应依赖受支持入口，而不是依赖会被删除的具体版本名。
4. 相比 host-level workaround，共享修复可减少配置漂移，降低未来升级时的认知负担。

落地原则：

- 优先写成最小替换，不顺带调整其他 server 行为。
- 若 `pkgs.linuxPackages_hardened` 在当前仓库上下文不可用，再退一步选择仓库中等价、受支持的 hardened 入口；不要重新引入固定版本号。
- vaultwarden 配置默认不动，只在后续验证证明其构建/运行依赖被波及时再做最小修复。

## 数据模型 / 接口影响

- 本次无新增持久化数据模型。
- 受影响接口为 NixOS 配置项：`boot.kernelPackages`。
- 兼容策略：
  - 配置语义保持不变：`role=server` 仍获得 hardened kernel。
  - 变更的是包入口绑定方式：从“固定版本 attr”切换为“受支持 package set attr”。
  - 对 `acorn` 的 host 配置接口无新增字段、无迁移脚本需求。

## 错误语义

- 若替换后 `nix build` 通过，则视为已修复当前 blocker。
- 若替换后出现新的 kernel package 求值错误，允许在 scope 内继续调整为等价受支持入口，属于**可恢复错误**。
- 若替换后暴露 vaultwarden 相关构建错误，先判断是否由本次内核入口替换直接触发；只有证据成立时才进入 vaultwarden 最小修复，避免把无关历史问题混入本变更。

## vaultwarden 边界

本次默认**不修改 vaultwarden 功能配置**。只有当报错栈、option eval 路径、或构建失败信息**直接指向** `hosts/acorn/modules/vaultwarden.nix` 或 `modules/services/vaultwarden.nix` 时，才允许触碰 vaultwarden 相关文件；否则一律记为独立后续问题，不在本 RFC 内处理。

验证重点仅包括：

- `hosts/acorn/modules/vaultwarden.nix` 仍可被正常求值；
- `services.vaultwarden`、`services.nginx.virtualHosts."vault.0xc1.space"`、`services.fail2ban.jails.*`、`age.secrets.vaultwarden-env` 的依赖边界未因内核入口调整发生明显回归；
- 若后续构建或评估中出现 vaultwarden 相关失败，再按“最小改动、保持 secrets/备份目录权限/fail2ban/nginx 边界不退化”的原则单独处理。

## 风险、发布与回滚

### 主要风险

- 共享 profile 代码虽为通用层，但当前 repo 内实际命中主机主要是 `acorn`；因此主要风险不是“多主机扩散”，而是 `acorn` 的运行时内核切换。
- `hardened` 包集合随 channel 演进，个别驱动/模块兼容性问题可能在运行时而非求值阶段暴露。
- `hosts/acorn/default.nix` 引入 `azure-common.nix`，因此运行时风险包含 Azure 虚机环境下的启动兼容性。
- darwin 侧验证不能替代 Linux builder/目标主机的真实 NixOS 构建与切换验证。

### 回滚策略

- **仓库侧回滚**：直接回退 `modules/profiles/role/server.nix` 本次 patch，恢复变更前版本。
- **发布前准备**：在目标机执行切换前记录当前 system generation，确认 bootloader 可见上一代。
- **运行时回滚**：若新 generation 启动或运行异常，优先从 bootloader 选择上一代；若主机仍可登录，则执行 `nixos-rebuild switch --rollback`。
- **应急止血**：若共享修复需要暂缓，但 acorn 必须先恢复构建，可临时使用方案 B 的 host 级覆盖；该方案必须视为短期过渡并在后续收回。

## rollout / observability / milestones

### Rollout

1. 在 darwin 工作机完成求值级验证，确认失效 attr 已去除。
2. 在可用的 Linux builder 或目标 NixOS 主机完成 `acorn` 的真实构建。
3. 在目标机执行切换，再做服务连续性与日志检查。

### Observability

- `systemctl status vaultwarden nginx fail2ban`
- `journalctl -u vaultwarden -u nginx -u fail2ban --since "-15m"`
- `ss -ltnp` 或等价方式确认 `80/443` 与 vaultwarden 后端端口仍按预期监听
- 若 Azure 虚机启动异常，优先检查 bootloader/generation 与串口控制台输出

### Milestones

- **Milestone 1**：移除失效 attr，darwin 上完成 `nix eval`/求值检查。
- **Milestone 2**：在 Linux 环境完成 `nix build .#nixosConfigurations.acorn.config.system.build.toplevel`。
- **Milestone 3**：目标机切换后确认 vaultwarden / nginx / fail2ban / age secrets 相关边界未回归。

## 验证计划

关键行为与验收映射：

1. **共享 profile 不再引用失效 attr**  
   - 检查 `modules/profiles/role/server.nix` 不再出现 `linux_6_9_hardened`。
2. **darwin 求值验证成立**  
   - 运行 `nix eval .#nixosConfigurations.acorn.config.system.build.toplevel.drvPath` 或等价求值检查，确认 attr 可解析。
3. **Linux 构建验证成立**  
   - 在 Linux builder 或目标 NixOS 主机运行 `nix build .#nixosConfigurations.acorn.config.system.build.toplevel`。
4. **vaultwarden 边界未明显回归**  
   - 对 `hosts/acorn/default.nix`、`hosts/acorn/modules/vaultwarden.nix`、`modules/services/vaultwarden.nix` 做评估级检查，确认相关模块仍被导入，关键 option 路径仍可求值。
5. **目标机切换后的运行时检查具备执行标准**  
   - 在目标机执行切换后，检查 `vaultwarden` / `nginx` / `fail2ban` 服务状态、近 15 分钟日志和端口监听情况。
6. **未超出 scope 引入额外变更**  
   - 变更文件应限制在 `modules/profiles/role/server.nix` 与必要时的 `hosts/acorn/**` / `modules/services/vaultwarden.nix` / `flake.nix`。

## 未决问题

- 当前仓库中是否还有其他 `role=server` 主机依赖该共享 profile 且在近期会一并迁移到新 `nixpkgs`？若有，实施时应补一轮受影响主机清单评估。
- 若 `pkgs.linuxPackages_hardened` 在本仓库 overlay/包集上下文中被重定义，是否存在更优的统一受支持入口？实现前可快速确认，但不应扩大为重构任务。

## 落地计划

### 预计文件变更点

- `modules/profiles/role/server.nix`：将固定版本 hardened kernel 替换为受支持入口。
- `hosts/acorn/**`：仅当共享修复后仍需最小 host 侧补充时才修改。
- `modules/services/vaultwarden.nix`、`flake.nix`：仅当验证证明确有必要时才进入。

### 实施步骤

1. 修改 `server.nix` 中的 `boot.kernelPackages` 绑定方式。
2. 重新执行 `acorn` 的 `nix build` 验证 blocker 是否消失。
3. 若构建继续失败，按报错确认是否属于 vaultwarden 或 flake 入口的次级问题，再决定是否做最小补丁。
4. 记录验证结果与回滚点，进入后续实现/测试文档阶段。

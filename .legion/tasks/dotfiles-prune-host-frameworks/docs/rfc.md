# RFC: Prune Raw Tasks and Extract Host Frameworks

> **Status**: Approved
> **Profile**: Standard
> **Design source**: `../plan.md`

## Decision

采用“共享 mechanics + host-local composition”两层结构：

- 共享 `modules/**` 只负责已经存在跨 host 需求的服务机制。
- `hosts/axiom/modules/**` 与 `hosts/acorn/modules/**` 负责各自拓扑和产品策略。
- `hosts/*/default.nix` 只保留主机清单、关键 facts、imports 和 hardware。
- 不新增 service graph DSL、Acorn framework namespace 或新的 profile 系统。

同时执行两项直接删除：删除所有旧 `.legion/tasks/*`，只保留本次 task；删除根 `README.md`。

## Evidence

- `.legion/tasks` 当前保存约 140 个任务和 1100 余个文件，而 `.legion/wiki/tasks` 已保存绝大多数任务的长期摘要。
- `hosts/axiom/default.nix` 约 1986 行，其中绝大部分是 RustDesk provisioning 脚本；Cloudflare、autossh、Caelestia、Auth Mini gateway 和 Axiom-to-Acorn FRP 拓扑也混在同一 `config` 函数中。
- `hosts/acorn/default.nix` 同时包含 Aliyun platform、ACME ingress、RustDesk server 和服务组合；它已经有 `hosts/acorn/modules/`，但顶层边界尚未完成。
- `modules/services/cloudflared.nix` 和 `modules/services/reverse-ssh.nix` 已经是正确的共享边界，只缺少少量 host 仍在手写的 mechanics。
- `modules/desktop/caelestia.nix` 已经拥有 package、session runner、mutable config 和 polkit mechanics；Axiom 不需要第二套 Caelestia abstraction，只需移出 host policy。

## Target Layout

### Shared modules

`modules/services/reverse-ssh.nix`

- 当 host 提供 `serviceHostKey` 且没有自定义 known-hosts 文件时，模块生成 service-private known-hosts 文件并用于 autossh；已有 `remoteHostKey` 的系统级 SSH pin 语义不变。
- host 继续提供 remote host/user/port/key；不引入 endpoint registry。

`modules/services/cloudflared.nix`

- `tunnelName` 作为 route 命令的唯一 option；host 不再把它塞进 `extraConfig`。
- `extraConfig` 继续承载 cloudflared 原生配置，例如 metrics/protocol；不新增 Cloudflare topology DSL。

`modules/services/auth-mini-gateway.nix`

- 统一 Axiom/Acorn 已重复的 system user、age secret metadata、loopback process、state directory 和 systemd hardening。
- 每个 host 只传 public host、port、upstream、dependencies、database/state facts 和少量额外环境变量；Nginx、FRP、placement 与防火墙不进入该接口。

`modules/services/nginx.nix`

- `cloudflareDnsAcme` 只把同一 credentials secret 与 hostname 列表展开为 DNS-01 certificate recipes。
- service-local modules 继续拥有 vhost、proxy、TLS attachment 和 public topology。

`modules/desktop/caelestia.nix`

- 保持现有公共接口；本任务不为 Axiom idle/favourite settings 新增通用 option。

### Axiom host-local modules

`hosts/axiom/modules/_facts.nix`

- 只保存多个本地模块共同需要的稳定事实，例如 Acorn public IP 和 SSH host key。
- 它是由 host-local modules 直接 import 的普通 attrset；不新增 option namespace、`specialArgs` 或 facts framework。

`hosts/axiom/modules/caelestia.nix`

- Axiom idle、launcher favourites、mutable migration、polkit 和 session path 组合。

`hosts/axiom/modules/cloudflare.nix`

- cloudflared connector、readiness healthcheck，以及现有 OpenCode/Gatus public ingress 组合。

`hosts/axiom/modules/autossh.nix`

- reverse SSH endpoint、host-key pin、`c1ctl` autossh facts 和 CLI target。

`hosts/axiom/modules/acorn.nix`

- FRP direct-route rule、Auth Mini gateway instances、FRP proxies 和 Axiom-to-Acorn unit ordering。
- 域名、IP、端口仍在该 host-local module 中直接可见。

`hosts/axiom/modules/rustdesk.nix`

- 机械承接现有 RustDesk client package/provisioning/service 实现。
- 不把一次性 provisioning 状态机泛化成公共 module API。

`hosts/axiom/modules/workstation.nix`

- 放置剩余 Axiom-only package、audio、Clash、firewall 和 workstation policy；不成为共享 catch-all module。

### Acorn host-local modules

保留现有 `auth-mini.nix`、`oneex-portfolio-adapter.nix`、`vaultwarden.nix`，新增：

- `platform.nix`: Aliyun guest、boot、network、resource limits、cloud-init 和 console。
- `ingress.nix`: 只承接当前 Acorn default 中的 Cloudflare DNS secret metadata、共享 ACME cert inventory 和 Vaultwarden nginx TLS attachment；不移动 `auth-mini.nix`、`oneex-portfolio-adapter.nix` 等 service-local TLS 配置。
- `rustdesk.nix`: RustDesk server key preflight、service hardening 和 assertions。

`hosts/acorn/default.nix` 只表达 system、module enablement 与这些 imports。

## Prune Semantics

- 删除所有已跟踪的 `.legion/tasks/**` 后重新加入本次 `dotfiles-prune-host-frameworks` 目录。
- `.legion/wiki/**` 不删除；其中指向旧 raw task 的路径视为 Git-history references，不逐文件重写。
- 在 wiki index 增加一次全局说明，避免把旧 raw-task path 当作当前 checkout 中的有效链接。
- 不创建新的 archive 目录，因为这会用另一套目录保留同一批噪音。

## Package Module Inventory

本任务只生成 `docs/package-module-inventory.md`：

- **可内联**：单 host 使用，主要行为只有安装 package。
- **待确认**：零使用或单 host 使用，但可能存在个人手工依赖或平台差异。
- **应保留**：多 host 使用，或拥有服务、配置生成、安全/平台策略。

Inventory 不触发 package module 删除，避免把架构抽取与产品删减绑在同一 PR。

## Alternatives

### 仅把 Axiom default 切成任意文件

可以降低单文件行数，但无法说明共享机制和 host facts 的边界。拒绝只做无语义分片。

### 建立通用 service topology DSL

可以描述 Cloudflare、FRP、gateway 和 monitoring graph，但当前只有少量具体拓扑，会增加 option、默认值和调试层。拒绝。

### 把所有服务都提升为共享 modules

RustDesk provisioning、Axiom display/session 和 Acorn ingress 含大量单 host policy。过早共享会把事实伪装成 API。拒绝。

## Migration Order

1. 建立 host-local modules，并让 defaults 通过显式 imports 组合。
2. 机械移动 RustDesk 与 Acorn service bodies，先不改变表达式。
3. 迁移 Cloudflare、autossh、Caelestia 和 Axiom-to-Acorn composition。
4. 仅在消除现有手写 mechanics 所需时调整共享 modules。
5. 生成 package inventory。
6. 删除 README 和旧 task directories。

## Verification

- 路径白名单：`.legion/tasks` 只有本次 task，`.legion/wiki` 文件数量不减少，README 不存在。
- 引用检查：新 host-local modules 被显式导入；默认文件不再包含长 shell script、Cloudflare/autossh/Caelestia service bodies。
- Axiom focused eval：reverse SSH `ExecStart`、known-hosts pin、FRP proxies/direct route、gateway units、cloudflared config/unit/healthcheck、Caelestia settings/session、RustDesk service/provisioning assertions。
- Acorn focused eval：network/firewall、ACME certs、RustDesk server services、auth-mini/vaultwarden/adapter enablement。
- 对被移动的 Axiom workstation policy 生成基线与候选 JSON 并直接 diff，至少覆盖 audio、Clash、packages、LAN firewall 和 SSH service policy。
- Axiom toplevel drvPath evaluation和可承受的 dry-run；Acorn 只做非构建 eval，绝不在 Acorn 本机 build/eval/switch，也不发起 live deployment。
- `git diff --check` 和 scope review；`flake.lock`、secret files、域名、端口和 tunnel ID 不得意外变化。

## Rollback

无数据或状态迁移。合并前丢弃分支；合并后 revert PR。模块移动若出现行为差异，可按 host-local module 边界连同对应 import/interface 调整一起回退，不需要兼容 alias。

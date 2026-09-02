# RFC 审查：Azar 上 Const X 原生 Auth Mini 部署

审查范围仅限 Azar 部署设计，以及当前 `hosts/acorn/modules/auth-mini.nix`、`hosts/acorn/modules/constx.nix` 所揭示的配置所有权。未审查尚未合入的 Const X release，也不把 RFC 自身的“无设计阻塞”断言当作证据。

## Verdict
FAIL

## 本次更新的时序判定

新增的顺序在理想执行下是正确的：若 gateway 外层保护持续生效，先启用并验证原生认证、后切透明入口，不会出现公开 user API 无认证的窗口；回滚时若 gateway 保护已经实际接管，后续关闭原生认证也不会暴露 upstream。

但当前 RFC 尚未把这两个“若”落实为可执行的硬门。特别是，复制 closure 不会改变当前已安装 `constxd.service` 的 `ExecStart`，而步骤 3 只检查 `/api/auth/config` enabled，未在切换透明 ingress 前证明目标 native binary 实际拒绝未认证 user API。回滚同样未在 `disable` 前要求确认有效 Nginx 配置已恢复 `auth_request`。因此不能据此宣称 transient open window 已被消除。

## Findings

### F1：移除 gateway 会同时失去 `constx` 的声明式 ACME host 所有权

> [REVIEW:blocking] `constx` 目前是 `gatewayInstances` 的一个成员；该集合同时派生 gateway unit、vhost 与 Cloudflare DNS-01 ACME host 列表。RFC 要移除这个成员并在 `constx.nix` 新增透明 vhost，但没有声明如何保留 `constx.0xc1.wang` 的 ACME/certificate 所有权。仅说“复用现有 certificate”不足以替代 Nix 中的续期与引用来源。
>
> [STATUS:open]

证据：`hosts/acorn/modules/auth-mini.nix:13-58` 定义 `constx` gateway；`:197-215` 用整个集合生成 gateway instances 和 ACME hosts；`:268` 用同一集合生成 vhost。RFC `:57-62` 只描述移除 instance 和新增 `useACMEHost` vhost。移除后，磁盘上的旧证书或许会让一次切换暂时可用，但 Nix eval/activate 也可能无法解析 `useACMEHost`，且至少不再有明确的续期归属。

影响：透明 Nginx 的 TLS 前提没有可重算的声明式来源，D1 与生产切换不可验证。

最小修复：在 RFC 明确 `constx.0xc1.wang` 的唯一 certificate owner（保留在 auth-mini 的 Cloudflare DNS-01 host 清单，或迁移到 `constx.nix` 的等价声明），并将其与新 vhost 同次切换。D1 的证据应包含 Nix eval/渲染后的 vhost、ACME host 与不含 gateway `auth_request` 的配置。

### F2：managed TOML 的首次启动与安全补丁算法尚不可执行

> [REVIEW:blocking] 现有证据只说明 `constxd serve` 在启动时管理 runtime TOML；RFC 却把“缺文件时运行 `constxd doctor` 生成 config”作为 pre-start 前提，未给出该 target release 确有此非交互命令、其使用相同 HOME/XDG 环境且不会启动常驻服务的证据。即使该前提成立，按 section header 删除 `[auth]` 的规则也没有定义重复表、`[auth.*]`、`[[auth]]`、畸形 TOML 与验证失败时的行为，不能证明“不覆盖其它运行时配置”。
>
> [STATUS:open]

证据：`docs/research.md:16-20` 仅记录 `serve` 对 `/var/lib/constx/config/constx/constxd.toml` 的管理；RFC `:68-82` 引入未被证实的 `doctor` bootstrap 与 header-based patch；当前 service 只有 executable test 后执行 `serve`（`hosts/acorn/modules/constx.nix:17-46`）。

影响：首次切换可在 `ExecStartPre` 卡死；随后每次重启都可能因文本匹配遗漏或误删而损坏私有 runtime config。这直接违背 plan 对幂等与保留非 auth 配置的验收。

最小修复：先把目标 release 的实际、非交互初始化命令及其干净目录试验列为 release 前置证据；为 `enable` 与 `disable` 都声明受支持的输入契约和拒绝策略（特别是重复、嵌套、数组与无效 auth 表），使用可验证的 TOML 校验路径，并预注册缺文件、无 auth、已有部署者拥有的 auth、异常输入、权限/owner、重复启动的正反例。只有这些场景都能证明 non-auth 内容未变，才可把 helper 放入 `ExecStartPre` 或 rollback。

### F3：新增顺序没有把目标 native release 置于 gateway 保护下的 active service

> [REVIEW:blocking] “在 Azar 复制新 closure 和 binary”后直接执行 helper、重启 `constxd`，并不会使已安装的 systemd unit 改用 closure 中的新 `releaseSha`。当前 unit 的 `ExecStart` 仍由当前 generation 决定。RFC 没有定义一个“保留 gateway ingress、但已把 active `constxd.service` 切到目标 native release”的中间 generation，也没有在切透明入口前验证真实未认证 user API 已由目标 binary 返回 401。
>
> [STATUS:open]

证据：`hosts/acorn/modules/constx.nix:4-8,32-33` 显示 active binary 由当前 generation 的 `releaseSha` 和 `ExecStart` 决定；RFC `:87-90` 只复制 closure/binary 后便执行 helper/restart，且只确认 `/api/auth/config` enabled。

影响：`enabled` 是配置状态，不足以证明实际 middleware/audience verifier 已生效。若步骤 3 仍运行旧或错配 binary，步骤 4 会在 D1 的外部 401 检查之前公开透明 ingress，正是新增排序要避免的 transient open window。

最小修复：定义三个明确状态：G0 为现有 gateway generation；G1 为保留 gateway ingress、但 active unit 已指向目标 release 且启用 auth 的 staging generation；G2 才移除 gateway 并启用透明 vhost。G1 必须在 loopback 对真实 user API 验证未认证请求为 401（以及必要的认证正向路径）后，才允许进入 G2。与此同时预注册不含秘密的 release manifest：merge commit、目标 `system`、binary SHA-256、Azar release directory、`releaseSha` 与 G1/G2 的对应关系，并记录 Axiom-only build、Azar hash 校验和 activate 证据。

### F4：Run Environment 的 D3 未覆盖任务契约中的完整机器路径

> [REVIEW:blocking] 旧 gateway 明确为 `pair`、`connect`、`heartbeats` 与 `tool-results` 四个路径绕过网页登录。RFC 选择由单一透明 `/` location 交给 constxd 是合理方向，但 D3 只要求既有 environment Available 与 `connect/heartbeat`，没有预注册一次成功的配对和一次实际 Tool Result 回传的端到端信号。后两者可能在 URL、方法、请求体或机器 credential 分流上独立失败，不能由 connection/heartbeat 代替。
>
> [STATUS:open]

证据：`hosts/acorn/modules/auth-mini.nix:127-137` 列出四条现有 bypass；`plan.md:14-18,55-57` 把四条机器路径列为验收；RFC `:62-64,98-101` 取消 special locations，但 D3 的正向证据只写 Available、connect 与 heartbeat。

影响：D3 目前无法证明 Run Environment 在 gateway 移除后仍可完成真实工作，故核心验收不可验证。

最小修复：将 D3 改为不记录 token 的端到端矩阵：受控的新配对完成并出现新 environment；既有 environment 的 connect 与持续 heartbeat；发起一次受控 tool call 且 control plane 收到对应 tool-result；各路径缺失/过期的正确机器凭据被拒绝，且用户 JWT 不能替代机器凭据。还应验证渲染后的单一透明 vhost 保留 Authorization、流式设置和 22 MiB body 限制。

### F5：rollback 缺少 gateway 已实际接管的硬门

> [REVIEW:blocking] RFC 的回滚顺序先选回 gateway generation、后执行 `disable`，方向正确，但没有把“有效 Nginx 已不再透明代理且 `/` 正在执行 `auth_request`”设为 `disable` 的前置条件。generation 切换、gateway unit 启动、Nginx reload 与 service restart 的成功状态不能由“已选择 generation”替代；若切换失败或部分生效后仍继续执行 helper，原透明入口可能仍指向 auth-disabled constxd。
>
> [STATUS:open]

证据：RFC `:105-113` 在 restore generation 与 `disable` 之间没有配置生效/外部拒绝请求的 gate；RFC `:68-81` 又规定 service pre-start 默认运行 `enable`，因此若把含该 pre-start 的 staging generation 误作 rollback generation，`disable` 后的 restart 还可能重新启用 auth。

影响：名义上的“gateway first”不是一个可证实的安全状态，不能排除 rollback 时的 transient open window，也不能保证 `disable` 后会稳定停留在旧认证边界。

最小修复：定义唯一的 rollback target 和状态机：先停住会重跑 `enable` 的 service，切到已验证 gateway-protected recovery generation，确认有效 Nginx 配置含 `auth_request` 且无凭据外部请求不直达 constxd；只有该 gate 成功才执行 `disable`，确认 loopback disabled 后启动旧 release。任一 gate 失败必须停止，不得继续 disable 或宣布回滚完成。

## 非阻塞确认

- 以一个透明 `/` vhost 取代 gateway 及其 Run Environment 特例，符合“应用负责用户 JWT 与机器 token 分流”的目标；不应在修复时重新引入 Nginx `auth_request` 或路径 bypass。
- 新增的 enable-before-ingress 与 gateway-before-disable 次序是正确的安全方向；在 F3、F5 的 active-service 与有效-ingress gate 补齐后，才可作为消除 transient open window 的证据。
- D4 把真实浏览器登录保留为 production gate 的方向正确。它不能抵消以上五项设计缺口，并且在 D4 实际通过前不得宣称完整生产验收。

## 会话注意力摘要

- 阶段：review-rfc
- 阶段结论：FAIL
- 注意力等级：review
- 判断变化：作者新增“enable 后再透明 ingress、gateway 后再 disable”的顺序，名义上缩小了公开窗口；但 active unit 未被切至目标 release、切换前未测实际 401、rollback 未验证 gateway 已接管，故 transient open window 仍未被证实消除，不能进入 engineer。
- 关键发现：
  1. 移除 `gatewayInstances.constx` 同时移除现有 ACME host 派生来源，而透明 vhost 未给出替代 owner。
  2. helper enable 不能证明 active `constxd` 是目标 native release，且透明 ingress 前缺真实未认证 401 gate。
  3. rollback 的 gateway-protected gate、TOML disable 语义与完整 Run Environment machine-path 验收均未形成可执行、可重算闭环。
- 阻塞项：F1、F2、F3、F4、F5 均为 blocking；修订 RFC 后须重新执行 review-rfc。
- 残余风险：D4 仍是必须由真实浏览器完成的 production 验收门；在其完成前禁止完整上线声明。
- 人类动作：复核 RFC 作者补入 G0/G1/G2 与唯一 rollback target、两侧有效 ingress gate、以及其余 blocking 修复；停止点为修订版 RFC 重新通过 review-rfc。
- 自动下一步：回到 spec-rfc 补齐状态机、验证矩阵与其余设计缺口，随后重新提交 review-rfc；不得进入 engineer、merge 或 production rollout。
- 完整证据：
  - `.legion/tasks/constx-azar-native-auth-mini/plan.md:12-36,51-57`
  - `.legion/tasks/constx-azar-native-auth-mini/docs/research.md:3-20`
  - `.legion/tasks/constx-azar-native-auth-mini/docs/rfc.md:45-123`
  - `hosts/acorn/modules/auth-mini.nix:13-58,127-149,197-215,254-276`
  - `hosts/acorn/modules/constx.nix:4-46`

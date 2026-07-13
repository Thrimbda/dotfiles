# RFC: RustDesk 自托管远程访问（Axiom runtime fixed-forward amendment）

> **Profile**: RFC Heavy / High Risk
> **Status**: Round 9 `review-rfc` PASS; implementation, verification and `review-change` PASS for the Axiom-only hotfix PR; candidate runtime remains pending
> **Audience**: 技术负责人和实施/评审人员
> **Design source of truth**: 本文件
> **Updated**: 2026-07-12

## Executive Summary

- **Decision**：acorn 运行 `rustdesk-server` 1.1.14；axiom 在当前 nixpkgs derivation 上仅 override `version/src/cargoHash`，source-build RustDesk 1.4.9；charlie 使用官方签名的 1.4.9 ARM64 DMG。
- **Security floor**：CVE-2026-57850 影响 1.4.9 之前的 client；1.4.8 不得用于部署、fallback 或 safe-generation rollback。
- **Trust material**：RustDesk server key 与 SSH key 分离；server private key、axiom password、charlie password 是三个独立 agenix secret，两台 client 的密码不同。
- **Provisioning**：两台 client 用短小、有限时的 oneshot 从 runtime secret 读取密码并调用上游 `--password`。不维护 `--password-file` patch，不构建 crash attestation 或 synthetic crash framework。
- **Accepted boundary**：axiom 与 charlie 是 single-owner trusted endpoints。用户接受设置密码时短暂出现在 argv，以及恰在该窗口崩溃时可能写入非核心 crash metadata 的低概率残余。
- **Normal-path invariant**：明文不得进入 Git、Nix store、derivation/unit/plist、常规日志或 PR；helper 禁止 trace，RustDesk stdout/stderr 不写 journal，匹配 stamp 时不重放。
- **Exposure**：仅开放 TCP 21115-21117 和 UDP 21116；Acorn DNS 与 Aliyun security group 已完成且不由 hotfix 改动。
- **Runtime hotfix**：仅在 Axiom 增加 canonical hostname 到 Acorn 公网 IP 的 host-local 解析、已证明的静态 session/display/DBus coordinates，以及 `${pkgs.pipewire}/lib/gstreamer-1.0`；root storage namespace保持`HOME=/root`、`XDG_CONFIG_HOME=/root/.config`，Charlie不继承这些Linux/Clash-specific设置。
- **Current rollout**：配置 PR #139 已 merge 为 `0026eb9922c87e9624ed7352b09b58cddb1a45a3`；Acorn、DNS 与 SG 已完成；Axiom 已停止并阻塞在 invalid ready state；Charlie 尚未部署。
- **State safety**：hotfix 必须改变 Axiom composite revision，但保留现有合法 revision prefix，使旧 reservation 成为 stale 并获得一次新的自动 password attempt。旧 revision 不得 resume、finalize 或通过 generation rollback 激活。
- **Rollback**：当前 Axiom 只能保持 RustDesk stopped 并 fixed-forward；始终保留 SSH、reverse SSH 和 ToDesk。部署证据仍通过 follow-up evidence PR 收口。

## 1. Context and Evidence

证据摘要见 [`research.md`](./research.md)。当前设计依赖以下事实：

1. NixOS 的 RustDesk server module 可运行 1.1.14，但默认 firewall 范围过宽、key 缺失会触发上游自动生成，因此必须显式最小化端口并做 fail-closed preflight。
2. 当前 flake 的 `pkgs.unstable.rustdesk` 仍为 1.4.8，但 RustDesk 1.4.9 已于 2026-07-06 发布并合入 PR #15469 的 session-scope authorization 修复。CVE-2026-57850 明确影响 1.4.9 之前版本，因此不能继续部署 1.4.8。
3. 1.4.9 保留 Linux/macOS service-scoped IPC hardening 与 argv-only `--password <value>` 管理入口；实现阶段必须从实际 fetched source 重新确认 `--config`、`--option`、`--password`、`Done!` 和 per-user IPC/PID 语义。
4. nixpkgs 的 RustDesk client 不支持 Darwin。Charlie 必须使用官方 DMG，且上游管理 CLI 和 launchd jobs 依赖固定的 `/Applications/RustDesk.app`。
5. `LimitCORE=0`/launchd `Core=0` 可降低传统 memory core 风险，但不能保证 systemd metadata 或 Apple crash metadata 不记录 argv；本设计不作超出该能力的声明。
6. 在 merged commit `0026eb9922c87e9624ed7352b09b58cddb1a45a3`、RustDesk 1.4.9、Axiom ID 11841215 上，Acorn/DNS/SG 均健康；Axiom 的 correct-password 连接最初由本地 runtime integration 关闭，不是 server 或 password persistence 失败。
7. Root `--service`启动的c1 `--server`继承了merged设计要求的`HOME=/root`、`XDG_CONFIG_HOME=/root/.config`，但缺少display/Wayland/runtime-dir/session-bus coordinates。Runtime drop-in在direct-host mapping之前同时改了HOME/XDG与session variables，因此它不能独立证明HOME/XDG需要改变；本amendment只采纳已证明的static session coordinates。
8. Clash fake-IP 把 canonical host 解析到 `198.18.0.69`，导致 UDP 21116 可达但 TCP 21115 失败；可逆 `/etc/hosts` 映射到 `8.159.128.125` 后 UDP/TCP NAT test 与认证均成功。RustDesk public config 始终保持 canonical hostname。
9. Portal 已成功返回 PipeWire stream/node 与 3840x2160 metadata，但 capture 先报 `Failed to create capturer for display 0`，server log 再报 `Failed scrap Failed to create element from factory name`。1.4.9 创建 `pipewiresrc -> videoconvert -> appsink`；nixpkgs wrapper 只有 GStreamer core/base plugin path，缺少 PipeWire plugin。把 PipeWire plugin directory 加入 service environment 后，同一测试完成画面与键鼠控制。
10. Root/c1的password/salt-derived fields与public fields一致，且未输出任何值；这支持现有upstream service IPC/config sync路径，不支持共享storage namespace。Portal restart也未修复capture。独立证明的三个修复是direct canonical resolution、spawned c1 server继承static session coordinates，以及PipeWire GStreamer plugin path。

## 2. Goals and Non-goals

### Goals

- 在 acorn 提供使用独立身份密钥的 hbbs/hbbr，并将公网暴露限制到 native client 必需端口。
- 在 axiom 与 charlie 安装 1.4.9 client，固定 ID server、公钥和关闭自动更新，并启用上游等价系统服务。
- 自动设置逐机不同的高熵永久密码，同时保证正常路径不把明文写入 Git、Nix store 或常规日志。
- 让配置发布、生产部署、验证和回滚均有明确顺序与 stop condition。
- 以 Axiom-only fixed-forward revision 恢复当前可信 c1 Hyprland session 的画面与输入控制，同时保持既有一次-per-revision/manual-finalize 状态机。

### Non-goals

- RustDesk Pro、Web client、Docker、WebSocket 公网端口或移除现有回退通道。
- 自维护 password-file patch、修改 RustDesk 协议/密码存储、建立共享跨平台 RustDesk framework。
- 全局 core handler、全局关闭 crash reporting、exact-OS crash attestation 或 synthetic crash test suite。
- 承诺 macOS FileVault preboot、睡眠唤醒、Wayland 登录屏或锁屏场景必然可控。
- 对同机 root/admin 或 single-owner 可信进程隐藏 RustDesk 的运行时密码状态。
- 把RustDesk server设置改成裸IP、给Charlie应用Linux session/Clash设置、把未经生产验证的Clash policy作为必需修复，或迁移/合并root与c1 RustDesk storage namespace。

## 3. Decision

### 3.1 Shared contract

| Item | Decision |
|---|---|
| Canonical server | `rustdesk.0xc1.wang` |
| Server version | `rustdesk-server` 1.1.14 |
| Client version | 1.4.9 on both clients；1.4.8 prohibited |
| Client public config | canonical host、匹配 public key、permanent-password approval、auto-update off |
| Server ingress | TCP 21115-21117；UDP 21116；21114/21118/21119 不开放 |
| Client ingress | 不新增 client firewall ingress |
| Secret source | host-local agenix runtime path |
| Deployment source | clean commit，已 merge 且与 `origin/master` 对齐 |

公共 DNS 仍是 canonical 配置且已经健康。Axiom 额外使用 NixOS declarative host resolution 绕过本机 Clash fake-IP；这不是第二套 RustDesk server 配置。Charlie 继续使用公共 DNS，不增加 Axiom-specific mapping。

### 3.2 Acorn server

- 使用 NixOS `services.rustdesk-server`，assert package version 为 1.1.14；不引入 Docker 或自建 server module。
- 生成独立 RustDesk keypair。private key 仅以 `rustdesk-server-key.age` 入库，runtime target 为 `/var/lib/rustdesk/id_ed25519`；public key 可提交并供两台 client pin。
- hbbs 与 hbbr 都使用 `-k _`，从同一 key material 派生/校验 public key。
- 两个 unit 在启动前以 service identity 检查 private/public key 可读且非空。任何检查失败都拒绝启动，不允许上游自动生成替代 key。
- `openFirewall = false`；在 acorn 现有 firewall 列表中显式加入 TCP 21115-21117、UDP 21116，Aliyun SG 使用相同 allowlist。
- 两个 unit 使用 `Restart=on-failure` 和短 `RestartSec`。可保留 per-unit `LimitCORE=0` 作为低成本 hardening；不改全局 `core_pattern`，不做 crash attestation，也不声称它消除 metadata。

### 3.3 Axiom client

- 以当前 `pkgs.unstable.rustdesk` derivation 为集成基线，override `version = "1.4.9"`、带 submodules 的 tag source、`cargoHash`，并显式以同一 source 重建 `cargoDeps` vendor derivation。保留 nixpkgs 原有 reproducibility patch、postPatch、依赖、wrapper 和 service shape；不追加 task-owned RustDesk 功能 patch。
- Immutable identity：tag commit `6c578292e8ebbbec708b76986ba8c4bc7c509747`；唯一 submodule `libs/hbb_common` commit `7e1c392c62d39c364127307cd408421dd5f8cfb0`；source SRI `sha256-AnwdIO4TveC48uMioBCvH60xun24ckK420ONSEB9lQI=`；cargo vendor SRI `sha256-HPvvsTcjSErGfdNwsHgWhs930Fe0hmK1g5J/ngtlkKM=`。
- Effective `cargoDeps` 必须引用 1.4.9 source，而非保留 1.4.8 vendor derivation。Patch application、CLI/IPC call sites 与完整 Axiom build 都是 pre-merge stop conditions。
- host-local systemd service 对齐上游 `rustdesk --service` 形状，并提供其运行所需的确定性 PATH。公开 host/key/options 在 service/provision 前写入并仅反查白名单字段。
- `rustdesk-provision.service` 对 main service **只能**声明 `Wants=` + `After=`。禁止 `Requires=`、`PartOf=`、`BindsTo=` 或 main service 到 provision 的反向依赖。
- Provision helper有限等待main service、MainPID、c1 RustDesk PID/socket与service IPC；这些local gates未通过时失败且不读取密码，但“readiness”不包含任何Hyprland/portal/PipeWire资源。
- 匹配 revision/stamp 时直接成功，避免每次 boot 重放。需要设置时，helper最多执行一次有timeout的上游`--password`调用；ACK后显式restart main service并复核公开配置，但不自动写success stamp。Stamp只能在外部完成新密码正测与旧密码负测后，由无secret的显式finalize命令提交。
- Main service保留upstream等价`ExecStop`以终止`--server`/tray；restart后root service与user server PID都必须更换并稳定，否则保持pending reservation且不允许finalize。
- Helper 不启用自动无限 restart。与 Charlie 相同，它在 password 前持久化 per-revision attempt reservation；失败、service restart或后续 reboot 都不得自动再次调用 password。Operator 只能按下文 reset procedure 显式清除 reservation 后重试。
- 可对 config/main/provision units 设置 `LimitCORE=0`；它只降低 memory core 风险，不是 argv 或 crash metadata 保密证明。

#### 3.3.1 Axiom runtime integration amendment

- 在Axiom声明`networking.hosts.${acornPublicIp} = [ rustdeskHost ];`，effective mapping必须是`8.159.128.125 -> rustdesk.0xc1.wang`。RustDesk public host/relay继续使用`rustdesk.0xc1.wang`；不改为IP，不增加Clash rule，现有destination-IP direct-route unit保持不变。
- **Storage invariant**：root `rustdesk --service`与password CLI继续使用merged canonical namespace：`HOME=/root`、`XDG_CONFIG_HOME=/root/.config`。Hotfix不声明`XDG_DATA_HOME`，不迁移、复制、删除或chown任何root/c1 RustDesk config/state，也不允许root activation/service/provision新增对`/home/c1` config/state的写入。
- Mutable RustDesk service state以现有root config namespace为canonical runtime state，metadata保持`root:root`。Declarative host/key/options仍以Nix配置为desired state并通过live service IPC证明；c1 `--server`继续使用upstream service IPC/config sync获取配置。既有c1 diagnostic/local config不是canonical source，hotfix既不信任它作为部署输入，也不自动删除、迁移或改属主。
- 定义单一`rustdeskServiceEnvironment` attrset，供`rustdesk.service.environment`与composite revision共用。其exact显式值为：

  | Variable | Effective unit value |
  |---|---|
  | `HOME` | `/root` |
  | `XDG_CONFIG_HOME` | `/root/.config` |
  | `DISPLAY` | `:0` |
  | `WAYLAND_DISPLAY` | `wayland-1` |
  | `XDG_RUNTIME_DIR` | `/run/user/1000` |
  | `DBUS_SESSION_BUS_ADDRESS` | `unix:path=/run/user/1000/bus` |
  | `XDG_CURRENT_DESKTOP` | `Hyprland` |
  | `XDG_SESSION_TYPE` | `wayland` |
  | `GST_PLUGIN_SYSTEM_PATH_1_0` | `${pkgs.pipewire}/lib/gstreamer-1.0` |
  | `PIPEWIRE_LATENCY` | `1024/48000` |
  | `PULSE_LATENCY_MSEC` | `60` |

- `XDG_DATA_HOME`保持undeclared；由`systemd.services.rustdesk.path`生成的`PATH`保持merged配置不变。UID从`config.users.users.${userName}.uid`派生并assert为`1000`，但不再从c1 home派生root HOME/XDG。`:0`与`wayland-1`是当前Axiom session coordinates；漂移时必须重新review，不做动态猜测。
- RustDesk wrapper继续prefix已有GStreamer core/base directories；unit只补immutable PipeWire directory。不得使用`/run/current-system/sw/lib/gstreamer-1.0`，也不得手工复制wrapper store paths。最终root service与spawned c1 `--server`的effective plugin path必须同时含core/base与`${pkgs.pipewire}`directory。
- **Readiness boundary**：现有pre-secret gate只证明root main PID、UID c1的RustDesk `--server` PID/socket、service IPC与approved public config；它不证明Hyprland、`/run/user/1000/wayland-1`、user bus、portal、PipeWire stream、capture或input ready。Static coordinates进入unit/revision，但所有图形资源均是new ready发布后的external acceptance gates。若任一资源缺失，该fresh revision已消耗；唯一动作是停止RustDesk并再次fixed-forward，不能声称no-login zero-reservation，也不能reset/finalize/rollback该revision。
- 保留root service的`multi-user.target` topology与`After=systemd-user-sessions.service`；该ordering不构成图形session readiness。Hotfix不增加session-discovery framework、pre-reservation portal probe或login-screen支持。
- Composite hash input新增exact `runtime-contract=axiom-rustdesk-runtime-v1`、`resolver=${rustdeskHost}:${acornPublicIp}`与`service-environment=${builtins.toJSON rustdeskServiceEnvironment}`；该JSON包含上表全部且仅这些显式unit values，因而把root storage invariant、session coordinates与immutable plugin path一起绑定revision。**不得改变`axiom-rustdesk-provision-v4:` prefix**：旧合法reservation必须成为stale而非malformed，新revision按既有状态表只获得一次新的自动password attempt。
- `0026eb99`已发布的reservation/ready不得直接finalize或resume；临时restart已使ready process identity无效。Hotfix merge/switch前RustDesk保持stopped。新revision正常替换stale reservation、移除stale ready，并在新的ACK/restart/process/public-IPC proof后发布fresh ready。
- 本amendment的production diff限于Axiom host configuration；Acorn server与Charlie config不变。Axiom mapping与Acorn public-IP rotation显式耦合：IP变化时必须同步更新DNS、mapping/revision并重新走fixed-forward runtime gates。

### 3.4 Charlie client

- 使用官方 release 1.4.9 的 `rustdesk-1.4.9-aarch64.dmg`：
  - GitHub digest：`sha256:f7935597b247d42c8f2a2ed71176a9f5868018cd9e1a33b8096418a668c8caf0`
  - Nix SRI：`sha256-95NVl7JH1CyPKi7XEXap9YaAGM2eGjO4CWQYpmjIyvA=`
- Host-local fixed-output derivation 只解包/复制 bundle，禁用会改写 bundle 的 fixup/strip；不修改 binary/Info.plist，不 ad-hoc re-sign。
- 安装位置固定为 `/Applications/RustDesk.app`。未知来源的同名 app 不静默覆盖；store bundle 和最终 destination 都必须在 Charlie 上通过 `codesign --verify --deep --strict` 与 `spctl` 后才能加载 jobs。还必须确认 bundle id `com.carriez.rustdesk`、TeamIdentifier `HZF9JMC8YN`，以及 Gatekeeper origin `Developer ID Application: zhou huabing (HZF9JMC8YN)`；任一 identity 漂移即停止，不 ad-hoc re-sign。
- 保留上游 topology：`com.carriez.RustDesk_service` LaunchDaemon 和 `com.carriez.RustDesk_server` LaunchAgent；server agent 覆盖 `LoginWindow` 与 `Aqua`。关闭 app auto-update。
- 增加一个小型 root provision LaunchDaemon。它 `RunAtLoad`，并以保守 `StartInterval=300` 仅重试 app/service/IPC/readiness；readiness 失败不读取密码。
- 对同一revision，实际password invocation只允许一次自动尝试。调用前持久化attempt reservation；失败或ACK后都不再由interval自动重试。ACK、restart和public proof只产生pending verification状态；operator完成外部密码正/负测后才可运行finalize写success stamp。
- `launchctl print` 只用于读取顶层 job fields；parser 必须按 brace depth 排除 resource/jetsam coalition 等嵌套 `state`，并通过来自目标系统的完整 fixture。后续 root UID、executable、command 和 stable-PID 校验仍必须保留。
- Attempt reservation 对任何非预期对象 fail closed；canonical path 必须是非 symlink 的 root:wheel `0600` regular file，并在 password CLI 前 byte-equal 当前 revision。Atomic publish 后立即复核同一条件。
- service/server/provision jobs 可设 soft/hard `Core=0`；这不控制 Apple `ReportCrash`，也不替代本 RFC 的 accepted residual。
- Screen Recording、Accessibility、Input Monitoring 由用户对固定签名 app 人工授权；Nix 不宣称绕过 TCC。

### 3.5 Minimal provisioning contract

两台 client 使用同一结果合同，平台只在 supervisor/readiness 上不同：

1. Secret 是各 host 独立的 root-only agenix runtime file；建议为单行 32-64 字符 base64url。格式、权限或可读性不满足时 fail closed。
2. Public config 先写入并通过 active-user IPC 反查；password 只在 main process 与 IPC ready 后读取。每次 apply/query 都使用彼此不同、root-owned、刚创建且为空的临时 `HOME`/`XDG_CONFIG_HOME`，调用后删除。Query 必须从自己的新空 fallback context返回预期的非默认 host/key/relay；若IPC不可达，caller-local fallback只能返回空/default并使exact helper失败。PID/socket检查必须包围query。测试拓扑分两步：raw CLI在同一context预置expected values后证明fallback确实可假阳性；exact helper必须改用另一新空context，在IPC阻断时失败且不得读取secret或发布reservation。
3. Helper 禁止 `set -x`，不把 password 放入 Nix 字符串、unit/plist、environment 或日志。调用窗口内不采集 process inventory。
4. Helper 从 runtime file 读入最短生命周期变量，调用官方 `rustdesk --password "$password"`，随后立即 unset。子进程 argv 的短暂明文是明确接受的边界。
5. 调用有硬 timeout；stdout/stderr 进入 root-only runtime temporary output 或 `/dev/null`，不进入 journal/launchd log。若使用 temporary output，只匹配上游成功结果并立即删除，绝不转录内容。
6. `Done!`只证明daemon ACK，不证明配置持久化成功。ACK后restart并复核process/public config，保留current reservation且不写stamp。Stamp由package/public-config/provision/secret-ciphertext revision驱动，不保存plaintext。
7. Provision仅在ACK、全部auth-serving process完成restart/replacement、public proof与PID稳定性检查后，原子发布非秘密`ready-to-finalize`记录。该记录绑定host、revision以及post-restart process PID/start identity；任何前置失败都不得发布。
8. 从另一台设备完成新密码成功、旧/错误/另一台密码失败后，operator运行`rustdesk-provision-finalize --confirm-remote-auth`。Finalizer不读取secret，只接受current valid reservation、current ready记录、相同运行中process identity和显式confirmation，然后原子写current stamp并sync。没有外部正/负测不得finalize。

### 3.6 Attempt/stamp state machine

两台 client 对每个 composite revision 最多自动调用一次 password。状态在任何 readiness或secret读取前按下表判定：

| Stamp | Reservation | Action |
|---|---|---|
| current、metadata合法 | 任意 | Fast-skip；不要求图形session，不调用管理 CLI，不读取secret |
| malformed object/metadata | 任意 | Fail closed；operator修复，不自动删除 |
| absent或合法stale | malformed object/metadata | Fail closed；不读取secret |
| absent或合法stale | current、metadata合法 | Pending external verification或failed attempt；跨service restart/reboot保持，不再调用password。只有current ready记录存在且process identity仍匹配时才允许finalize；否则只能fixed-forward到新revision或显式reset |
| absent或合法stale | absent | Readiness通过后原子发布current reservation、sync并复核，再读取secret和调用password |
| absent或合法stale | stale、metadata合法 | 新revision获得一次attempt；readiness通过后原子替换为current reservation、sync并复核，再读取secret和调用password |

状态表按行优先：current且metadata合法的stamp直接fast-skip，不检查reservation；仅在没有current valid stamp时才检查reservation。此后canonical stamp/reservation/ready都必须是非symlink regular file：Axiom `root:root 0600`，Charlie `root:wheel 0600`。Stamp/reservation内容必须byte-equal对应revision；ready必须严格绑定同一revision和post-restart process identities。Unexpected directory/device/FIFO、owner/mode错误、truncated或额外内容都fail closed。Reservation publish后、secret读取前及password调用前再次复核canonical path；publish或复核失败不得调用password。

Provision与finalizer使用同一root-owned operation lock；无法获取锁时fail closed，stale lock只由operator在确认无相关进程后处理。Password ACK、全部auth-serving process restart/replacement和public config IPC proof通过后，provision发布ready记录并成功退出，但保留current reservation且不写stamp。外部remote-auth正/负测通过后，operator以显式confirmation参数运行finalizer；finalizer在锁内重验reservation、ready和process identity后提交stamp，且不读取secret。失败、中断或未验证状态保留reservation；未达到全部local gates时不得存在ready。

Operator reset procedure：先stop/disable provision job，获取同一operation lock，确认helper/password CLI/finalizer均未运行，删除canonical reservation与ready并sync，复核state目录/stamp metadata，再显式start provision；不得由interval、boot或通配清理自动reset。用户选择简化single-owner边界，不增加自动历史账本：一旦新revision已发布reservation，任何旧generation即使client版本仍为1.4.9也不再是安全rollback target；失败时保持RustDesk停止并fixed-forward到全新revision。

该generic reset只保留为既有平台合同；对当前Axiom old state以及本hotfix任何已发布reservation后的post-ready graphical/storage failure，本文明确禁用reset，唯一恢复路径是stop + fresh fixed-forward revision。

Reservation publish后在password前执行平台可用的filesystem sync。该设计覆盖正常process crash、service restart与orderly reboot；突然掉电、storage/controller故障仍不是绝对exactly-once保证，发生不确定状态时保持provision停止并轮换到新revision，不假定旧调用未发生。

## 4. Options Considered

### Option A — Upstream 1.4.9 + bounded argv oneshot（选择）

- **优点**：代码最少；Linux/macOS 使用同一官方 CLI；保留 binary cache 与 macOS 官方签名；升级时无需 rebase 私有 patch。
- **代价**：single-owner endpoint 上存在短暂 argv；极低概率 crash metadata 残余需明确接受。

### Option B — 自维护 `--password-file` source patch

- **优点**：managed argv 不含密码。
- **缺点**：Axiom 失去简单上游包路径，产生持续 source review/build/test 负担；Charlie 不能应用而不破坏官方签名，最终仍是两套安全模型。
- **结论**：不选；删除现有 patch 与专用测试。

### Option C — 完全人工 GUI/CLI 设置密码

- **优点**：无需自动读取 secret。
- **缺点**：不可重复、轮换依赖人工、无法由 agenix revision 驱动，三机部署更易漂移。
- **结论**：不选；TCC 仍保留人工步骤，但 password provisioning 自动化。

### Option D — 全局 core handler、exact-OS attestation 或大型事务 harness

- **优点**：可追求更强的 crash artifact 断言。
- **缺点**：影响全机诊断，OS 绑定强，代码和验证面远大于个人可信 endpoint 的实际风险；容易产生无法长期维护的虚假保证。
- **结论**：不选。只保留 per-unit resource limit 与诚实的 residual 声明。

### Option E — 共享跨平台模块

- **优点**：表面减少重复。
- **缺点**：NixOS package/systemd 与 DMG/launchd/TCC 的生命周期不同；两台 client 不足以抵消抽象成本。
- **结论**：不选；使用 host-local config。

### Option F — Axiom declarative host resolution（选择）

- **优点**：与已成功的 `/etc/hosts` runtime test 等价；只影响 Axiom NSS；RustDesk public config 继续使用 canonical hostname；改动小且可由 Nix eval 审查。
- **代价**：显式耦合 Acorn public IP rotation，且它绕过的是 Axiom resolver，不是通用 Clash policy。
- **放弃**：把 RustDesk host/relay 改成裸 IP 会产生第二套 server identity；新增 Clash rule 尚无生产证据且扩大配置面，均不选。

### Option G — Preserve root storage + static session coordinates + immutable plugin（选择）

- **优点**：保持merged root config/password namespace与upstream service IPC sync，不产生migration或root-to-user path trust；只加入已证明的session coordinates与`${pkgs.pipewire}`，可由eval、closure与runtime gates验证。
- **代价**：pre-secret PID/socket/IPC gate不证明图形资源；`:0`/`wayland-1`漂移或post-ready graphical gate失败会消耗revision并要求再次fixed-forward，不支持login screen。
- **放弃**：Runtime experiment把c1 HOME/XDG与session variables一起改变，不能证明storage relocation必要；让root使用c1 namespace会引入ownership/confused-deputy/migration问题。`/run/current-system/sw`与动态user-manager environment discovery也分别因mutable coupling与额外竞态而不选。

## 5. Secret Lifecycle

### Creation and storage

- Server keypair 独立生成，不复用 OpenSSH key。只提交 age ciphertext 和 public key。
- Axiom、Charlie 各生成一个不同的高熵 password，分别写入各自 `.age` payload；不复制、不从同一低熵口令派生。
- PR、日志和 evidence 只记录 recipient mapping、owner/mode 与 PASS/FAIL，不记录 secret、secret digest 或可还原输出。

### Runtime use and rotation

- Agenix 解密到 runtime path；derivation 和 supervisor 配置只包含该 path。
- Nix/agenix是declarative desired config与secret distribution的source；RustDesk root namespace是当前mutable canonical service state，c1 local config只是upstream IPC sync产生的非canonical replica/diagnostic state，均不进入Git。
- 单 client 轮换只更新该 host ciphertext/revision，merge 后 switch 并重放一次 provision；从另一台 client 做新密码正测和旧密码负测。
- Server key rotation 没有双 key grace：保留旧 key，安排维护窗口，同步切换 server 与两台 client；任一 client 失败则关闭 ingress 并整体回旧 key。

### Revocation and disposal

- 删除 `.age` 文件不会自动清除 RustDesk derived password。Decommission 时先停止自动 provision；可安全调用现有 CLI 时清空/替换 password，否则保持服务停止并删除相应 mutable RustDesk config。
- 怀疑 password 泄露时只轮换对应 client；怀疑 server private key 泄露时轮换 server key 和全部 client public-key pin。

## 6. Deployment

### Phase 1 — Configuration PR #139（completed）

- 配置 PR #139 已 merge 为 `0026eb9922c87e9624ed7352b09b58cddb1a45a3`；此前 Round 7 RFC/configuration review 与三端 pre-deployment build evidence 保留为历史证据。
- Acorn 已从该 clean merged commit switch；hbbs/hbbr、DNS、host firewall 与 Aliyun SG 已验证健康。
- Axiom 已从该 commit switch 并发布 current reservation + ready、无 stamp；后续 runtime diagnosis 使 ready process identity 漂移，因此该 ready 无效且不得 finalize。RustDesk 已停止，临时 drop-in、hosts override、scripts/log copies 均已清理。
- Charlie 尚未部署。

### Phase 2 — Axiom fixed-forward hotfix PR

- Production change仅修改`hosts/axiom/default.nix`：declarative host resolution、保留root HOME/XDG的exact service environment、immutable PipeWire plugin path，以及绑定这些值的composite revision input。不得增加storage migration/chown/delete逻辑，不得修改secret ciphertext、Acorn或Charlie production config。
- 运行第 8 节全部 pre-merge gates，重新执行 `review-rfc`、change review 与 required checks；旧 pre-deployment PASS 不覆盖新增 runtime contract。
- Hotfix 必须先 merge。任何 production switch 均从与 `origin/master` 对齐的 clean merged commit 执行，不从当前 worktree 或未 merge commit 执行。

### Phase 3 — Axiom fixed-forward runtime

1. Hotfix merge 前保持 RustDesk stopped。记录新 merged commit，确认它是 `0026eb99` 的后继且 Axiom composite revision 已变化。
2. 旧 reservation 必须被识别为合法 stale，旧 ready 必须被识别为 stale/invalid；不得运行旧 finalizer、不得直接删除状态来“续跑”、不得 generation rollback。
3. 从新clean merged commit switch Axiom。Existing pre-secret gate只需证明c1 RustDesk server PID/socket/IPC与public config；通过后provision替换stale reservation、消耗新revision唯一一次automatic password attempt，并发布绑定新revision和新process identities的ready，仍无stamp。
4. 严格按顺序通过：fresh reservation/ready → root/c1 storage metadata与exact process environment → canonical hostname direct resolution → actual Wayland socket/user bus/portal/PipeWire → correct-password screen capture与keyboard/mouse control → wrong-password negative test。
5. 任一post-ready graphical gate缺失、process identity漂移或ready失效时，该revision已经消耗；立即停止RustDesk，不finalize、不reset、不回滚generation，再次fixed-forward。若storage metadata发生非预期变化，同样停止且不得自动chown/delete，先保留metadata evidence再修订。
6. 全部 gate 通过且 identity 仍匹配时，operator 才运行 exact command：`sudo rustdesk-provision-finalize --confirm-remote-auth`。随后验证 current stamp 与 fast-skip，且没有第二次 password invocation。

Acorn 不因 Axiom-only hotfix 重做 switch；记录其已部署 commit与新 hotfix commit的父子关系，并证明 hotfix 没有改变 Acorn production config。后续 Axiom/Charlie switch 均使用新 clean merged hotfix baseline。

### Phase 4 — Charlie and evidence closeout

- 只有 Axiom 完成 manual finalize 后才能从同一 hotfix baseline 部署 Charlie。不得把 Axiom host mapping、Hyprland environment 或 PipeWire plugin fix复制到 Charlie。
- Charlie 继续执行既有 DMG hash、store/destination signature、launchd topology、password正/负测、manual finalize 与人工 TCC gates。
- 完成双向控制、跨机密码负测和 forced relay；lock/login/sleep/FileVault 结果分项记录，不扩大能力声明。
- 观察正常使用窗口并保留 SSH/reverse SSH/ToDesk；以独立 follow-up evidence PR 提交不含 secret 的 runtime PASS/FAIL。

## 7. Rollback

### Triggers

- key mismatch、secret 缺失却生成新 key、意外公网端口、异常 relay 流量或服务 crash-loop。
- package/app 不是 1.4.9、任何路径仍引用 1.4.8、Charlie 签名失败、public host/key/options 漂移。
- Axiom canonical host仍返回Clash fake-IP、exact root/session environment不匹配、PipeWire plugin/factory不可见、capture/input失败、process identity漂移，或provision/password正负测异常。
- Root canonical state不再`root:root`、c1 state被root rewrite/chown、generated artifact出现storage migration/delete，或任何验证需要打印secret-derived value。
- 日志出现明文，或 SSH/ToDesk 回退受损。

### Immediate containment

1. 对当前 Axiom-only runtime failure，先停止/disable provision 与 RustDesk，保留 SSH/ToDesk；Acorn 已健康，不因 client integration failure 自动关闭 SG。
2. 只有出现 server key/exposure问题、异常 relay 流量或全局服务风险时才关闭对应 Aliyun SG ingress；仅 relay 滥用可先关闭 21117。
3. Storage metadata异常时只保留approved metadata evidence并停止；不得自动chown、删除、迁移或用generation rollback掩盖side effect。若可能发生secret disclosure，按对应credential incident轮换；不要把可疑argv/crash artifact复制进PR。

### Per-host rollback

- **Acorn**：回滚到已知 generation，确认 hbbs/hbbr 与 host firewall 状态；SG/DNS 是外部状态，单独回退。Key rotation 必须 server 和两台 client 整体回旧。
- **Axiom**：首次password attempt前可回到预验证`>=1.4.9`或RustDesk absent/disabled target。一旦任何revision发布reservation，禁止回滚任何更早RustDesk generation，因为mutable password状态可能已改变；保持RustDesk disabled并fixed-forward到全新revision。不得执行generic generation rollback。退役时还需处理derived config并做旧密码负测。
- **Charlie**：首次password attempt前可恢复预验证`>=1.4.9`受管bundle或app/jobs均不存在状态。一旦任何新revision发布reservation，禁止恢复任何更早RustDesk bundle/generation，即使signer和marker有效；保持三个jobs unloaded、RustDesk disabled并fixed-forward到全新revision。不得用`darwin-rebuild --rollback`重新激活旧状态。TCC可保留，完全卸载时人工reset。

当前`0026eb99` Axiom reservation已使generation rollback永久失效；其ready又因process identity drift无法finalize。唯一允许的恢复路径是保持stopped，merge新runtime contract，以新composite revision替换stale state并重新完成全部runtime gates。因为hotfix保持root/c1 namespaces不变，正常fixed-forward不需要filesystem migration或cleanup；若观察到ownership/path side effect，则停止并单独调查，不能自动修复后继续。部分成功不是继续rollout的理由。

## 8. Verification

### Pre-merge static and build gates

此前#139的Acorn/Charlie artifact evidence与Axiom package/provision安全证据仍有效；Round 8 FAIL仅否决shared root/c1 storage与过宽readiness claim。Revised hotfix必须通过：

1. **Effective resolver**：Nix eval显示`networking.hosts`含且只新增`8.159.128.125 = [ "rustdesk.0xc1.wang" ]`；RustDesk effective host/relay仍为canonical hostname，Charlie无此mapping。
2. **Exact unit/password environment**：Nix eval与generated `rustdesk.service`逐项匹配3.3.1表格；root service与password CLI继续是`HOME=/root`、`XDG_CONFIG_HOME=/root/.config`，`XDG_DATA_HOME`未声明，existing generated `PATH`与latency values不漂移，不含`/run/current-system/sw`。
3. **No-migration/storage boundary**：production diff、generated unit/provision/finalizer与activation不得为root service/provision引用`/home/c1/.config/rustdesk`或其他c1 RustDesk config/state path，不得新增针对root/c1 RustDesk state的copy/move/delete/chown。Root main service identity仍为root，spawned server identity检查仍为UID c1；public-config temporary contexts保持独立root-owned scratch，不成为canonical storage。
4. **Clean/future-state structural gate**：generated/evaluated artifacts证明hotfix不预创建或迁移RustDesk config。若future root state absent，唯一writer仍是使用root HOME/XDG的upstream root service；若c1 local state absent，hotfix不替它创建，后续只允许upstream UID c1 process按既有sync行为创建。不得为测试删除、移动或改属主production profile中的任何root/c1 state。
5. **Immutable plugin dependency**：`${pkgs.pipewire}/lib/gstreamer-1.0/libgstpipewire.so`存在；generated unit直接引用该store path；fresh Axiom toplevel closure包含对应`pkgs.pipewire` output。
6. **Pipeline factories**：pinned RustDesk 1.4.9 source仍创建`pipewiresrc -> videoconvert -> appsink`；以wrapper core/base paths加`${pkgs.pipewire}/lib/gstreamer-1.0`运行`gst-inspect-1.0`，三个factory均解析。
7. **Fresh revision**：hotfix revision与`0026eb99` deployed revision不同，仍使用`axiom-rustdesk-provision-v4:`prefix；serialized exact service environment包含root HOME/XDG且不含c1 HOME/XDG。State tests证明旧reservation合法stale、旧ready在secret/password前删除、新revision仅一次attempt、旧state不能direct finalize。
8. **Narrow readiness contract**：generated helper与tests只把MainPID、c1 RustDesk PID/socket/service IPC及approved public-config proof视为pre-secret readiness；不得新增或声称Wayland/user-bus/portal/PipeWire pre-reservation guarantee，也不得声称no-login zero-reservation。Post-ready graphical failure必须映射为stop + another fixed-forward。
9. **Approved comparisons only**：public proof只静默比较既有approved host/relay/key/options与expected值，evidence仅记录PASS/FAIL；若比较root/c1 password/salt-derived fields，也只允许输出byte-equality PASS/FAIL。不得输出value、digest、public key或完整config；storage checks只读取path type/owner/group/mode等approved metadata。
10. **Regression/scope/build/review**：same-source 1.4.9/cargoDeps、IPC fallback负控、`Wants/After`-only topology、双PID replacement、ready identity、zero-secret finalizer与malformed-state checks继续通过；production diff限于`hosts/axiom/default.nix`，fresh完整Axiom toplevel build通过。随后必须fresh `review-rfc` PASS、implementation `review-change`与required checks通过才可merge。

No-migration design不引入新的filesystem transition，因此不通过破坏production profile来模拟clean start。Generated actor/environment/activation checks覆盖future absent-state writer与namespace；post-switch metadata preservation关闭warm-state regression。这一组合比删除真实state后重建更可信，也不触碰当前reservation/password状态。

### Post-merge Axiom runtime gates（ordered）

1. **Source/state precondition**：Axiom仍stopped；checkout是new clean merged `origin/master`；revision已变化。旧reservation/ready不得finalize、resume、reset或rollback。
2. **Pre-switch metadata snapshot**：仅记录已存在root canonical namespace与c1 diagnostic namespace的path type/owner/group/mode；root objects必须`root:root`，c1 objects若存在必须c1-owned。不读取内容，不打印secret/public-key/derived value，不删除或修复任何对象。
3. **Fresh state**：switch后出现new current reservation与new ready、无stamp；ready绑定fresh root service与c1 server PID/start identity，且只发生一次new-revision password attempt。Ready只表示local RustDesk process/IPC gates完成，不表示graphical readiness。
4. **Storage preservation**：post-switch root canonical config/state仍为`root:root`；existing c1 files仍c1-owned。Generated activation无rewrite/chown path，runtime不得出现root写入c1 config/state的证据。Approved public/derived comparison只输出PASS/FAIL。任一metadata异常都停止RustDesk、保留evidence且禁止自动chown/delete/finalize。
5. **Exact process environment**：只从root service与live c1 `--server`提取3.3.1白名单变量；两者保持`HOME=/root`、`XDG_CONFIG_HOME=/root/.config`并含static session coordinates。Effective `GST_PLUGIN_SYSTEM_PATH_1_0`同时含wrapper core/base和immutable `${pkgs.pipewire}`，不依赖`/run/current-system/sw`。
6. **Direct canonical resolution**：NSS把`rustdesk.0xc1.wang`直接解析为`8.159.128.125`，不返回`198.18.0.0/15`；public config仍为canonical hostname，RustDesk UDP 21116与TCP 21115 NAT tests均成功。
7. **Post-ready graphical resources**：在ready已发布后才验证actual `/run/user/1000/wayland-1`、c1 user bus、portal、PipeWire stream/node、三factory与capture/input path。任何缺失都表示该revision已消耗，只能stop + another fixed-forward。
8. **Positive/negative controls**：从另一设备以正确password完成portal screen选择、实际画面与keyboard/pointer control；同一fresh identity下错误password必须被拒绝，旧/跨机password负测继续只记录PASS/FAIL。
9. **Exact finalize**：重验process identity与storage metadata未漂移后，才运行`sudo rustdesk-provision-finalize --confirm-remote-auth`；确认current stamp、ready处理与后续fast-skip，且无第二次password invocation。
10. **Stop condition**：任一步失败即停止RustDesk；不得finalize、reset该revision或generation rollback。Graphical failure再次fixed-forward；storage anomaly先保留metadata evidence并修订，绝不自动迁移/清理。Axiom finalize成功前不得部署Charlie。

Acorn runtime、DNS与SG gates已在`0026eb99`完成；hotfix只确认其配置未变。Axiom验收只覆盖active c1 Hyprland session，不把login/lock/DPMS表现提升为支持承诺，也不运行真实-secret crash injection或destructive clean-state test。

## 9. Observability

- Acorn继续观察systemd active/restart、listen socket、registration/relay、CPU/memory/network egress和Aliyun费用；异常relay的第一动作是关21117。
- Axiom观察config/main/provision unit result、reservation/ready/stamp revision与process identity、root/c1 approved storage metadata、NSS direct resolution、RustDesk UDP/TCP NAT test、post-ready Wayland portal和GStreamer stage；Charlie观察launchd job、signature和TCC状态。
- Process environment只读取本文白名单变量；storage只读取path type/owner/group/mode。不得采集完整environment/process inventory、dump RustDesk config、输出password/salt-derived value或digest。
- Provision日志只能写stage/category/revision，不写command line、password、secret digest、完整RustDesk config或portal stream内容。
- 没有HTTP health endpoint时，以storage invariant + supervisor/process identity + direct resolver/NAT + post-ready actual screen/control组合判断Axiom健康；local ready、portal成功或password ACK任一单项都不足以判定PASS。

## 10. Accepted Residuals

以下风险由用户针对 single-owner endpoints 明确接受，不应在实现或评审中被重新包装成“已消除”：

1. Provision 调用期间，password 会短暂出现在 RustDesk 子进程 argv；同机 root 或足够权限的可信进程可能观察到。
2. 若 RustDesk 恰在该短窗口崩溃，systemd/Apple 可能保存包含 argv 的非核心 crash metadata。概率低但非零。
3. `LimitCORE=0`/`Core=0` 只降低传统 memory core 风险，不关闭 systemd metadata 或 Apple `ReportCrash`，也不构成 attestation。
4. Agenix 保护 source/runtime distribution，不防同机 root/admin；RustDesk derived config 与允许的本地 IPC 路径仍属于 endpoint 信任边界。
5. 1.4.9 的 service IPC peer-uid/executable hardening 和 session-scope authorization 缩小攻击面，但不提供 password-file CLI，也不取消上述 argv residual。
6. 公网 hbbs/hbbr 仍有扫描、DoS 和 relay 费用风险；最小 SG 与 egress 观察只能缓解。
7. macOS TCC/FileVault/sleep 与 Wayland portal/login screen 是平台边界，只能由真机结果界定。
8. Axiom `networking.hosts` 与 Acorn当前公网IP耦合；公网IP轮换若未同步更新mapping/revision会中断RustDesk，即使公共DNS已更新。
9. Axiom service environment保持root HOME/XDG，同时绑定当前single-user c1 session的`:0`、`wayland-1`和UID 1000。它依赖upstream root-to-user config sync，不把c1 local files提升为canonical state。
10. Existing pre-secret readiness不证明graphical session。Login/logout、lock、DPMS或portal缺失可能在ready发布后才暴露，并消耗该revision；此时只能stop并再次fixed-forward。

若设备改为 multi-owner、开始运行不可信本地代码，用户不再接受 argv/crash-metadata residual，或Axiom session topology改变，必须停用自动 provision并重新评估RFC；涉及已发布reservation时继续遵守fixed-forward规则。

## 11. Milestones and Implementation Boundary

### M1 — Configuration PR #139（complete）

- Scope：三端1.4.9配置、独立secrets、manual-finalize状态机与pre-deployment review/build。
- Acceptance：PR #139已merge为`0026eb9922c87e9624ed7352b09b58cddb1a45a3`。其PASS保留，但不覆盖后来发现的Axiom runtime integration。

### M2 — Partial production rollout（contained）

- Scope：Acorn、DNS、SG与Axiom首轮switch。
- Current result：Acorn完成；Axiom旧reservation/invalid ready、无stamp且RustDesk stopped；Charlie未部署。
- Safety boundary：旧Axiom revision不得resume/finalize/rollback。

### M2a — Axiom runtime hotfix PR

- Scope：Axiom declarative resolver、root-storage-preserving exact service environment、immutable PipeWire plugin path、fresh composite revision，以及对应文档/验证。
- Acceptance：fresh `review-rfc`、第8节pre-merge gates、fresh Axiom full build、change review和PR checks通过并merge；无production switch。

### M2b — Axiom fixed-forward acceptance

- Scope：从clean merged hotfix switch Axiom，执行ordered runtime gates与exact manual finalizer。
- Acceptance：root/c1 ownership与no-migration invariant、direct canonical resolution、exact process env、post-ready graphics、correct-password screen/input PASS、wrong-password FAIL、fresh identity finalize/fast-skip PASS；否则保持stopped并按failure class处理。

### M3 — Charlie rollout and evidence PR

- Scope：仅在M2b通过后部署Charlie，完成既有signature/TCC/auth gates，并提交非秘密runtime evidence、walkthrough和closeout。
- Acceptance：evidence分别追溯Acorn deployed commit与Axiom/Charlie hotfix commit，失败和residual如实记录。

Hotfix production implementation boundary只有：

- `hosts/axiom/default.nix`

Design/evidence仅更新本task的`docs/*.md`。不得修改Acorn/Charlie production files、任何`.age` ciphertext、`modules/**`、`packages/**`或新增RustDesk framework/test harness。

## 12. Remaining Gates and Review Readiness

### Design blockers

无。Round 8的shared-storage blocker已通过保留merged root namespace、定义ownership/source-of-truth与no-migration gates关闭；readiness claim已收窄。Round 9 `review-rfc`已PASS。

### Deployment/acceptance gates

- [x] 配置PR #139 merge为`0026eb99`；原pre-deployment review/build PASS保留为历史证据。
- [x] Acorn deployment、公共DNS、host firewall与Aliyun SG完成并健康。
- [x] Axiom当前失败已contained：旧reservation + invalid ready、无stamp，临时runtime改动已清理，RustDesk stopped。
- [x] Charlie尚未部署。
- [x] Round 8 FAIL作为历史保留；Round 9 `review-rfc`已PASS。
- [x] Effective `networking.hosts`、root-preserving exact unit/password environment、no-migration/storage tests、immutable PipeWire plugin closure、三factory、narrow-readiness与fresh revision state tests PASS。
- [x] Fresh Axiom full build与`review-change` PASS。
- [ ] Required checks PASS且Axiom-only hotfix PR merge。
- [ ] Axiom从clean merged hotfix完成fresh reservation/ready、root/c1 metadata preservation、exact process env、direct resolution、post-ready graphical gates、screen/input正测与wrong-password负测。
- [ ] Exact manual finalizer与后续fast-skip PASS。
- [ ] 仅在Axiom gate通过后部署Charlie并完成其既有signature/TCC/auth/finalize gates。
- [ ] Follow-up evidence PR收口。

## References

- Contract：`../plan.md`
- Evidence：[`research.md`](./research.md)
- Current review evidence：[`review-rfc.md`](./review-rfc.md) Round 9 PASS；Round 8 FAIL仅作历史保留
- RustDesk client source：tag 1.4.9，commit `6c578292e8ebbbec708b76986ba8c4bc7c509747`
- RustDesk server source：tag 1.1.14
- Official release：`https://github.com/rustdesk/rustdesk/releases/tag/1.4.9`
- Session-scope fix：`https://github.com/rustdesk/rustdesk/pull/15469`
- CVE：`https://www.cve.org/CVERecord?id=CVE-2026-57850`
- Official client configuration：`https://rustdesk.com/docs/en/self-host/client-configuration/`

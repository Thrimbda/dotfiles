# Research: RustDesk 自托管远程访问（Axiom runtime hotfix amendment）

> **Purpose**: 为当前 RFC 提供版本、平台与 Axiom production runtime blocker 的最短可追溯证据。
> **Contract source**: `../plan.md`
> **Checked**: 2026-07-12
> **Review state**: Round 9 `review-rfc` PASS; implementation/static verification/change review PASS，candidate runtime pending
> **Secret handling**: 未打开任何 `.age` payload，未读取未跟踪密码文件。

## 1. Current Conclusion

| Area | Current evidence | Design consequence |
|---|---|---|
| Acorn | `services.rustdesk-server.package.version` 求值为 1.1.14 | 保留 NixOS 原生 module、独立 key、fail-closed preflight 和最小端口 |
| Security floor | 1.4.9 于 2026-07-06 发布并包含 PR #15469；CVE-2026-57850 影响 1.4.9 之前版本 | 1.4.8 禁止部署、fallback 和 rollback；两端升级到 1.4.9 |
| Locked nixpkgs baseline | `pkgs.unstable.rustdesk.version` 仍求值为 1.4.8；merged Axiom effective unit使用override后的1.4.9 | 保留该 derivation，override version/source/cargo hash并从同一source重建cargo vendor derivation；不维护功能 patch |
| 1.4.9 IPC | Tag 保留 upstream service-scoped peer uid/executable hardening；实现时重新确认 per-user IPC/PID 与 CLI call sites | 继续使用上游 hardening，并增加真实 process/socket readiness |
| Password CLI | 1.4.9 仍使用 `--password <value>` | 自动部署继续接受 bounded argv；实现时精确复核成功输出语义 |
| Charlie | nixpkgs RustDesk 仍标记 Darwin unsupported；官方有 1.4.9 ARM64 DMG | Pin 官方 DMG，保持签名、固定 app path 和上游 launchd topology |
| Crash controls | Linux/macOS resource limit 不等于关闭 crash metadata | `LimitCORE=0`/`Core=0` 只作低成本 hardening；不做 attestation 或全局 handler |
| Delivery | 配置 PR #139 已 merge 为 `0026eb9922c87e9624ed7352b09b58cddb1a45a3`；Acorn/DNS/SG完成，Axiom contained，Charlie未部署 | 只做Axiom fixed-forward hotfix；后续switch仍来自clean merged commit |
| Axiom session env | Spawned c1 `--server`继承merged root HOME/XDG但缺少display/Wayland/DBus coordinates；drop-in同时改变HOME与session variables | 保留root HOME/XDG，只加入已证明的static session coordinates；不承诺login screen |
| Axiom resolver | Clash fake-IP返回`198.18.0.69`，UDP 21116成功而TCP 21115失败；host mapping到`8.159.128.125`后两者成功 | 用`networking.hosts`做Axiom-only NSS bypass；RustDesk public config保持canonical host |
| Axiom capture | Portal已返回PipeWire node/3840x2160；RustDesk随后无法创建GStreamer factory | 给service补`${pkgs.pipewire}/lib/gstreamer-1.0`，不用`/run/current-system/sw` |
| Storage/config sync | Root/c1 password/salt-derived与public fields byte-equal且未输出值；1.4.9有root-to-local IPC sync | 支持保留existing root canonical state + c1 replica，不支持共享storage或迁移 |
| Readiness | Existing gate只证明root/c1 RustDesk PID/socket/IPC/public config | Graphical resources是post-ready acceptance；缺失时revision已消耗，只能stop + fixed-forward |
| Attempt state | `0026eb99` reservation + ready、无stamp；临时restart使ready identity drift | 旧state不得finalize/resume/rollback；新runtime contract必须产生fresh composite revision |

## 2. Production Runtime Diagnosis

### Scope and current state

- Evidence was observed on merged commit `0026eb9922c87e9624ed7352b09b58cddb1a45a3`, RustDesk 1.4.9 and Axiom ID 11841215. No secret plaintext or secret-derived value was recorded.
- Acorn hbbs/hbbr, public DNS, host firewall and Aliyun SG were healthy. Axiom had a current reservation + ready and no stamp.
- Temporary service launches/restarts changed the auth-serving process identities, so that ready is invalid. It must not be finalized or resumed. Axiom RustDesk is now stopped pending a merged fixed-forward revision; Charlie has not been deployed.

### Reproduction and isolation

| Step | Observation | Conclusion |
|---|---|---|
| Initial auth | Correct-password attempts ended with `连接被对方关闭` | Server reachability alone did not establish a usable Axiom session |
| Spawned process env | Root `--service` spawned c1 `--server` with merged `HOME=/root`, `XDG_CONFIG_HOME=/root/.config`, and no DISPLAY/Wayland/runtime-dir/session-bus variables | Storage namespace matched merged design; static session coordinates were missing |
| Live session env | Generic and Hyprland portals plus the user manager had `DISPLAY=:0`, `WAYLAND_DISPLAY=wayland-1`, `XDG_RUNTIME_DIR=/run/user/1000`, `DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus`, `XDG_CURRENT_DESKTOP=Hyprland`, `XDG_SESSION_TYPE=wayland` | These are the target trusted-session coordinates |
| Session env drop-in | The experiment, before direct-host mapping, added session coordinates and c1 HOME/config/data homes together; the user server then initialized Wayland/UInput | It proves the static session coordinates are needed, but does **not** independently prove HOME/XDG relocation; storage change is rejected |
| Resolver | User-server log resolved `rustdesk.0xc1.wang` through Clash fake-IP `198.18.0.69`; UDP 21116 worked, TCP 21115 failed | Fake-IP resolution broke the required TCP path |
| Reversible host mapping | Mapping canonical host to `8.159.128.125` made UDP 21116 and TCP 21115 NAT tests succeed and allowed correct-password auth | Axiom needs a deterministic local resolver bypass while public config stays canonical |
| Capture | Portal DBus returned a PipeWire stream/node and 3840x2160 metadata; capture reported `Failed to create capturer for display 0` and the server then logged exactly `Failed scrap Failed to create element from factory name` | Portal selection/stream creation succeeded; failure moved to local GStreamer factory creation |
| Plugin path | Adding `/run/current-system/sw/lib/gstreamer-1.0` to runtime service env made the same test show the screen and accept keyboard/mouse input | PipeWire GStreamer plugin visibility is the third necessary condition; mutable profile path is evidence, not permanent design |
| Password/portal controls | Root/c1 password/salt-derived and public fields matched byte-for-byte without printing values; portal restart did not fix capture | Password persistence and portal restart are excluded; equality supports existing IPC sync, not a shared filesystem namespace |

The runtime experiments prove the resolver, session-coordinate and plugin-path components individually. The smallest approved candidate combines them while preserving root storage; that exact root-preserving combination remains a post-merge runtime gate:

1. canonical hostname resolves directly to Acorn public IP despite Clash;
2. the spawned c1 server inherits the static display/Wayland/runtime-dir/session-bus coordinates; root HOME/XDG remain unchanged by design and require live confirmation;
3. the service-visible GStreamer path includes the PipeWire plugin.

After validation, RustDesk was stopped; the temporary drop-in was removed; `/etc/hosts` was restored to the NixOS-managed symlink; temporary scripts/log copies were deleted; no RustDesk user process remains.

### Repository/source corroboration

- Merged `hosts/axiom/default.nix` sets root service and password CLI contexts to`HOME=/root`、`XDG_CONFIG_HOME=/root/.config`; it does not declare`XDG_DATA_HOME`. This is the canonical storage model the hotfix preserves.
- Pinned `libs/hbb_common/src/config.rs:751-805` derives config paths from HOME/XDG and explicitly warns that privileged code must not trust an environment-redirected HOME. Moving root to`/home/c1`would therefore create a new trust/ownership contract, not a display-only hint.
- Pinned `src/server.rs:691-824` makes non-root server startup request root config over service IPC, writes received config through the local user process, and keeps a bidirectional watch. This supports separate root canonical and c1 local namespaces; matching fields are evidence that sync works, not evidence that both actors should share files.
- Existing c1 diagnostic/local config is therefore noncanonical. The revised hotfix neither reads it as deployment input nor adds activation/provision code to copy, delete, migrate or chown it. Root service/provision must not reference`/home/c1/.config/rustdesk`or another c1 RustDesk state path.
- One `rustdeskServiceEnvironment` attrset must drive both the exact explicit unit environment and the composite hash via`builtins.toJSON`. It retains root HOME/XDG, adds only the six static session coordinates, the immutable PipeWire plugin path and existing latency values, and omits`XDG_DATA_HOME`.
- This no-migration design has a structural future-state argument: with root service identity + root HOME/XDG unchanged, an absent future root config can only be created by upstream as root under the root namespace; the hotfix does not precreate c1 state, and any later c1 local state is created by the upstream UID c1 process. Generated/evaluated artifact inspection plus post-switch owner/type/mode checks are sufficient; deleting production state to simulate clean start would itself violate the active reservation/storage boundary.
- Axiom already has a destination-IP direct-route unit for`8.159.128.125`, and`rustdesk.service`depends on it. The missing deterministic piece was canonical-name resolution; no new Clash rule is required.
- The root service is wanted by`multi-user.target`and ordered after`systemd-user-sessions.service`. Existing pre-secret checks establish only main/c1 RustDesk PID, socket, service IPC and public config. They do not test Hyprland, actual Wayland socket, user bus, portal, PipeWire, capture or input; those remain post-ready external acceptance gates and may consume the revision on failure.
- Current eval reports`networking.hosts`as an attribute set of hostname lists and only the existing Axiom localhost entry. The bounded implementation is`networking.hosts.${acornPublicIp} = [ rustdeskHost ];`.
- Pinned 1.4.9`libs/scrap/src/wayland/pipewire.rs`creates`pipewiresrc`, then`videoconvert`, then`appsink`(`PipeWireRecorder::new`). The merged wrapper exposes GStreamer core and`gst-plugins-base`but no PipeWire directory.
- Evaluated`${pkgs.pipewire}/lib/gstreamer-1.0`contains`libgstpipewire.so`; a read-only local check with wrapper core/base plus this directory resolved all three factories. Hotfix still requires fresh Axiom build and effective-closure checks.

## 3. Repository and Lock Evidence

### Inputs and packages

- `flake.nix` 暴露 `nixpkgs-unstable`，host package set 通过 `pkgs.unstable` 使用该 input（`lib/nixos.nix`）。
- `flake.lock` 的 `nixpkgs-unstable` rev 为 `b5aa0fbd538984f6e3d201be0005b4463d8b09f8`。
- 当前 eval：
  - `nix eval --raw .#nixosConfigurations.axiom.pkgs.unstable.rustdesk.version` -> `1.4.8`
  - `nix eval --raw .#nixosConfigurations.acorn.config.services.rustdesk-server.package.version` -> `1.1.14`
- 锁定 unstable `pkgs/by-name/ru/rustdesk/package.nix` 当前仍为 1.4.8；它作为 1.4.9 override 的集成基线：
  - `version = "1.4.8"`
  - source 为 GitHub tag 1.4.8，fetch submodules
  - `meta.badPlatforms = lib.platforms.darwin`
  - package 自带 nixpkgs 的 reproducibility patch、postPatch、依赖与 wrapper；1.4.9 override 只允许改变 version/source/cargo hash，以及显式重建对应 `cargoDeps`。

### 1.4.9 immutable source/vendor identity

- Tag commit：`6c578292e8ebbbec708b76986ba8c4bc7c509747`
- 唯一 submodule：`libs/hbb_common` at `7e1c392c62d39c364127307cd408421dd5f8cfb0`；无 nested submodules
- Source SRI（含 submodule）：`sha256-AnwdIO4TveC48uMioBCvH60xun24ckK420ONSEB9lQI=`
- Cargo vendor SRI：`sha256-HPvvsTcjSErGfdNwsHgWhs930Fe0hmK1g5J/ngtlkKM=`
- 只 override `cargoHash` 会保留已生成的1.4.8 `cargoDeps`并build失败；effective package必须显式从1.4.9 source重建vendor derivation。
- 锁定nixpkgs reproducibility patch可应用，`webm 1.1.0`与`webm-sys 1.0.4`仍存在。

### Existing host conventions

- `modules/agenix.nix` 与锁定 agenix module 提供 host-local runtime secret path；明文位于 `/run/agenix.d/<generation>` 一类 runtime 位置，consumer 应只把 path 放进 Nix-generated script/unit。
- `hosts/acorn/default.nix` 的 TCP firewall 列表使用 `lib.mkForce`。RustDesk module 的 `openFirewall` 不能作为最小 ingress 的可靠来源，必须显式修改现有列表。
- `hosts/axiom/default.nix` 已有 Hyprland、ToDesk与目的地址为Acorn公网IP的Clash bypass route；runtime evidence只要求补canonical-name NSS mapping，不要求新增Clash policy，且不能移除现有回退。
- `hosts/charlie/default.nix` 是 `aarch64-darwin`，已有 nix-darwin launchd/agenix 模式；TCC 仍需人工授权。

## 4. RustDesk Client 1.4.9 Evidence

Tag `1.4.9` 解析到 commit `6c578292e8ebbbec708b76986ba8c4bc7c509747`。现有证据确认原 nixpkgs patch target 与 `webm 1.1.0`/`webm-sys 1.0.4` 依赖仍存在；实现必须在实际 fetched source 上重新确认下列 call sites与语义。

### Password CLI remains argv-only

- `src/core_main.rs:432-452` 只识别 `--password`，要求 installed + root，并把 `args[1]` 传给 `crate::ipc::set_permanent_password`。
- Source 中没有 `--password-file` 或 password stdin 管理入口。
- `src/ipc.rs:1591-1626` 发送 password 后等待 daemon ACK；CLI success 输出 `Done!`。
- Context7 检索到的官方 RustDesk wiki/Linux headless 文档也仍示例 `sudo rustdesk --password <password>`。

**结论**：使用官方 1.4.9 package/bundle 时，自动设置永久密码仍会产生短暂 secret argv。当前 contract 已接受该 residual，但仍要求不把值写入 unit、environment 或日志。

### Password ACK is not a durability proof

- `src/ipc.rs:1607-1626` 在daemon返回ACK后输出成功；后续storage sync失败只记录warning，不改变ACK。
- `hbb_common` config write错误也不会通过该ACK路径传播给CLI。因此精确`Done!`只能证明daemon接受了请求，不能证明restart后新密码仍持久化。
- 当前设计在ACK和全部auth-serving process restart/replacement及public proof后发布绑定revision/PID/start identity的非秘密ready记录，保留current reservation且不自动写stamp。从另一台设备完成新密码正测和旧密码负测后，operator运行不读取secret的`rustdesk-provision-finalize --confirm-remote-auth`提交stamp。
- 未finalize的current reservation跨service restart/reboot阻止自动重放；测试失败时保持pending/failed状态并按rotation或显式reset流程处理。
- 用户在2026-07-12明确选择简化的“远测后手动finalize”边界，而不是ticket/history驱动的自动反回滚框架。Provision/finalize用同一小型operation lock串行化；一旦新revision已attempt，旧generation禁止rollback，只能保持RustDesk停止并fixed-forward。

### Public option fallback requires a negative control

- `src/ipc.rs:1721-1768` 的 `get_options` 在IPC失败时回退caller-local config；`set_options`即使IPC连接失败也会写caller-local config。
- 因此“调用`--option`后比较值”本身不能证明active-user server已接收配置。
- Current design为每次apply/query提供独立root-owned临时`HOME`/`XDG_CONFIG_HOME`。Query使用新的空fallback home；IPC失败只能得到空/default，不能满足非默认host/key/relay。
- Verification还必须阻断IPC并预置caller-local expected values，证明helper不会从该fallback context误判成功。

### Service IPC hardening is upstream

- `src/ipc/auth.rs:168-172`：Linux/macOS service peer 只允许 root 或当前 active uid。
- `src/ipc/auth.rs:213-277`：Linux 使用 `SO_PEERCRED`，macOS 使用 `getpeereid` 获取 peer uid；同时可取得 peer pid。
- `src/ipc/auth.rs:639-657`：service-scoped connection 还要求 peer executable 与当前 executable 匹配，失败即拒绝。
- `src/ipc.rs:491-542`：service-scoped channel 在 accept 后授权；`_service` 只允许 `SyncConfig` message。
- `src/ipc.rs:620-641`：service sockets 虽为 active user 可连接而设为 `0666`，但授权在 accept-time 执行；非 service socket 为 `0600`。
- `src/ipc/fs.rs:195-386`：IPC parent directory 使用 no-follow fd、owner/mode 检查与 hardening。

**结论**：1.4.9 保留 service IPC peer authorization，并新增 session-scope authorization 修复。该事实支持使用上游安全边界，但不创造 password-file CLI，也不改变 argv residual。

### Upstream service shapes

- `res/rustdesk.service` 以 root 运行 `rustdesk --service`，使用 `KillMode=mixed` 和较高 `LimitNOFILE`；Axiom 的 host-local unit 应保持该基本 topology。
- `src/platform/macos.rs:189-223` 要求 `/Library/LaunchDaemons/*_service.plist` 与 `/Library/LaunchAgents/*_server.plist` 同时存在。
- `src/platform/privileges_scripts/daemon.plist` 启动 `/Applications/RustDesk.app/Contents/MacOS/service`。
- `src/platform/privileges_scripts/agent.plist` 启动 `RustDesk --server`，session types 为 `LoginWindow` 与 `Aqua`。
- `src/platform/macos.rs:804-811` 的 installed check 要求 executable 位于 `/Applications/<App>.app` 下。

## 5. RustDesk Server 1.1.14 Evidence

以下旧调研结论与新设计仍一致：

- NixOS module 创建 `rustdesk-signal.service`/hbbs 和 `rustdesk-relay.service`/hbbr，工作目录/状态目录为 `/var/lib/rustdesk`，服务身份为 `rustdesk`。
- Server source 从工作目录的 `id_ed25519` 读取 key；`-k _` 触发该读取。Key 缺失时上游可自动生成，因此 preflight 必须在 ExecStart 前检查可读、非空并 fail closed。
- hbbs 与 hbbr 都传 `-k _`，可确保 signal/relay 使用同一 public key value；hbbr 不应省略 key check。
- Native clients 需要：
  - hbbs TCP 21115、21116 与 UDP 21116
  - hbbr TCP 21117
  - 21118/21119 是 WebSocket 入口，本任务不需要
- NixOS module `openFirewall=true` 会开放 21115-21119/TCP 与 21116/UDP，因此当前设计必须设 false 并手工声明最小集合。
- Module 未提供 restart policy；host override 需要 `Restart=on-failure`。

## 6. Official Charlie 1.4.9 Artifact

GitHub official release API（tag `1.4.9`）在 2026-07-12 查询到：

| Field | Value |
|---|---|
| Published | `2026-07-06T10:02:30Z` |
| Asset | `rustdesk-1.4.9-aarch64.dmg` |
| URL | `https://github.com/rustdesk/rustdesk/releases/download/1.4.9/rustdesk-1.4.9-aarch64.dmg` |
| Size | `25906851` bytes |
| GitHub digest | `sha256:f7935597b247d42c8f2a2ed71176a9f5868018cd9e1a33b8096418a668c8caf0` |
| Nix SRI | `sha256-95NVl7JH1CyPKi7XEXap9YaAGM2eGjO4CWQYpmjIyvA=` |

SRI 由以下命令对 GitHub digest 做格式转换，未改变 digest：

`nix hash convert --hash-algo sha256 --to sri f7935597b247d42c8f2a2ed71176a9f5868018cd9e1a33b8096418a668c8caf0`

Linux 侧的 digest 不能替代 Darwin Gatekeeper 验证。Store bundle 与 `/Applications/RustDesk.app` destination 仍须在 Charlie 上执行 `codesign --verify --deep --strict` 和 `spctl`；失败不得 ad-hoc re-sign 后继续。

## 7. Secret and Crash Boundary Evidence

### Still-current evidence

- Agenix 避免把 plaintext 放进 Git/Nix store，但 root 运行时仍可读取 secret；它不是对 endpoint root/admin 的隔离。
- RustDesk 会把永久密码转换为 host-local derived state。删除 age source 不等于撤销已设置密码；rollback/decommission 必须处理 mutable config。
- Linux locked systemd 的历史源码/实证表明：`LimitCORE=0` 可阻止或大幅限制 memory core image，但仍可能留下 `COREDUMP_CMDLINE` 等 metadata。
- macOS launchd `SoftResourceLimits/Core=0` 与 `HardResourceLimits/Core=0` 只约束传统 core resource；Apple `ReportCrash` 是独立机制。

这些发现现在只用于界定 residual：不再要求 global handler、crash attestation 或 synthetic marker test，也不得声称 core limit 消除了 argv metadata。

### Accepted trust boundary

- Axiom 与 Charlie 是 single-owner trusted endpoints；本地 root/admin 和同 owner 进程不作为需要从永久密码隔离的对手。
- 正常路径仍禁止 plaintext 进入 Git、Nix store、常规日志或 PR。
- 用户明确接受 bounded provisioning window 中的 argv 可见性，以及恰在窗口崩溃时 non-core crash metadata 持久化的低概率残余。

## 8. Historical Findings and Superseded Design

以下内容保留为历史记录，不再是 current design requirement：

| Historical finding/design | Current status |
|---|---|
| RustDesk 1.4.8 client | **Prohibited**：CVE-2026-57850 影响 1.4.9 之前版本，不得部署或回滚 |
| Stable `pkgs.rustdesk` 1.4.3 | **Superseded**：Axiom 基于 locked unstable derivation source-build 1.4.9 |
| Official 1.4.3/1.4.8 ARM64 DMG 与旧 SRI | **Superseded**：不得用于实现；使用本文件的 1.4.9 asset/digest/SRI |
| 1.4.3 service IPC 缺少 peer credential authorization | **Version-specific history**：1.4.9 有 peer-uid/executable/message hardening |
| Local `--password-file` patch 可行性 | **Rejected option**：维护成本高且不能用于签名 macOS bundle |
| Exact-OS crash attestation、synthetic marker、全树 crash scan | **Removed requirement**：用户已接受 bounded argv/crash-metadata residual |
| Global `core_pattern` handler 或全局关闭 crash reporting | **Rejected option**：影响面和维护成本不成比例 |
| Axiom provision 使用 `Wants+After`，避免 restart propagation | **Still current**：保留为必要 dependency topology |
| Merge-before-switch 与 follow-up evidence PR | **Still current**：保留为交付顺序 |
| Round 7 pre-deployment PASS | **Partially superseded**：Acorn/Charlie artifacts与Axiom package/provision state machine证据保留；Axiom runtime integration与rollout authorization必须fresh review |
| Runtime `/run/current-system/sw/lib/gstreamer-1.0` drop-in | **Evidence only**：证明missing PipeWire plugin；永久设计使用`${pkgs.pipewire}/lib/gstreamer-1.0` |
| Draft c1 HOME/XDG service environment | **Rejected after Round 8 FAIL**：experiment co-varied storage/session values；未证明storage relocation，且引入privileged path trust、ownership和migration gap |
| Round 8/9 review | **Round 8 FAIL historical; Round 9 PASS current**：revised RFC保留root storage、收窄readiness并获准实现；candidate runtime仍待验证 |

PR #139 已删除历史 `hosts/axiom/rustdesk-password-file.patch`、`test/rustdesk-round3-linux.py` 与 `test/rustdesk-charlie-safety.py`。Runtime hotfix不得恢复这些设计，也不得增加新的跨平台framework。

## 9. Current Gates

这些是实施/部署 gates，不是未决设计问题：

- **Completed server gates**：Acorn deployment、公共DNS、host firewall与Aliyun SG已完成并健康；历史NXDOMAIN不再是current state。
- **Axiom pre-merge**：effective`networking.hosts`、root-preserving exact service/password environment、no-migration generated-artifact checks、immutable plugin closure、三factory、narrow readiness、fresh revision tests与fresh full build。
- **Axiom storage/runtime**：pre/post metadata只检查type/owner/group/mode；root canonical objects保持`root:root`，c1 objects保持c1-owned，不dump config、不输出secret-derived value，也不做destructive clean test。
- **Axiom graphical acceptance**：new reservation/ready后再检查actual Wayland socket、user bus、portal、PipeWire、screen/input与password正/负测。缺失会消耗revision，只能stop + another fixed-forward。
- **Wayland boundary**：只验收active c1 Hyprland session；lock/login/DPMS分项记录，不承诺login screen或no-login zero-reservation。
- **Charlie**：Axiom finalize前禁止部署；之后继续执行destination signature、launchd、TCC、auth/finalize gates。
- **Closeout**：direct/forced relay、跨机密码负测与fallback evidence进入独立follow-up PR。

## 10. Evidence Index

- Contract：`../plan.md`
- RFC：[`rfc.md`](./rfc.md)
- Review evidence：[`review-rfc.md`](./review-rfc.md) Round 9 PASS；Round 8 FAIL retained as history
- Repo：
  - `flake.{nix,lock}`
  - `lib/nixos.nix`
  - `modules/agenix.nix`
  - `hosts/{acorn,axiom,charlie}/default.nix`
  - `hosts/{acorn,axiom,charlie}/secrets/secrets.nix`
- Locked nixpkgs：
  - `pkgs/by-name/ru/rustdesk/package.nix`
  - `nixos/modules/services/monitoring/rustdesk-server.nix`
- Production observation baseline：merged commit `0026eb9922c87e9624ed7352b09b58cddb1a45a3`，RustDesk 1.4.9，Axiom ID 11841215（no secret values）
- RustDesk 1.4.9 source：
  - `src/core_main.rs`
  - `src/ipc.rs`, `src/ipc/{auth,fs}.rs`
  - `src/server.rs` (`wait_initial_config_sync`, `sync_and_watch_config_dir`)
  - `libs/hbb_common/src/config.rs` (`Config::get_home`, `Config::path`)
  - `libs/scrap/src/wayland/pipewire.rs` (`PipeWireRecorder::new`)
  - `src/platform/macos.rs`
  - `src/platform/privileges_scripts/{agent,daemon}.plist`
  - `res/rustdesk.service`
- RustDesk Server 1.1.14 source：`src/{common,rendezvous_server,relay_server}.rs`
- Official release API/tag：`https://github.com/rustdesk/rustdesk/releases/tag/1.4.9`
- Session-scope fix：`https://github.com/rustdesk/rustdesk/pull/15469`
- CVE：`https://www.cve.org/CVERecord?id=CVE-2026-57850`
- Official docs：
  - `https://rustdesk.com/docs/en/self-host/client-configuration/`
  - `https://rustdesk.com/docs/en/client/linux/`
  - `https://rustdesk.com/docs/en/client/mac/`

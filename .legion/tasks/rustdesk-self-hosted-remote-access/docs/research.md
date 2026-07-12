# Research: RustDesk 自托管远程访问（1.4.9 security revision）

> **Purpose**: 为当前 RFC 提供最短、可追溯的版本与平台证据。
> **Contract source**: `../plan.md`
> **Checked**: 2026-07-12
> **Secret handling**: 未打开任何 `.age` payload，未读取未跟踪密码文件。

## 1. Current Conclusion

| Area | Current evidence | Design consequence |
|---|---|---|
| Acorn | `services.rustdesk-server.package.version` 求值为 1.1.14 | 保留 NixOS 原生 module、独立 key、fail-closed preflight 和最小端口 |
| Security floor | 1.4.9 于 2026-07-06 发布并包含 PR #15469；CVE-2026-57850 影响 1.4.9 之前版本 | 1.4.8 禁止部署、fallback 和 rollback；两端升级到 1.4.9 |
| Axiom | `pkgs.unstable.rustdesk.version` 仍求值为 1.4.8 | 保留该 derivation，override version/source/cargo hash并从同一source重建cargo vendor derivation；不维护功能 patch |
| 1.4.9 IPC | Tag 保留 upstream service-scoped peer uid/executable hardening；实现时重新确认 per-user IPC/PID 与 CLI call sites | 继续使用上游 hardening，并增加真实 process/socket readiness |
| Password CLI | 1.4.9 仍使用 `--password <value>` | 自动部署继续接受 bounded argv；实现时精确复核成功输出语义 |
| Charlie | nixpkgs RustDesk 仍标记 Darwin unsupported；官方有 1.4.9 ARM64 DMG | Pin 官方 DMG，保持签名、固定 app path 和上游 launchd topology |
| Crash controls | Linux/macOS resource limit 不等于关闭 crash metadata | `LimitCORE=0`/`Core=0` 只作低成本 hardening；不做 attestation 或全局 handler |
| Delivery | 最新 plan 要求 merge-before-switch 和 follow-up evidence PR | 配置 PR 与生产证据分离，三台只从 clean merged baseline 部署 |

## 2. Repository and Lock Evidence

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
- `hosts/axiom/default.nix` 已有 Hyprland、ToDesk、Clash/direct-route 相关配置；RustDesk 需真机验证 active Wayland session，不能移除现有回退。
- `hosts/charlie/default.nix` 是 `aarch64-darwin`，已有 nix-darwin launchd/agenix 模式；TCC 仍需人工授权。

## 3. RustDesk Client 1.4.9 Evidence

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

## 4. RustDesk Server 1.1.14 Evidence

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

## 5. Official Charlie 1.4.9 Artifact

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

## 6. Secret and Crash Boundary Evidence

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

## 7. Historical Findings and Superseded Design

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

因此实施必须删除：

- `hosts/axiom/rustdesk-password-file.patch`
- `test/rustdesk-round3-linux.py`
- `test/rustdesk-charlie-safety.py`

当前 worktree 中与 password patch、Charlie crash attestation 或数百行 transaction/crash harness 绑定的 host 配置同样属于待简化实现，不应被 RFC 继续合法化。

## 8. Remaining External Gates

这些是部署/验收 gates，不是未决设计问题：

- **DNS**：2026-07-11 的历史公共 DoH 检查为 NXDOMAIN；部署前必须重新查询并确认 DNS-only A record，不能使用本机 Clash fake-IP 结果。
- **Aliyun SG**：仓库不管理其规则，当前状态/owner 未由本研究读取；开放前确认只允许 TCP 21115-21117、UDP 21116，并保留 21114/21118/21119 负证据。
- **Darwin**：真实 aarch64-darwin build、store/destination signature、launchd load 和 app ownership。
- **TCC**：Screen Recording、Accessibility、Input Monitoring 人工授权。
- **Wayland**：Axiom active Hyprland session 必测；lock/login/DPMS 分项记录。
- **Runtime auth**：两台 password 各自正测，旧/错误/跨机 password 负测；direct 与 forced relay 都通过。

## 9. Evidence Index

- Contract：`../plan.md`
- RFC：[`rfc.md`](./rfc.md)
- Repo：
  - `flake.{nix,lock}`
  - `lib/nixos.nix`
  - `modules/agenix.nix`
  - `hosts/{acorn,axiom,charlie}/default.nix`
  - `hosts/{acorn,axiom,charlie}/secrets/secrets.nix`
- Locked nixpkgs：
  - `pkgs/by-name/ru/rustdesk/package.nix`
  - `nixos/modules/services/monitoring/rustdesk-server.nix`
- RustDesk 1.4.9 source：
  - `src/core_main.rs`
  - `src/ipc.rs`, `src/ipc/{auth,fs}.rs`
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

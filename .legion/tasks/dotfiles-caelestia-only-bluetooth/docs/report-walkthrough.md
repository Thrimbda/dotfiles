# 交付 Walkthrough：全局 Caelestia-only 蓝牙控制面

> **Mode**：`implementation`
> **设计基线**：RFC Revision 5
> **前置结论**：`review-rfc` PASS · `test-report` PASS · `review-change` PASS
> **审阅目标**：确认全局蓝牙控制面收敛、安全边界、rfkill 分支及剩余部署 gate 可接受。

## 先看结论

这是一项 **全局 dotfiles 共享 profile** 变更，不是 Axiom 主机特判。当前声明 Bluetooth profile 的 `axiom`、`azar`、`harusame`、`ramen`、`udon` 都采用同一策略：

- BlueZ 与 `bluetoothctl`/`bctl` 继续保留；
- stock Blueman、Blueman Manager/tray/mechanism 与 Rofi Bluetooth 不再构成可见或可激活控制面；
- 只有启用 Caelestia 的主机拥有图形蓝牙开关、扫描、配对与连接入口；
- 所有 Bluetooth profile 主机保留一个不可见、普通用户权限的 AuthAgent，处理 PIN/passkey 等 BlueZ Agent1 交互；
- Bluetooth soft block 在 boot/add/resume 后由 Bluetooth-only finalizer 收敛，ordinary 与 TLP 主机使用不同的 systemd 接线；
- Caelestia 主列表优先 connected、paired/bonded 与真实名称设备，但完整 pairing page 仍保留匿名设备。

最终设计复审、验证和变更审查均为 **PASS，无 blocking finding**。

> **重要证据边界**：本次验证 **没有部署或激活任何 generation**，也没有调用宿主机的 `systemctl`、BlueZ、rfkill、TLP 或真实配对设备。Axiom toplevel 只完成构建；所有 systemd/rfkill 运行时操作都发生在隔离的 NixOS QEMU VM 或私有测试总线/fixture 中。宿主 live Bluetooth/rfkill 状态未改变。

## 1. 全局所有权边界

共享配置按“是否声明 Bluetooth profile”与“是否启用 Caelestia”组合，而不是按 hostname 分支：

| Bluetooth profile | Caelestia | 有效行为 |
|---:|---:|---|
| 否 | 否 | 无本任务蓝牙行为 |
| 否 | 是 | Caelestia 可显示无 adapter；不运行 AuthAgent |
| 是 | 否 | BlueZ + CLI + headless AuthAgent；有意不提供 GUI 管理器 |
| 是 | 是 | BlueZ + CLI + headless AuthAgent；Caelestia 是唯一 GUI 管理面 |

当前五台 Bluetooth 主机都启用 Caelestia；`axiom.extendModules` 的 synthetic `Caelestia=false` 边界证明共享 profile 不依赖这一偶然现状。Atlas 的 Bluetooth-off 边界也确认不会生成 agent 或 rfkill helper。

### 可见控制面如何收敛

```text
之前
  BlueZ/CLI + Blueman applet/manager/tray/mechanism
             + Rofi Bluetooth + Caelestia

之后
  BlueZ/CLI ────────────────┐
  headless AuthAgent ───────┼─ 后端能力，不提供管理入口
  Caelestia ────────────────┘  唯一可见图形控制面（仅启用时）
```

具体删除了：

- `services.blueman.enable` 与 public `blueman` package exposure；
- Blueman desktop/autostart、session/system D-Bus activation 与 mechanism 的搜索路径来源；
- Rofi Bluetooth launcher；
- Hyprland 中仅服务 `blueman-manager` 的 window rules。

完整 Blueman 2.4.6 仍可作为 runner 的 **私有 Nix store Python/UI library**，但不进入 system/user package、D-Bus、systemd、PATH 或 session XDG 集合。store closure 中存在文件不等于它们可被桌面或总线发现。

## 2. Headless AuthAgent 边界

`bluetooth-auth-agent.py` 没有重写配对协议或 Blueman 的 PIN/passkey UI；它只负责三个宿主边界：

1. **Readiness**：依次检查环境变量、Blueman schema、session bus、GTK 初始化与 icon；全部通过后才接触 system bus。
2. **私有适配**：复用 pinned Blueman `BluezAgent`，把五个 notification call site 固定到进程内 GTK `_NotificationDialog`。
3. **生命周期**：使用一条 persistent Gio system-bus connection 完成 local export → `RegisterAgent` → `RequestDefaultAgent`，并在失败、BlueZ owner 变化、Release、connection close 与信号退出时按状态清理。

| 项目 | 边界 |
|---|---|
| 身份 | `config.user.name`；当前为 `c1` 或 `hlissner`，不是 root |
| systemd user unit | `WantedBy` / `PartOf` / `After=graphical-session.target`，`Type=notify` |
| readiness | 只有 state=`default` 后发送 `READY=1` |
| 公共命令 | runner output 仅 `blueman-auth-agent` 一个 non-dot executable |
| 不加载 | applet、PowerManager、KillSwitch、Menu、tray、manager、mechanism |
| D-Bus identity | object export 与 Register/Default/Unregister 使用同一 connection/sender |
| 清理 | registered/default 先远端 unregister 再 local unexport；Release/name vanish 只做适用的本地清理 |

未知的 BlueZ owner query 错误不会留下“unit active 但没有 agent”的假健康状态：实现会逆序清理并以非零状态退出，由 `Restart=on-failure` 重建连接。

## 3. rfkill：ordinary 与 TLP 明确分流

两个分支复用同一个无参数、幂等 finalizer：

1. 只枚举 `/sys/class/rfkill` 中 `type=bluetooth` 的 entry；
2. 无设备或全部 `soft=0` 时零写成功；
3. 任一 Bluetooth `soft=1` 时只执行一次 `rfkill unblock bluetooth`；
4. 重读并验证所有 Bluetooth entry，不收敛则失败；
5. 不执行 `unblock all`，不修改 hard block、WLAN persisted state 或 TLP state。

| 分支 | 主机 | Boot / ordinary lifecycle | Device ADD | Resume | stock systemd-rfkill |
|---|---|---|---|---|---|
| Ordinary | Axiom、Azar、Harusame、Udon | helper 仍由 `multi-user.target` 拉起；每个 `systemd-rfkill.service` invocation 追加唯一 `ExecStopPost` finalizer | 仍 target stock `systemd-rfkill.service` | `post-resume` nonblocking restart base helper | 保留 vendor unit/socket 与 restore 语义 |
| TLP | Ramen | base helper 无 `WantedBy`; `tlp.service` weak-`Wants` helper，helper `After=tlp.service` | `bluetooth-rfkill-unblock@%k.service`，每个 rfkill device 独立 unit identity | `post-resume` nonblocking restart base helper；无 `tlp-sleep` Bluetooth hook | 继续 masked/disabled；无 ExecStopPost、无 InvocationID |

TLP boot 的有效顺序为：

```text
multi-user.target
       │ Wants / vendor ordering
       ▼
  tlp.service
       │ weak Wants + helper After=tlp.service
       ▼
bluetooth-rfkill-unblock.service

ADD    ──> bluetooth-rfkill-unblock@rfkillN.service
resume ──> post-resume.service ──> restart base helper
```

关键点是 Ramen 的 base helper **不再**直接出现在 `multi-user.target.wants/`。这移除了旧设计的 target → helper 回边；`%k/%I` 只决定 template unit identity/Description，不进入 root `ExecStart`、Environment、shell 或 finalizer 参数。

## 4. Caelestia 设备命名与主列表策略

`caelestia-bluetooth-policy.js` 是生产与测试共用的单一 policy source。主列表最多五项，规则为：

1. connected 优先；
2. paired/bonded 次之；
3. 有真实名称的设备再优先；
4. label 使用“非 address 的 trimmed Alias → BlueZ `deviceName` → address”；
5. 使用大小写无关 label、规范化 address、原始 index 做确定性 tie-break；不修改输入数组。

匿名且未 connected/paired/bonded 的广播不会挤占主五项；匿名但已连接、已配对或已 bonded 的设备仍可进入主列表。完整 `BluetoothPairing.qml` 不引入该过滤、不截断五项，匿名未 bonded 设备仍可被发现和配对。

策略不会根据 MAC、OUI 或厂商广播猜测产品名。Caelestia package 安装后的 `BluetoothPolicy.js` 与仓库 source 逐字节一致，patch 只把主 popout 接到该 policy。

## 5. 安全与隐私姿态

| 风险面 | 实现边界 | 已有证据 |
|---|---|---|
| 用户侧提权 | AuthAgent 以配置用户运行；不恢复 Blueman mechanism/polkit | generated unit 与 surface audit PASS |
| root command 输入 | root 只执行 immutable、无参数 finalizer；template instance 不进入 command | effective unit/template audit PASS |
| 广播范围 | 仅 `rfkill unblock bluetooth`；不触碰 WLAN/hard block | ordinary/TLP sentinel 与 byte/hash gate PASS |
| pairing secret 日志 | runner 只记录 allowlisted lifecycle/request kind；不记录 exception text/traceback；上游 warning 被过滤 | PIN/passkey/MAC/object-path sentinel scan 为 0 |
| desktop notification | pairing notification 直接创建 local GTK dialog，不调用 `org.freedesktop.Notifications.Notify` | 7 interactions，Notify=0 |
| Caelestia history/state | pairing body 不进入 `Notifs.list` 或 `notifs.json` | QML memory delta=0，state delta=0 |
| 私有 Blueman surface | runtime 只在 runner 的 process-local Python/schema/UI/icon 路径中 | output/PATH/XDG/D-Bus/systemd audit PASS |

PIN/passkey 可短暂存在于本地 GTK widget，这是完成交互所必需；边界保证它们不被 runner 写入 journal、desktop notification daemon 或 Caelestia 持久化状态。

## 6. 文件变更导航

最终 `review-change` 审阅的输入 diff 相对 latest `origin/master` 共 27 个路径；本 walkthrough 阶段只新增本文件、standalone HTML 与 `pr-body.md`，没有修改 production code、`plan.md`、`tasks.md` 或 `log.md`。

### Production / desktop

| 路径 | 作用 |
|---|---|
| `modules/desktop/apps/rofi.nix` | 删除 Rofi Bluetooth launcher |
| `modules/desktop/caelestia-bluetooth-policy.js` | 主列表候选、命名与确定性排序 policy |
| `modules/desktop/caelestia-bluetooth-primary.patch` | 将 pinned Caelestia `Bluetooth.qml` 接到同源 policy |
| `modules/desktop/caelestia.nix` | 应用 patch、安装/比对 policy、挂接 policy check |
| `modules/desktop/hyprland.nix` | 删除 `blueman-manager` window rules |
| `modules/profiles/hardware/bluetooth-auth-agent.py` | private headless Agent1 runner |
| `modules/profiles/hardware/bluetooth-rfkill-finalize.sh` | Bluetooth-only rfkill finalizer |
| `modules/profiles/hardware/bluetooth.nix` | 全局 package/unit/surface/rfkill 分支接线及 checks |

### Verification fixtures

- `modules/desktop/tests/caelestia-bluetooth-policy-test.js`
- `modules/profiles/hardware/tests/_bluetooth-predeploy-vm-test.nix`
- `modules/profiles/hardware/tests/fake-rfkill.sh`
- `modules/profiles/hardware/tests/test-bluetooth-auth-agent-integration.py`
- `modules/profiles/hardware/tests/test-bluetooth-auth-agent.py`
- `modules/profiles/hardware/tests/test-bluetooth-rfkill.sh`
- `modules/profiles/hardware/tests/test-systemd-rfkill-reactivation.py`
- `modules/profiles/hardware/tests/vm-agent-call.py`
- `modules/profiles/hardware/tests/vm-fake-bluez.py`
- `modules/profiles/hardware/tests/vm-notifs-harness.qml`
- `modules/profiles/hardware/tests/vm-rfkill-main.py`

### Legion evidence

- 稳定契约与流程记录：`../plan.md`、`../tasks.md`、`../log.md`
- 设计与证据：`research.md`、`rfc.md`、`review-rfc.md`、`test-report.md`、`review-change.md`

## 7. 最强验证证据

以下只转述最终 `test-report.md` 与 `review-change.md` 的既有结果；本 walkthrough 阶段没有补跑测试。

| 结论 | 最强证据 | 状态 |
|---|---|---|
| Ramen production graph 无 cycle | actual Ramen 与 bounded tree 的 82 services / 105 units 名称、edges、links 完全一致；pinned systemd 258.7 full `multi-user.target` verify 为 status 0、diagnostic bytes 0 | PASS |
| gate 能识别旧 cycle | 旧 graph 负向对照同样 status 0，但产生 2 条 cycle/job-deleted 诊断并被 scanner 拒绝 | PASS |
| TLP boot/add/resume 语义 | fresh faithful NixOS VM 保留 vendor TLP units，取得 22 个唯一 InvocationID；覆盖 init success/non-zero/timeout、boot、真实 udev ADD、base + 两个 template 并发、helper failure/recovery、resume success/failure | PASS |
| TLP 无跨 radio 副作用 | stock systemd-rfkill 始终 masked/无 InvocationID；`wlan-delta=0`、`tlp-state-delta=0`，WLAN/TLP bytes/hash 不变 | PASS |
| ordinary final-writer | real-systemd fixture 16 个唯一 InvocationID，覆盖 normal/reactivation/restart/startup/runtime failure/shutdown/no-device/finalizer failure；`wlan-delta=0` | PASS |
| AuthAgent 生命周期 | Nix 环境 18 tests 无 skip；private D-Bus integration 覆盖 7 interactions、单 connection、BlueZ vanish/reappear、Release 与 signal cleanup | PASS |
| pairing 隐私 | generated user unit 两次 READY；`notify=0`、QML memory delta=0、state delta=0；PIN/passkey/MAC/object-path sentinel 为 0 | PASS |
| Caelestia policy | fixture 精确验证排序/截断/匿名边界/输入不变；installed policy 与 source hash 一致；完整 pairing page invariant 保持 | PASS |
| 全局 host 边界 | 五台 Bluetooth host focused eval 与 selected derivations、synthetic Caelestia-off、Atlas Bluetooth-off 均满足预期 | PASS |
| 可交付构建 | Axiom 完整 `config.system.build.toplevel` 构建成功，且包含 focused checks/VM；未激活 generation | PASS |
| 最终审查 | RFC Revision 5 与完整 current diff 均无 blocking finding，security lens 已应用 | PASS |

## 8. 已知但无关的 baseline

这些问题位于 Bluetooth 之外的 host-wide package closure，未通过 production 改动掩盖，也不改变本任务的 focused graph/eval 与 Axiom full-build 结论：

- Azar/Ramen 已知 `pnpm-10.29.2` insecure policy；Ramen 直接完整 etc 还会先遇到 `pkgs.nerdfonts` rename；
- Harusame/Udon 的 `godot_4-export-templates` 已 rename 为 `godot_4-export-templates-bin`；
- Atlas 的 `docker-28.5.2` 被标记 insecure/unmaintained；
- eval 仍有既有 `xorg.xrandr` rename warning。

这些 baseline 应由各自主线维护任务处理，不在本 PR 扩 scope。

## 9. 回滚路径

优先组件级回滚，避免恢复引发原问题的第二控制面：

1. **Caelestia policy 异常**：只回退 package override、patch 与 policy。
2. **rfkill 异常**：ordinary 回退对应 finalizer 集成；TLP 移除 `tlp.service Wants=base`、template/udev 与 post-resume trigger。不要恢复成 TLP helper `WantedBy=multi-user`、`tlp-sleep` hook 或旧的 block→unblock workaround；必要时维护窗口手工 `rfkill unblock bluetooth`。
3. **AuthAgent 异常**：停止 `blueman-auth-agent.service`，临时使用交互式 `bluetoothctl agent KeyboardDisplay`；不要先恢复 stock Blueman。
4. **整代回滚**：仅作为最后手段。它会恢复旧 Blueman/Rofi/mechanism 与 rfkill 竞态，回滚后仍需停止 `app-blueman@autostart` 和 mechanism。

不迁移或删除 BlueZ pairing 数据，也不手工删除旧 Nix store path。当前尚未部署，因此这些是未来 rollout 的回退预案，而不是已执行操作。

## 10. 仍须部署后完成的硬件 gate

这些是最终 RFC 明确保留的真实环境 residual，不是 pre-deploy 测试遗漏可以替代的项目。

### Axiom / `c1`

- 验证真实 UWSM/Wayland user unit 环境、GTK/schema/session bus、state=`default` 与 READY；
- 真实 pairing 与七类 test interaction 只出现 local GTK dialog，Notify monitor、Caelestia history/`notifs.json` 与 journal 无敏感增量；
- 验证 Agent1 Release 与 `bluetooth.service` restart 后恢复到 default；
- 维护窗口执行 MediaTek late unbind/rebind，观察每个 ordinary InvocationID 的 main → ExecStopPost 链、真实 `/dev/rfkill` 与 persisted state；
- reboot 一次、suspend/resume 两次，确认 Bluetooth soft=0、WLAN 不变、Caelestia off→on 可用；
- 确认旧 Blueman surface/name/mechanism 均不可见且不可激活。

### Ramen / `hlissner`

- reboot 后确认 journal 无 cycle/job deletion，TLP init 完成后出现 base helper 新 InvocationID，Bluetooth soft=0；
- 制造至少两个 distinct tagged rfkill ADD，观察不同 `@rfkillN` template；base overlap 时不得合并；
- suspend/resume 两次，确认 `tlp resume` 完成后由 `post-resume.service` 产生新 base InvocationID；
- 全程 stock systemd-rfkill 保持 masked/inactive，WLAN soft/hard/persisted bytes 与真实 TLP config/state 不变。

### 其余 Bluetooth 主机

- 逐台确认 agent active/default、无 Blueman/Rofi surface、ordinary finalizer effective、Bluetooth soft=0；
- 真实设备未自然覆盖的 Agent1 请求类型继续记录为 residual，不宣称已由硬件证明。

## 11. Reviewer checklist

- [ ] 接受 global Bluetooth profile 语义，以及 non-Caelestia 主机有意无 GUI 的边界。
- [ ] 确认 private Blueman runtime 不等于可发现的第二控制面。
- [ ] 重点检查 AuthAgent 单 connection、Release/name-vanish 与 fail-closed owner-query 路径。
- [ ] 确认 ordinary ExecStopPost 与 Ramen TLP weak-Wants/template/post-resume 分支没有交叉泄漏。
- [ ] 确认 finalizer 只写 Bluetooth soft block，instance 名不进入 root command。
- [ ] 确认主五项名称 policy 不影响完整 pairing page，也不猜测匿名设备名。
- [ ] 接受 pre-deploy PASS 与 deploy-only hardware gate 的证据边界。
- [ ] 确认 rollout 前保留组件级 rollback 与“未部署/未改 live state”事实。

## 12. 证据入口

- [稳定契约](../plan.md)
- [RFC Revision 5](rfc.md)
- [PASS RFC review](review-rfc.md)
- [Final PASS test report](test-report.md)
- [Final PASS change review](review-change.md)

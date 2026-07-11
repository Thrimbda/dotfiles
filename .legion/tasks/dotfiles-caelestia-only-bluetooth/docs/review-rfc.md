# RFC Final Re-review：全局 Caelestia-only 蓝牙控制面（Revision 4）

## 结论：PASS

Revision 4 以 ordinary-host `systemd-rfkill.service` 的 per-invocation `ExecStopPost` Bluetooth finalizer关闭了 Revision 3 的最后一个 blocker。该设计不再猜测某个 ADD 由旧还是新 instance 处理：任何可能执行 restore 且最终停止的 invocation 都在 main process结束后运行同一个幂等 Bluetooth-only finalizer；stop-post期间排队的socket reactivation只能在旧finalizer完成后启动，并在新invocation结束时再次finalize。因此旧instance退出与late `RFKILL_OP_ADD`之间的竞态不再能让restore成为最后writer。

正常退出、start/runtime failure、restart、shutdown stop、socket reactivation、有限重复events和no-device路径均有明确语义与确定性fixture。finalizer不读写WLAN，调用的`rfkill unblock bluetooth`在pinned util-linux中使用`RFKILL_OP_CHANGE_ALL`且type固定为Bluetooth；Ramen/TLP求值时完全不生成drop-in或ordinary udev target。先前已通过的lifecycle、package/surface、privacy、QML及verification边界保持完整，未发现新的blocking complexity、rollback gap或scope creep。设计可交回`legion-workflow`进入实现。

## 最后一个 blocker 的关闭验证

### 1. per-invocation final-writer成立

- Ordinary hosts只以`overrideStrategy = "asDropin"`向vendor `systemd-rfkill.service`追加一条不带`-`的`ExecStopPost=${bluetoothRfkillFinalize}`；不替换ExecStart、socket、timeout、restore或enablement（`docs/rfc.md:324-346`）。
- Pinned systemd 258.7保证`ExecStopPost`在service停止后执行，也覆盖无`ExecStop`、unexpected exit和startup failure；restart是完整stop-post后再start，且stop-post计入Before/After ordering（`systemd.service.xml:527-569`）。
- Pinned `service.c:2186-2213,2951-2960,4159-4171,4356-4365`显示unit处于`SERVICE_STOP_POST`/deactivating时，新start返回`-EAGAIN`并保留job，直到旧invocation进入dead；不存在旧finalizer与新main并发。
- Pinned socket路径对deactivating service可排队start；若shutdown已有socket stop job则只抑制/flush新activation。前者由下一invocation自己的finalizer收尾，后者已有当前shutdown finalizer完成Bluetooth写入。
- 因此先前的最坏顺序已关闭：即使udev先可见、旧instance完成finalizer后才投递匹配ADD，新socket invocation仍只能在旧stop-post之后启动；它若restore persisted `1`，退出时自己的ExecStopPost再写`0`。

### 2. 各结束路径

| 路径 | 复审结论 |
|---|---|
| normal 5秒idle exit | **CLOSED**：stock main先drain/save并关闭fd，随后finalizer检查并最后写Bluetooth。 |
| startup/runtime failure | **CLOSED**：已进入service lifecycle的失败仍走ExecStopPost；main failure不会被成功finalizer改写为success，finalizer失败也保持unit failed。Condition/unit-load等从未启动main的skip路径没有restore可覆盖。 |
| explicit restart | **CLOSED**：systemd执行stop → ExecStopPost → start；新instance同样带finalizer。 |
| old-instance/socket reactivation | **CLOSED**：start job可排队但不能跨越`SERVICE_STOP_POST`；每个新instance再次finalize。 |
| shutdown stop | **CLOSED**：stock unit的`Conflicts/Before=shutdown.target`排序包含ExecStopPost；socket停止时不再reactivate，但当前finalizer本身已完成Bluetooth-only收敛，且受90秒stop timeout约束。 |
| finite repeated ADD/CHANGE | **CLOSED**：events可进入当前或下一instance，但最后一个退出的instance必有finalizer；already-unblocked检查避免自激循环。 |
| no-device | **CLOSED**：枚举为空即零写成功；以后device add由host-specific tagged udev另行触发。 |
| finalizer自身失败 | **FAIL CLOSED**：不带`-`，所属invocation失败且发布gate阻塞；设计不伪报收敛。 |

systemd能检测到的post-command spawn/timeout故障不能保证状态收敛，但会留下失败而非成功证据；manager崩溃或断电不属于可执行cleanup能够保证的路径。无限外部rfkill event stream没有完成的activation，RFC也只对有限boot/add/resume burst声明收敛，停止理由明确。

### 3. 幂等与无循环

- finalizer只在至少一个Bluetooth entry的`soft=1`时执行一次unblock；无device或全部soft=0均不写（`docs/rfc.md:312-322`）。
- 第一次1→0产生的CHANGE至多触发后续stock invocation；该instance保存0后，其finalizer看到0并no-op，不产生下一次CHANGE。
- 新ADD若夹在任一阶段，会被当前或排队的新invocation处理；无论归属哪个instance，最后都经过该instance自己的post-finalizer。
- fixture明确覆盖normal、held-ADD reactivation、restart、三次events、failure、shutdown、no-device、already-unblocked和finalizer failure，并按InvocationID记录`main → exit → stop-post`（`:547-560`）。该gate直接覆盖Revision 3遗漏的adversarial interleaving。

## WLAN 与 TLP 边界

### WLAN

- finalizer只枚举`type=bluetooth` sysfs entries，不读写WLAN state file/radio，也不执行`unblock all`。
- Pinned util-linux 2.41.4的`rfkill unblock bluetooth`生成`RFKILL_OP_CHANGE_ALL`并把`event.type`设为解析出的Bluetooth type（`sys-utils/rfkill.c:536-565`）；不会匹配WLAN。
- Stock systemd-rfkill的既有WLAN restore/save语义未被drop-in改写。测试逐case比较WLAN live value、persisted bytes/hash和fake write log，能区分stock既有行为与finalizer越界。

### TLP / Ramen

- `services.tlp.enable=true`时不生成systemd-rfkill drop-in，ordinary udev rule也不存在；Ramen继续保持service/socket masked（`docs/rfc.md:362-366,619-625`）。
- Ramen tagged add只启动独立Bluetooth helper；boot/resume复用同一Bluetooth-only finalizer，不load、start或unmask systemd-rfkill。
- Resume顺序仍为`tlp resume/restore_device_states → suspend.target → post-resume helper`；没有新增`tlp-sleep`依赖或TLP/WLAN policy。
- 五主机eval、ordinary/Ramen生成unit审计和Ramen runtime sentinel共同防止条件分支漂移。

## 已解决边界的回归检查

| 区域 | 结论 | 复审依据 |
|---|---|---|
| GTK/session readiness | **INTACT** | `WantedBy/PartOf/After=graphical-session.target`、UWSM waitenv、schema/session bus/`Gtk.init_check`及READY-only-at-default未变（`:160-203`）。 |
| Agent1 lifecycle | **INTACT** | 单一persistent connection、四状态、owner replacement、Release/name vanish、signals、partial failure与逆序cleanup未变（`:204-257,508-523`）。 |
| package/surface/migration | **INTACT** | 私有Blueman runtime仍不进入profile、PATH/XDG、D-Bus/systemd集合；runner allowlist、stock activation清理与组件rollback未放宽（`:71-158,300-308,429-462`）。 |
| pairing privacy | **INTACT** | 五个module notification call site及RequestPinCode/RequestPasskey两个共享入口均纳入local `_NotificationDialog`和daemon/list/state/journal负向测试；Caelestia production persistence不改（`:258-298,508-545,607-617`）。 |
| Caelestia QML policy | **INTACT** | 生产/测试同源JS、installed hash、QML wiring与pairing-page匿名设备invariant保持（`:375-399,562-564`）。 |
| verification/build scope | **INTACT** | 五主机专项eval/相关derivation、synthetic non-Caelestia、Axiom完整toplevel及部署硬件gate保持；pnpm/Godot基线仍排除（`:573-629`）。 |

## Scope 与 rollback

- 新增行为仅是ordinary stock systemd-rfkill invocation结束时清除Bluetooth soft block；没有长期watcher、polling window、global radio policy、Caelestia notification改造或TLP hook。
- 该策略意味着ordinary host上的有限Bluetooth soft block会在下一次systemd-rfkill invocation结束时被清除，而不只是跨boot/resume不持久；这是per-invocation finalizer的显式、可测结果。它不改变Caelestia的BlueZ `Powered` off/on语义，也不触碰WLAN/hard block。
- Rollback可单独移除drop-in与ordinary udev target，并停止独立helper；无需恢复stock Blueman或修改pairing/QML组件（`:455-462`）。
- 新增isolated-systemd/socket fixture直接验证最后一个高风险ordering，不属于无关功能扩张。

未发现新的contract偏移或scope creep。

## Implementation gates

### Pre-deploy

1. **Generated unit**：四台ordinary host的effective `systemd-rfkill.service`保留vendor ExecStart/socket/timeout，`ExecStopPost` list恰好只有finalizer一条且无`-`；pinned upstream若新增command则build fail并重新审RFC。Ramen list为空且units保持masked。
2. **Finalizer unit tests**：覆盖no-device、already-unblocked、单/多Bluetooth entry、hard+soft组合、entry add/remove race和command/verification failure；只允许Bluetooth type write，无poll/sleep/systemctl/runtime path injection。
3. **Per-invocation fixture**：使用真实isolated systemd/socket覆盖normal exit、held-ADD old-exit→reactivation、explicit restart、startup/runtime failure、shutdown stop、三次ADD/CHANGE、no-device、no-op与finalizer failure；逐InvocationID证明新main不跨越旧ExecStopPost，最终soft=0或明确failed。
4. **WLAN invariant**：每个rfkill case逐位比较WLAN live value、persisted bytes/hash及write log；任何finalizer WLAN访问/变化阻塞。
5. **TLP boundary**：Ramen无drop-in/ordinary rule/systemd-rfkill依赖；resume helper晚于TLP resume，boot/add/resume三条helper路径都只写Bluetooth，TLP与WLAN前后不变。
6. **Runner lifecycle**：c1/hlissner unit verify、GTK失败零system-bus动作、同connection identity、partial failures、Release/name vanish/reappear、signals与connection-close tests通过；READY只在default。
7. **Privacy**：七个interaction入口/五个notification call site全覆盖；upstream factory/bubble/desktop Notify为0；Caelestia list与`notifs.json` bytes/hash不变；stdout/stderr/journal无sentinel。
8. **Surface/package**：runner output allowlist和private-runtime boundary通过；stock applet/manager/tray/mechanism、Rofi入口及Hyprland rule为零。
9. **QML**：同源policy fixture、installed source hash、installed `Bluetooth.qml`调用及pairing-page invariant通过。
10. **Host/build**：五主机Bluetooth专项eval和相关derivation、synthetic non-Caelestia boundary、Axiom完整toplevel通过；无关pnpm/Godot failure仅记baseline。

### Deploy

1. **Axiom**：真实/测试pairing、Release、BlueZ restart、late MediaTek rebind、systemd-rfkill InvocationID/ExecStopPost链、reboot及两次resume通过；Bluetooth最终soft=0，WLAN sentinel和notification state不变。
2. **Ramen**：确认TLP与masked systemd-rfkill配置不变、无drop-in、helper晚于`tlp resume`且WLAN逐位不变。
3. **其余hosts**：agent default、无旧surface、ordinary finalizer effective且Bluetooth soft=0；无法自然覆盖的Agent1交互记录为residual。
4. 任一invocation缺少finalizer、自激loop、finalizer/WLAN越界、TLP unit被load、敏感值进入notification/state/journal、stock activation残留或新增Bluetooth build failure，均阻塞发布并按组件rollback。

## Return condition

**PASS**：RFC design gate已通过。交回`legion-workflow`进入实现；上述pre-deploy与deploy gates为发布硬条件，不得在实现阶段弱化。

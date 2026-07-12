# RFC Re-review：全局 Caelestia-only 蓝牙控制面（Revision 5）

## 结论：PASS

Revision 5 的shared TLP projection关闭了production boot cycle，同时保留独立的boot、per-device ADD与post-resume收敛点。`tlp.service Wants=bluetooth-rfkill-unblock.service`只负责把base helper拉入同一transaction；helper的`After=tlp.service`负责ordering。由于TLP base helper不再由`multi-user.target`直接Wants，旧的target默认`After=helper`回边消失。Pinned TLP显式`After=multi-user.target`又使systemd抑制target对TLP的相反默认ordering，因此有效启动链为`multi-user.target → tlp.service → helper`，无环。

成功或失败的TLP init都会先结束其start job，随后helper才可启动；weak `Wants`使两者failure result相互独立，helper成功不能掩盖TLP失败，helper失败也不改变TLP result。TLP ADD template按monotonic `rfkillN`建立独立unit identity，避免与base或其他device ADD job合并；instance不进入root command。Resume恢复既有sleep/post-resume chain，masked systemd-rfkill及WLAN边界不变。Faithful full-target VM与实际Ramen generated-tree diagnostic gate能够捕获vendor graph漂移及systemd返回0但删除job的cycle诊断。

Revision 4 ordinary finalizer以及lifecycle、package/surface、privacy、QML和host/build边界均未回归。未发现新的blocking complexity、rollback gap或scope creep；可交回`legion-workflow`实施。

## TLP boot graph

### Cycle-free证明

生成关系为：

```text
multi-user.target --Wants--> tlp.service --Wants--> bluetooth-rfkill-unblock.service
multi-user.target --Before--> tlp.service --Before--> bluetooth-rfkill-unblock.service
```

- Pinned `tlp.service`保留`WantedBy=multi-user.target`与`After=multi-user.target NetworkManager.service`，且为`Type=oneshot`、`RemainAfterExit=yes`。
- Pinned systemd `target.c:35-60`与`unit.c:1473-1497`只会为target requirement增加默认ordering；发现被依赖unit已显式`After=target`时，不添加相反的`target After unit`，避免制造loop。
- TLP branch的base helper明确`WantedBy=[]`，所以`multi-user.target.wants/`没有helper symlink，也不会产生旧graph中的`multi-user.target After helper`。
- `Wants=`自身不增加ordering。TLP对helper的weak Wants只创建start job，helper的单向`After=tlp.service`才形成TLP→helper顺序。
- helper的普通service default dependencies只增加sysinit/basic/shutdown边，不会隐式创建`Before=multi-user.target`。

因此vendor `multi-user After`不是新cycle来源；它正是成功顺序中target先于TLP的edge。不得恢复helper的multi-user WantedBy、host-specific Ramen override或任何反向target link。

### 成功与失败语义

Pinned systemd `systemd.unit.xml:643-662,818-845`给出以下结果：

- **TLP init成功**：oneshot `ExecStart=tlp init start`退出0、TLP达到active/exited并完成start job后，helper才开始。
- **TLP init失败/超时**：service startup在命令失败或报告成功时都被视为ordering已完成；helper仍在其后启动。`Wants`不会像`Requires+After`一样因TLP失败取消helper。
- **helper失败**：TLP的weak Wants不传播helper failure，TLP保持其自身result；helper unit独立failed。
- **release解释**：必须分别检查TLP result与helper InvocationID/result。helper清除Bluetooth不等于TLP init通过，TLP成功也不等于helper执行过。

这允许TLP partial/failed init停止写radio后仍做Bluetooth-only fail-safe finalization，同时保留真实TLP failure。实现gate必须覆盖TLP init成功和失败两个transaction，不能只从成功boot推断weak-dependency语义。

## Per-device ADD template

- TLP udev rule只在`ACTION=add`、`SUBSYSTEM=rfkill`、`type=bluetooth`时生成`bluetooth-rfkill-unblock@%k.service`，并保留`TAG+="systemd"`。
- Pinned udev的`%k`是device kernel name；Linux 6.12.93 `rfkill_register()`以单调递增`rfkill_no`生成`rfkillN`（`net/rfkill/core.c:1074-1094`）。每个device ADD因此得到不同template instance；re-add也获得新name。
- Base unit与任一`@rfkillN`、不同`@rfkillN/@rfkillM`都是不同systemd unit/job，不能因base正在activating或另一个ADD正在处理而合并。
- 即使重复event被同instance合并，finalizer仍扫描全部Bluetooth entries；不过正常rfkill ADD identity本身已经按device唯一。
- `%I`只允许出现在unit identity及可选Description。Effective template `ExecStart`必须是单一argv、逐字等于immutable finalizer store path；不得含`%i/%I`、shell、参数、instance-derived Environment/EnvironmentFile或动态路径。finalizer不读取instance并扫描全部Bluetooth entries。

实现fixture必须同时hold base并创建至少两个rfkill devices，观察base、`@rfkillN`、`@rfkillM`三个不同job/InvocationID；只证明base+一个template不同还不足以覆盖per-device coalescing claim。

## Resume ordering

Revision 5正确删除`tlp-sleep.postStop`等额外hook，并恢复NixOS `post-resume.service`中的nonblocking base restart：

```text
tlp-sleep.service Before sleep.target
systemd-suspend.service After sleep.target
suspend.target After systemd-suspend.service
post-resume.service After suspend.target
```

这给`tlp-sleep.service`与`post-resume.service`建立传递ordering。Resume阶段前者是stop job、后者是start job；pinned systemd对一停一启的ordered units总是先完成stop。因此`tlp-sleep.service ExecStop=tlp resume`（含`restore_device_states`）完成或失败终止后，post-resume service才执行`systemctl --no-block restart bluetooth-rfkill-unblock.service`。

- Boot不使用nested `systemctl`，只使用declarative Wants/After。
- Resume中的`systemctl --no-block`只校验并enqueue新base restart，不同步等待manager，也不在TLP ExecStartPost内形成自锁。
- `restart`确保已有base job不会被当作本次resume证据；release gate必须等待新的InvocationID并单独检查TLP resume result。
- Resume期间的early ADD template不能替代post-resume base；late ADD又有独立template，所以TLP restore后仍有确定的finalization。

Faithful VM必须走实际sleep/suspend/post-resume unit edges并分别覆盖successful/failed `tlp resume` ordering；test不得直接start helper或以test-only tlp-sleep hook伪造顺序。

## systemd-rfkill、WLAN与权限边界

- TLP branch不生成ordinary `systemd-rfkill.service` ExecStopPost/drop-in，base/template/TLP Wants/udev/resume也不得引用service/socket。
- Ramen的stock systemd-rfkill service/socket继续由NixOS TLP module disabled/masked；static unit audit和runtime InvocationID必须均为零。
- Base和template只调用同一无参数finalizer：枚举`type=bluetooth`，仅在soft=1时执行一次`rfkill unblock bluetooth`，随后验证；不使用`unblock all`，不读写WLAN persisted state或radio，不修改hard block。
- TLP init/resume本身的result与配置单独观察；WLAN live soft/hard、persisted bytes/hash及TLP state必须在boot/add/resume gate中保持预期且无helper写入。

## Faithful full-target verification

Revision 5的VM设计足以防止Revision 4 fixture再次错误PASS，但实现必须保留以下真实性条件：

1. 从pinned `pkgs.tlp`派生test package时只替换`tlp`可执行行为（实际路径`sbin/tlp`）；vendor `tlp.service`/`tlp-sleep.service`及其`After=multi-user.target NetworkManager.service`、Type、RemainAfterExit和enablement不得重写。
2. TLP/base/template/udev/resume均来自同一production projection factory；fixture只能append测试依赖，不能替换production ordering edge。
3. VM由默认boot启动完整`multi-user.target` transaction，不能手工start boot helper。
4. 使用pinned systemd与完整generated unit path执行`systemd-analyze verify multi-user.target`；同时检查exit status及C-locale stdout/stderr。任何case-insensitive `ordering cycle`、`Found ... cycle`、`deleted to break ordering cycle`诊断都失败，即使status=0。
5. PID 1 boot journal重复相同negative scan，并证明TLP init-end严格早于base InvocationID/finalizer。
6. 运行TLP init success与non-zero/timeout variants，证明helper分别在TLP start job完成后启动且两个result独立。
7. 运行base+两个template concurrent jobs、实际post-resume success/failure、mask/InvocationID及WLAN byte/hash gates。
8. 从实际Ramen专项eval导出的relevant production tree运行同一full-target diagnostic scan；VM projection与host projection任一不一致即失败。

注：RFC中的“只替换`sbin/tlp`”是可实现方向；实现审计应按实际store path比较vendor unit内容，避免测试package无意重写unit。任何为便于fixture而删除vendor multi-user edge的做法直接阻塞。

## 已PASS区域回归检查

| 区域 | 结论 | Revision 5状态 |
|---|---|---|
| Ordinary per-invocation finalizer | **INTACT** | 四台ordinary host继续使用Revision 4 ExecStopPost及socket-reactivation fixture；TLP projection不改变该分支。 |
| Agent/GTK lifecycle | **INTACT** | graphical-session readiness、单connection、四状态与Release/name-vanish/failure cleanup未变。 |
| Package/surface | **INTACT** | private Blueman runtime、runner allowlist及stock applet/manager/tray/mechanism/Rofi删除边界未放宽。 |
| Pairing privacy | **INTACT** | 七个interaction入口、local-only dialog及Notify/Caelestia/journal负向gate未变。 |
| Caelestia QML | **INTACT** | 同源policy、installed hash、wiring和pairing-page invariant未变。 |
| Host/build scope | **INTACT** | 五主机专项eval、synthetic non-Caelestia、Axiom full build与pnpm/Godot baseline边界未变；新增TLP VM只覆盖已发现的production graph风险。 |

未发现新的contract偏移或scope creep。Per-device template与faithful VM都是对真实job coalescing和错误测试投影的最小修复；没有新增daemon、poller、GUI、global rfkill policy或host特判。

## Implementation gates

### Static/generated graph

1. Ramen/TLP base helper：`WantedBy=[]`，无`multi-user.target.wants/`symlink；effective `After`包含且只在TLP branch包含`tlp.service`。
2. Effective `tlp.service`保留vendor ExecStart、`After=multi-user.target NetworkManager.service`、`Type=oneshot`、`RemainAfterExit=yes`及multi-user enablement，并新增`Wants=bluetooth-rfkill-unblock.service`；不得新增Requires/PartOf或Bluetooth ExecStartPost。
3. TLP template只在TLP branch存在；effective ExecStart单一argv严格等于finalizer store path，所有command/environment字段均不含`%i/%I`或instance-derived input。
4. Generated udev精确匹配Bluetooth rfkill add、带systemd tag并target `@%k`; ordinary rule仍target stock systemd-rfkill。
5. `tlp-sleep.service`无Bluetooth drop-in/postStop/After/PartOf；post-resume保留唯一`systemctl --no-block restart` base trigger，无同步nested systemctl。
6. TLP branch的systemd-rfkill service/socket保持masked、无drop-in、无任何helper dependency；ordinary Revision 4 graph逐项不变。

### TLP full-target VM

1. 保留pinned vendor units并使用production projection；full `multi-user.target` verify的status和diagnostic text均通过，PID 1 journal无cycle/job-deletion。
2. TLP init success：`init-end < base-start`，TLP和base均成功且有独立InvocationID。
3. TLP init failure/timeout：`init-failure-end < base-start`；TLP保持failed，base仍运行并独立报告result，任何一项失败均阻塞release。
4. Hold base后创建两个distinct rfkill devices：base、两个`@rfkillN`instance同时可见且三个InvocationID不同；释放后Bluetooth soft=0。
5. Assert template ExecStart argv/environment不含instance；恶意手工instance名也不得改变command或finalizer输入。
6. Post-resume success与TLP-resume failure variants均走真实unit graph；每次严格记录`tlp resume end → post-resume trigger → new base InvocationID`，并分别保留TLP/helper result。
7. No-device/already-unblocked零写；helper failure可见且后续invocation可恢复。
8. 全程stock systemd-rfkill无InvocationID，WLAN live/persisted bytes/hash、hard state与TLP配置/state无helper导致的变化。
9. 实际Ramen relevant unit tree运行同一full-target verify/diagnostic scan；与VM production projection做结构比较。

### Previously approved gates

1. Ordinary ExecStopPost normal/failure/restart/shutdown/reactivation/no-device fixture继续通过。
2. Auth runner lifecycle/private-D-Bus、c1/hlissner generated unit与READY gate继续通过。
3. 七个pairing interaction的desktop Notify、Caelestia list/`notifs.json`及journal sentinel gate继续通过。
4. Runner/private-runtime surface audit、Rofi/Hyprland removal及migration checks继续通过。
5. Caelestia同源QML policy、installed hash/wiring及pairing-page invariant继续通过。
6. 五主机专项eval/相关derivation、synthetic non-Caelestia与Axiom完整toplevel继续通过；无关pnpm/Godot只记baseline。

### Deploy

1. Ramen reboot journal证明无cycle诊断、TLP init完成后出现base InvocationID，Bluetooth soft=0；不得靠ADD偶然补救boot gate。
2. Ramen至少制造两个distinct tagged rfkill ADD并观察不同template InvocationID；base overlap场景不合并。
3. Ramen suspend/resume两次，严格证明`tlp resume`完成后post-resume enqueue新的base InvocationID；无tlp-sleep Bluetooth hook。
4. Ramen全过程systemd-rfkill保持masked/inactive、WLAN live/persisted与TLP state不变，helper只写Bluetooth。
5. Axiom及其余previously approved deploy gates保持：ordinary finalizer、agent/default、privacy、surface、reboot/resume与QML smoke不得回归。

## Return condition

**PASS**：Revision 5 design gate通过。交回`legion-workflow`实施；以上TLP success/failure、multi-instance、full-target diagnostics与previously approved gates均为发布硬条件。

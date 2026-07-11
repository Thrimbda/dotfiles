# Research：全局收敛到 Caelestia 蓝牙控制面

> **RFC 档位**：Heavy
> **修订**：2026-07-12，Revision 4；只替换普通主机 rfkill final-writer，保留已关闭 privacy 等边界
> **用途**：给 RFC 复审和实现者提供可追溯事实；不修改 `plan.md` 契约。

## 1. 调研结论

- stock `blueman-applet` 无法裁成严格的“仅 AuthAgent”：2.4.6 没有插件 CLI allowlist，且三个基础 UI/API 插件不可卸载。
- 最小可见面不是重做一个“裁剪版 Blueman derivation”，而是：**完整 Blueman 只作为私有 Nix store Python/runtime library；另建只有一个公共命令的 runner package**。只要前者不进入任何 profile、D-Bus/systemd package 集合或会话 XDG 路径，其 desktop/unit/mechanism 文件就是不可发现的闭包内容。
- runner 仍有必要：Quickshell 没有 Agent1；stock applet 会加载 PowerManager/KillSwitch。runner 的边界限于 GTK readiness、安全日志/通知适配、单连接 Agent1 状态机，不复制配对协议或 UI。
- user service 必须同时 `WantedBy/PartOf/After=graphical-session.target`。UWSM 在该 target 前完成 `WAYLAND_DISPLAY` 等环境同步；显式 `After` 不会与 `WantedBy` 形成 ordering cycle。
- Agent1 注册的 sender identity 是 system-bus unique name。对象导出、`RegisterAgent`、`RequestDefaultAgent`、`UnregisterAgent` 必须使用同一条持续存活的 `Gio.DBusConnection`，并对 Release、name vanish、部分失败和信号做逆序幂等清理。
- 普通主机不再猜测某次ADD属于哪个active instance：给`systemd-rfkill.service`追加唯一的`ExecStopPost`，每个正常、失败、restart或socket-reactivated invocation结束后都运行同一个Bluetooth-only idempotent finalizer。TLP主机不生成该drop-in，继续独立处理boot/add/resume。
- 五主机完整构建不是稳定 contract，且当前四台有无关基线失败。正确 gate 是五主机 Bluetooth 专项 eval/assertion + 相关 derivation build、Axiom 完整 toplevel、synthetic non-Caelestia boundary，以及部署后的硬件 gate。
- Pinned Blueman 会在 INFO 日志写明文 passkey/PIN 和含 MAC 的 object path；其 notification body 还会被 Caelestia 写入 `notifs.json`。runner 必须压低日志，并把所有 pairing notification 调用直接绑定到本地 `_NotificationDialog`，完全绕开 desktop notification daemon。

## 2. 当前仓库与主机边界

### 2.1 生产入口

| 路径 | 当前职责 | 证据 |
|---|---|---|
| `modules/profiles/hardware/bluetooth.nix` | BlueZ、stock Blueman、resume rfkill | profile `:9`；BlueZ `:10-22`；Blueman `:25-32`；block/unblock `:34-39` |
| `modules/desktop/apps/rofi.nix` | Rofi Bluetooth desktop item | `:73-80`；desktop item 工厂见 `lib/pkgs.nix:28-40` |
| `modules/desktop/caelestia.nix` | pinned shell package 与 session XDG | package `:36-43`；package data dirs `:130-135`；session 注入 `:231-237` |
| `modules/desktop/hyprland.nix` | Hyprland/UWSM、Caelestia 默认、遗留 Blueman rule | UWSM `:443-468`；session startup `:541-570`；Blueman rule `:678-679` |
| `default.nix`、`modules/home.nix` | 单主用户与受限 HM 适配 | `config.user` alias：`default.nix:16-18,46-55`；HM：`modules/home.nix:101-128` |

### 2.2 五台 Bluetooth 主机

| 主机 | 用户 | Caelestia | Rofi | TLP | 当前完整 drvPath 基线（2026-07-11） |
|---|---|---:|---:|---:|---|
| `axiom` | `c1` | 是 | 否 | 否 | PASS |
| `azar` | `c1` | 是 | 是 | 否 | FAIL：无关 `pnpm-10.29.2` insecure |
| `harusame` | `hlissner` | 是 | 是 | 否 | FAIL：无关 `godot_4-export-templates` rename |
| `ramen` | `hlissner` | 是 | 是 | **是** | FAIL：无关 `pnpm-10.29.2` insecure |
| `udon` | `hlissner` | 是 | 是 | 否 | FAIL：无关 `godot_4-export-templates` rename |

Bluetooth profile 声明见 `hosts/axiom/default.nix:19-31`、`azar:15-27`、`harusame:18-30`、`ramen:19-30`、`udon:14-27`。五台当前都因 `modules/desktop/hyprland.nix:468` 有效启用 Caelestia，但共享 profile 不能依赖这个偶然现状。

Ramen 导入 Dell XPS hardware profile（`hosts/ramen/default.nix:10-12`），并明确说明 TLP 由该 profile 启用（`:100-113`）；只读求值确认 `services.tlp.enable=true`，其他四台为 false。

仓库没有实体 “Bluetooth=true、Caelestia=false” 主机。该边界必须用 `axiom.extendModules` 强制 `caelestia=false` 验证。

## 3. 图形会话 readiness

### 3.1 UWSM 的同步点

Pinned UWSM 为 0.24.3：

- `wayland-session-waitenv.service:1-19` 在 `graphical-session.target` **之前**等待 `WAYLAND_DISPLAY` 等环境，超时 30 秒；
- `wayland-session@.target:4-9` Wants waitenv，且 `Before=graphical-session.target`；
- UWSM 示例 `swayidle.service:1-19` 同时使用 `After=graphical-session.target` 与 `WantedBy=graphical-session.target`。

因此只排在 `graphical-session-pre.target` 后会与 waitenv 并行，进程不会自动获得之后导入 user manager 的 display 环境。

### 3.2 `After` + `WantedBy` 不成环

Pinned systemd 258.7 `src/core/target.c:35-60` 明确：target 根据 Wants/Requires 增加默认 ordering 前，会检测用户已声明的相反 ordering；存在显式 `service After target` 时不会再添加 `target After service`。`PartOf` 只传播 stop/restart，不增加启动 ordering。

故目标 unit 应同时为：

- `WantedBy=graphical-session.target`；
- `PartOf=graphical-session.target`；
- `After=graphical-session.target`。

### 3.3 GTK 不是 GLib main loop 的隐含能力

Blueman PIN/passkey 路径使用 GTK（`blueman/main/applet/BluezAgent.py:65-95,111-137`）；`setup_icon_path()` 立即读取默认 `Gtk.IconTheme`（`blueman/Functions.py:138-140`）。stock applet 原本通过 `Gtk.Application.run()` 完成初始化（`apps/blueman-applet:39-40`），自定义 GLib runner 没有这层保证。

PyGObject 当前文档/测试对 GTK3 使用 `Gtk.init_check([])[0]`，失败即视为不可运行。runner 需先 `gi.disable_legacy_autoinit()`，再显式 `Gtk.init_check`；失败时不得连接/注册 system-bus agent。

## 4. Blueman 2.4.6：surface、包与插件

### 4.1 stock package 的真实输出

Nixpkgs `b6018f87...` 固定 Blueman 2.4.6（`pkgs/by-name/bl/blueman/package.nix:31-37`），并用 `wrapGAppsHook3` 与 `wrapPythonProgramsIn` 双重包装（`:39-46,90-94`）。当前 package output 包含：

- XDG/desktop：
  - `etc/xdg/autostart/blueman.desktop`
  - `share/applications/blueman-manager.desktop`
  - `share/applications/blueman-adapters.desktop`
  - `share/Thunar/sendto/thunar-sendto-blueman.desktop`
- systemd：
  - `lib/systemd/user/blueman-applet.service`
  - `lib/systemd/user/blueman-manager.service`
  - `share/systemd/user/{blueman-applet,blueman-manager}.service`
  - `lib/systemd/system/blueman-mechanism.service`
- D-Bus：
  - `share/dbus-1/services/org.blueman.{Applet,Manager}.service`
  - `share/dbus-1/system-services/org.blueman.Mechanism.service`
  - `share/dbus-1/system.d/org.blueman.Mechanism.conf`
- public commands：applet、tray、manager、adapters、sendto、services；
- hidden wrappers：例如 `.blueman-applet-wrapped`、`..blueman-applet-wrapped-wrapped`。

上游安装位置见 Blueman `meson.build:211-299,311-314`。因此旧 RFC 的 `share/systemd/user`/`lib/systemd/system` denylist 漏掉了 `lib/systemd/user` 和 `share/dbus-1/system.d`；“bin 只有一个文件”也与正常 wrapper 冲突。

### 4.2 `services.blueman` 为何暴露这些文件

Pinned NixOS module 把 `pkgs.blueman` 同时放入 `environment.systemPackages`、`services.dbus.packages` 和 `systemd.packages`（`nixos/modules/services/desktops/blueman.nix:20-27`）。Axiom 当前因此出现：

- masked `blueman-applet.service`，但 XDG generator 生成并运行 `app-blueman@autostart.service`；
- session names `org.blueman.Applet`、`org.blueman.Tray`，以及可激活 `org.blueman.Manager`；
- system bus 上可激活 `org.blueman.Mechanism`；root `blueman-mechanism.service` 曾被多次激活。

### 4.3 stock applet 不能成为 strict AuthAgent

- CLI 只有 `--loglevel`/`--syslog`（`blueman/Functions.py:263-277`，`apps/blueman-applet:19-40`）。
- applet 创建 `PersistentPluginManager` 并遍历/import 全部插件（`blueman/main/Applet.py:25-64`；`PluginManager.py:78-125`）。
- 默认 `__autoload__=true`（`BasePlugin.py:29-39`）。
- GSettings 不能禁用不可卸载的 `Menu`、`DBusService`、`StandardItems`（`Menu.py:114-125`、`DBusService.py:44-59`、`StandardItems.py:19-37`）。

### 4.4 最小 package 选择

比较两个可行方向：

| 方向 | 复杂度 | 可见/激活面 | 漂移风险 |
|---|---:|---:|---:|
| 从 Blueman derivation 删除所有 surface、改 postFixup | 高；需跟随全部 output/wrapper 变化 | 可做到零 | 高 |
| **完整 Blueman 仅作私有 store library + 独立 runner package** | 低；不改上游 output | 会话中为零；私有闭包内文件不可发现 | 低 |

选择第二种。Nix store closure 的文件不会因“被另一个 derivation 引用”自动进入 PATH、XDG、D-Bus 或 systemd 搜索路径。安全条件是完整 Blueman runtime **绝不**进入 system/user/home package lists、`services.dbus.packages`、`systemd.packages` 或 session XDG；只有 runner 的进程级 `PYTHONPATH`、schema/UI/icon 绝对路径可引用它。

runner package 自身的允许面是：

- 唯一公共、非点号 executable：`bin/blueman-auth-agent`；
- 允许 `wrapGAppsHook3`/`wrapPythonProgramsIn` 产生只指向该 runner 的一层或多层 dot-prefixed wrapper；
- 可有 `nix-support` 元数据；
- 不得有 `etc/**`、`share/applications/**`、`share/dbus-1/**`、`lib/systemd/**`、`share/systemd/**` 或 `libexec/**`。

### 4.5 PowerManager/KillSwitch soft-block 故障链

Pinned 2.4.6 源码能解释已观察到的慢初始化问题：

1. BlueZ name出现后，PowerManager延迟1秒读取adapter（`plugins/applet/PowerManager.py:61-67`）；
2. adapter列表仍空时推导state=false（`:69-75`），并向PowerStateHandler请求false（`:118-129`）；
3. KillSwitch handler调用root mechanism的`SetRfkillState(false)`（`plugins/applet/KillSwitch.py:35-41,138-153`）；
4. mechanism对Bluetooth type写`RFKILL_OP_CHANGE_ALL`、soft=1（`plugins/mechanism/RfKill.py:10-17`）；
5. systemd-rfkill以`StateDirectory=systemd/rfkill`保存radio状态（systemd `systemd-rfkill.service:10-25`），Axiom现有Bluetooth与WLAN独立state文件；
6. 仓库当前resume workaround又主动制造一次block事件（`bluetooth.nix:34-39`），扩大错误中间态被保存的窗口。

移除applet plugin/mechanism切断写入源；Bluetooth-only helper只负责把历史soft block收敛回契约要求的unblocked。

## 5. Agent1 的连接与生命周期事实

### 5.1 sender identity

Pinned BlueZ 5.84：

- Agent1 service 是调用者的 unique name（`doc/org.bluez.Agent.rst:14-30`）；
- `RegisterAgent` 以 D-Bus message sender 为 key 创建 agent（`src/agent.c:964-995`）；
- sender connection 断开会自动移除 agent/default（`:174-188`）。

所以不能用 `busctl` 子进程或另一条 transient connection 注册。对象 export、name-owner watch、Register/Default/Unregister 必须共享一条由 runner 强引用、持续存活的 `Gio.DBusConnection`。

### 5.2 Blueman 对 connection 与 Release 的行为

- `DbusService` 内部通过 `Gio.bus_get_sync` 获得 connection，并用 `_bus.register_object` export（`blueman/main/DbusService.py:27-38,94-129`）。
- `BluezAgent` 构造阶段只登记方法；调用 `register()` 才 export。
- `BluezAgent._on_release()` 只取消 UI 并本地 unexport（`BluezAgent.py:146-150`）。BlueZ 文档明确：收到 Release 时已经从 BlueZ 注销，不能再调用 `UnregisterAgent`（BlueZ Agent docs `:24-30`）。
- `AgentManager.register_agent()` 是无 callback 的异步调用（`blueman/bluez/AgentManager.py:12-17`），不能作为 readiness。

可行的最小适配更简单：完成 GTK 检查后只构造一次本地 `BluezAgent` subclass；`DbusService.__init__` 此时取得 system connection，但尚未 export。runner 立即把该实例的 `_bus` 采纳并强引用为唯一 `system_connection`，不再调用第二次 `bus_get_sync`；后续 name watch、export 和同步 `Gio.DBusConnection.call_sync` 全部使用这个同一对象。该 protected API 依赖必须由 pinned import/state-machine tests 锁住。

## 6. 隐私日志与 local-only pairing UI

### 6.1 上游日志会泄露

Pinned `BluezAgent.py` 在 INFO 级别直接记录：

- `DisplayPasskey (object_path, passkey, entered)`（`:179-180`）；
- `DisplayPinCode (object_path, pin_code)`（`:191-192`）。

BlueZ object path 含设备 MAC。其他 Bluez proxy 在 DEBUG 也会记录 object path（`blueman/bluez/Base.py:63-70`、`Manager.py:39-95`）。因此不能直接开启上游 INFO/DEBUG 后宣称 journal 无敏感值。

安全边界应是：上游 root logger 至少 WARNING；runner 使用独立、`propagate=false` 的 allowlist logger，只写固定 lifecycle/state/request-kind；所有 warning/error 经过 MAC/object-path redaction，runner 不写 exception message/traceback。真实 pairing 日志必须用已知 sentinel 做负向检查。

### 6.2 desktop notification daemon 会持久化 pairing secret

`BluezAgent.py` 在五处调用其模块级 `Notification`（`:134,188,197,215,246`）；body包含设备地址，以及 DisplayPinCode、DisplayPasskey、confirmation 或 authorization内容（`:184-217,237-248`）。上游 `Notification()` factory会读取GSettings、连接session bus，并在daemon支持body/actions时选择`_NotificationBubble`（`blueman/gui/Notification.py:276-305`）。仅清空`icon_name`或设置transient都不会改变这条数据路径。

Pinned Caelestia `services/Notifs.qml` 对每个收到的notification设`tracked=true`（`:83-102`），list变化1秒后把未关闭条目的`body`等字段写到`${Paths.state}/notifs.json`（`:50-72,105-123`）。`Paths.state`是`${XDG_STATE_HOME:-$HOME/.local/state}/caelestia`（`utils/Paths.qml:14-17`）；persistence不检查transient hint。action的`invoke()`也不自动close（`modules/notifications/Notification.qml:478-490`；`modules/sidebar/NotifActionList.qml:135-149`）。所以 Revision 2 的“空icon”仍会把PIN/passkey/MAC送入内存history和磁盘。

### 6.3 精确的 local GTK seam

Pinned `BluezAgent` 在module import时同时取得`Notification`与`_NotificationDialog`（`BluezAgent.py:7-12`）；所有五处调用都在运行时查找该module global。`_NotificationDialog`是纯本地`Gtk.MessageDialog`：构造/action/close路径只操作GTK（`Notification.py:26-118`），不会调用`org.freedesktop.Notifications`。

最小adapter seam是：在构造`PrivateBluezAgent`之前，把**该进程内**`blueman.main.applet.BluezAgent.Notification`替换为签名兼容的`local_notification(...)`；后者直接构造`_NotificationDialog`并传递actions/actions_cb，但绝不调用上游`Notification()` factory或`_NotificationBubble`。这样：

- RequestPinCode/RequestPasskey已有`applet-passkey.ui`保持本地；其附加提示也成为local dialog；
- DisplayPinCode、DisplayPasskey、RequestConfirmation、RequestAuthorization、AuthorizeService全部使用local dialog；
- PIN/passkey/MAC只进入短生命周期GTK widget，不进入desktop daemon、Caelestia list或`notifs.json`；
- `setup_icon_path()`只给本地window解析`blueman` icon，不需要任何Blueman XDG surface。

该seam依赖private class，必须用pinned signature/import test和一个“`_NotificationBubble`构造即失败”的负向fixture锁住；不能用全局dconf、transient hint或Caelestia persistence patch代替。

## 7. rfkill、systemd finalization 与 TLP

### 7.1 为什么 first-inactive barrier 不成立

Linux 6.12.93在`rfkill_register()`中先`device_add()`产生udev add，后向已打开的`/dev/rfkill` fd发送`RFKILL_OP_ADD`（`net/rfkill/core.c:1074-1131`）。若旧systemd-rfkill instance恰在idle expiry退出，helper可以先看到短暂inactive并unblock，随后ADD才让socket启动新instance；新instance再从persisted `1`恢复blocked。任意采样窗口都没有绑定“本次ADD已处理”，所以Revision 3的Wants/After/10秒poll全部删除。

### 7.2 ExecStopPost 是 per-invocation finalizer

Pinned systemd 258.7对`ExecStopPost=`的保证：

- 在service已停止后运行，覆盖自然/意外退出、无`ExecStop`、startup failure（`man/systemd.service.xml:547-569`）；
- restart是stop再start，明确执行`ExecStopPost`（`:537-539`）；
- stop-post计入Before/After ordering（`:568-569`）；同一unit处于`SERVICE_STOP_POST`/deactivating时不会并发进入下一start，source在finalizer结束后才进入dead/auto-restart（`src/core/service.c:2186-2213,4187-4365`）；
- 多条command按解析顺序append（`load-fragment.c:1062-1075`、`execute.c:2193-2204`）。Pinned stock `systemd-rfkill.service`没有现有ExecStopPost，所以合并后list必须**恰好只有本finalizer一条**。若上游以后新增任何ExecStopPost，build fail closed并回到RFC复核；不能假设前置command必成功，也不能用空directive静默删除上游行为。

普通host因此以NixOS `overrideStrategy="asDropin"`条件性扩展现有unit（drop-in生成语义见Nixpkgs `nixos/lib/systemd-lib.nix:440-489`），追加**不带`-`前缀**的`${bluetoothRfkillFinalize}`作为唯一`ExecStopPost`。不修改该unit的enablement、socket、ExecStart、90秒timeout或restore逻辑。normal/error-return路径先由systemd-rfkill cleanup保存queue并关闭fd（`src/rfkill/rfkill.c:255-269`）；signal stop未承诺保存queue，但systemd同样只在main process全部停止后运行finalizer。因此任何main-process radio write都先于finalizer。

### 7.3 finalizer 的最小幂等算法

`${bluetoothRfkillFinalize}`没有systemctl、poll、sleep或event identity：

1. 只枚举`/sys/class/rfkill/*/{type,soft,hard}`中`type=bluetooth`的entry；
2. 无Bluetooth entry：`result=no-device`，零写、exit 0；
3. 全部`soft=0`：`result=already-unblocked`，**不调用rfkill**、exit 0；
4. 任一`soft=1`：只执行一次`rfkill unblock bluetooth`，再验证全部Bluetooth `soft=0`；失败则non-zero；
5. hard block只作无identifier的布尔摘要；永不使用`unblock all`，永不读写WLAN state file或radio。

“already-unblocked不写”避免递归：第一次finalizer若从1写到0，会产生CHANGE并可能让socket启动下一instance；该instance只保存CHANGE，退出后的第二次finalizer看到0即no-op，不再制造event。

### 7.4 每种systemd路径的最终写入

| 路径 | Pinned语义 | Bluetooth最终行为 |
|---|---|---|
| 正常5秒idle退出 | main drain/save后进入ExecStopPost | finalizer最后unblock或no-op |
| 旧instance退出后late ADD触发新instance | 旧finalizer先完成；socket随后start新invocation；新invocation也有同一ExecStopPost | 新restore即使写1，新finalizer仍写回0 |
| explicit restart/reactivation | restart必须完整stop-post后再start | 每个invocation各finalize一次 |
| startup/runtime failure | ExecStopPost仍运行；`SERVICE_RESULT`保留原失败 | 可用时unblock；原failure不被隐藏，finalizer失败也可见 |
| shutdown stop | ExecStopPost仍运行，受stock stop timeout约束 | 有device则Bluetooth-only final write；无device no-op；不延迟到无界 |
| 无Bluetooth device | no-op，不调用rfkill | 不产生socket reactivation |
| 有限重复/并发events | 当前instance退出必finalize；stop-post期间到达的event排队到下一instance，下一instance也finalize | 最后event后5秒退出，最后invocation保证soft=0；queued events drain后，首个看到soft=0的finalizer不再制造event |

这消除了event-specific causal matching：不需要知道某个ADD属于旧或新instance，因为**所有可能执行restore且最终停止的instance都有自己的post-exit finalizer**。无限外部event stream没有“完成的activation”，因此不宣称其间已收敛；显式stop/restart/shutdown仍会进入finalizer。这是可观察的外部持续输入，不靠production polling伪造完成。

### 7.5 ordinary与TLP触发矩阵

共同的简单`bluetooth-rfkill-unblock.service`复用同一finalizer source，只作为boot/resume safety net，不依赖systemd-rfkill。udev rule保持`TAG+="systemd"`，但target按host条件生成：

- ordinary（Axiom/Azar/Harusame/Udon）：late Bluetooth add `SYSTEMD_WANTS=systemd-rfkill.service`；stock socket也可自然activation；每个instance由ExecStopPost收尾。boot/resume safety helper可先或后运行，后续任何restore instance仍会自行finalize。
- TLP（Ramen）：不生成systemd-rfkill drop-in，udev add `SYSTEMD_WANTS=bluetooth-rfkill-unblock.service`；boot `WantedBy=multi-user.target`、resume仍由`post-resume.service`启动该helper。

Pinned NixOS TLP module继续mask `systemd-rfkill.service/socket`（`nixos/modules/services/hardware/tlp.nix:109-120`）。TLP `tlp-sleep.service` stop时运行`tlp resume`/`restore_device_states`（TLP `sbin/tlp:430-468`），NixOS `post-resume.service After=suspend.target`之后才执行`resumeCommands`（`power-management.nix:65-97`）；所以Ramen helper晚于TLP restore。没有drop-in、Wants/After或unmask，WLAN/TLP语义不变。

### 7.6 deterministic adversarial fixture

Fixture使用真实isolated systemd manager和socket-reactivated fake systemd-rfkill unit，复用同一finalizer source。预置Bluetooth persisted/live=1与WLAN live/persisted唯一sentinel。必须覆盖：

1. normal ADD restore→main exit→finalizer 0；
2. **旧instance接近idle expiry；Bluetooth sysfs entry/udev先可见，但fixture把匹配ADD投递hold到old ExecStopPost完成后**；随后socket启动新instance，断言其restore 1后自己的ExecStopPost再写0；
3. explicit restart、startup failure、runtime failure、shutdown stop；
4. no-Bluetooth与already-unblocked路径的rfkill write count=0；
5. repeated ADD/CHANGE/reactivation最终静默，且每个invocation恰有一个finalizer completion record。

每个有Bluetooth entry的invocation都断言soft=0于finalizer完成时成立；no-device case断言零写；WLAN live value、persisted bytes/hash全程逐位不变。测试还必须确认普通unit的ExecStopPost list恰好只有本finalizer，Ramen unit没有该drop-in且从不加载masked systemd-rfkill。

## 8. Caelestia 名称策略与可重复测试

- Quickshell `BluetoothAdapter.enabled` 直接绑定BlueZ `Powered`，blocked状态拒绝enable（`src/bluetooth/adapter.hpp:62-67,159-167`；`adapter.cpp:53-63`）。
- Quickshell Bluetooth实现没有Agent1/AgentManager/RegisterAgent；Caelestia pairing只调用device `Pair`，所以外部default agent不可省略。
- Quickshell `address`、`deviceName`、`name` 分别绑定 BlueZ Address、Name、Alias（`src/bluetooth/device.hpp:190-211`）。
- 当前 popout 对全部设备排序后 `slice(0,5)`（Caelestia `modules/bar/popouts/Bluetooth.qml:63-66`）。
- pairing page 只过滤 `!bonded`、不 slice，并显示 address（`BluetoothPairing.qml:65-78,140-151`）。
- Caelestia build 只复制 QML 目录，不编译/lint policy（`CMakeLists.txt:62-72`）。仅“package build 成功”不能证明排序。

为避免实现与测试复制两套逻辑，应把纯 policy 放在一个普通 QML-compatible JS 文件中，Bluetooth.qml import 同一文件；Nix test 用 Node `vm` 加载该文件和 fixture。fixture 至少覆盖：

- `Name` 非空；
- 自定义 Alias；Alias 与 Address 大小写不同但等价；
- 空串/纯空白；
- anonymous connected、paired、bonded；
- connected > paired/bonded > named 的排序；
- address tie-break；
- 超过五项截断；
- 输入数组不被修改。

另做静态断言：`BluetoothPairing.qml` 不 import primary policy、不调用 slice/名称过滤，仍保留 `!bonded` 模型。

## 9. 验证基线与剩余硬件风险

稳定 plan 要求多主机求值与 Axiom 构建，不要求修复四台主机的无关 package baseline。因此：

- 五主机必须完成只触达 Bluetooth/user/Caelestia/TLP/unit 属性的专项 eval/assertion；
- 构建 runner、rfkill helper/unit、patched Caelestia、QML policy test 等相关 derivation；
- Axiom 完整 toplevel build；
- synthetic non-Caelestia boundary 求值和相关 derivation build；
- broad `drvPath`/flake check 的 pnpm/Godot 失败记录为 pre-existing baseline，不在本任务修复，也不伪报 PASS。

只能部署后取得的证据：真实 PIN/passkey pairing、Axiom MediaTek reboot/resume、BlueZ stop/start、c1/hlissner 实际进程环境、Ramen TLP/WLAN 状态。一个设备不能覆盖所有 Agent1 方法，未覆盖交互要记录 residual risk。

## 10. 证据索引

- 契约：`../plan.md`
- 失败复审：`review-rfc.md`
- 本仓库：
  - `modules/profiles/hardware/bluetooth.nix`
  - `modules/desktop/apps/rofi.nix`
  - `modules/desktop/caelestia.nix`
  - `modules/desktop/hyprland.nix`
  - `hosts/{axiom,azar,harusame,ramen,udon}/default.nix`
- Pinned source：
  - Nixpkgs `b6018f87da91d19d0ab4cf979885689b469cdd41`
  - Blueman `2.4.6`
  - BlueZ `5.84`
  - Linux `6.12.93` rfkill core
  - systemd `258.7`
  - TLP `1.8.0`
  - UWSM `0.24.3`
  - Caelestia shell `4a7773c5ded0699180ef61cdff28b1f2cc5deefb`
  - Quickshell `68c2c85c33845385f7ab8147b32f1450b1e468e0`
- 文档检索：Context7 未收录 Blueman；Blueman/BlueZ 结论来自 pinned source。PyGObject 的 `Gtk.init_check`/Gio API以及systemd `ExecStopPost=`/restart语义已用当前Context7官方文档交叉核对。

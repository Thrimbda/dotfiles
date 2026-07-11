# RFC：全局 Caelestia-only 蓝牙控制面

> **Profile**：RFC Heavy
> **Status**：Ready for re-review（Revision 4）
> **日期**：2026-07-12
> **Contract**：`../plan.md`（保持不变）

## Executive Summary

- **唯一控制面**：所有 Bluetooth 主机移除 stock Blueman 与 Rofi Bluetooth；仅启用 Caelestia 的主机有图形管理界面。
- **配对能力**：保留 pinned Blueman `BluezAgent` 的 PIN/passkey UI，但完整 Blueman package 只作为不可发现的私有 store library；单独 runner package 只有一个公共命令。
- **生命周期**：runner 先验证图形环境与 GTK，再用一条 persistent Gio system-bus connection 完成 export → register → default；所有失败和退出逆序清理。
- **隐私**：上游敏感日志被抑制；runner把Blueman五条pairing notification调用强制绑定到进程内`_NotificationDialog`，不调用desktop notification daemon，不进入Caelestia history/`notifs.json`。
- **启动时序**：user service 同时 `WantedBy/PartOf/After=graphical-session.target`，在 UWSM waitenv 完成后启动；该组合不会形成 ordering cycle。
- **rfkill**：普通主机给每个`systemd-rfkill.service` invocation追加Bluetooth-only `ExecStopPost` finalizer；任一late reactivation都有自己的收尾。TLP主机无drop-in，继续独立boot/add/resume helper。
- **Caelestia**：一个可复用 JS policy 控制主五项，并由确定性 fixture 测试；完整 pairing page 保留匿名设备。
- **验证**：五主机做 Bluetooth 专项 eval/assertion 与相关 derivation build；完整 toplevel 只要求 Axiom；四台无关 pnpm/Godot 基线失败仅记录。
- **部署 gate**：Axiom 真实 pairing/BlueZ restart/reboot/resume；Ramen 验证 TLP 与 WLAN 前后不变；这些不能由静态检查替代。

## 1. Context / Evidence

当前共享 profile 同时启用 BlueZ、stock Blueman 与 resume-time rfkill block/unblock（`modules/profiles/hardware/bluetooth.nix:9-39`）。stock package 的 XDG autostart 生成 `app-blueman@autostart.service`，绕过 `blueman-applet.service` mask；其 PowerManager/KillSwitch 在慢 adapter 初始化时可写入并持久化 Bluetooth soft block。完整源码链见 `research.md` 第4.5节。

Pinned Quickshell 将 `Adapter.enabled` 映射到 BlueZ `Powered`，但 blocked adapter 拒绝 enable；它也没有 Agent1。Caelestia 因此既不能清除 soft block，也不能独立完成需要 PIN/passkey 的 pairing。

Revision 3 已关闭pairing persistence等全部边界，只剩already-active systemd-rfkill在短暂inactive后reactivate的final-writer竞态。本版只把ordinary rfkill设计替换成per-invocation finalizer；其余已通过决策和gate不变。

## 2. Goals

1. Caelestia 是唯一可见 Bluetooth 管理面；non-Caelestia Bluetooth 主机有意地没有 GUI 控制面。
2. 所有 Bluetooth profile 主机保留 BlueZ、CLI 与图形会话配对 agent。
3. agent 空闲时无 tray/menu/manager；不加载 PowerManager、KillSwitch 或其他 applet plugin。
4. 配对 UI 只能在 GTK/display/session bus 确认可用后注册；所有PIN/passkey/confirmation/authorization UI必须是本地GTK dialog，不得进入desktop notification daemon。
5. BlueZ restart、Release、部分注册失败和进程信号后，agent 能恢复或干净退出，不遗留本地 export/远端 registration。
6. boot/device-add/resume 后只清除 Bluetooth soft block；WLAN、hard block、TLP/systemd-rfkill enablement 不变。
7. Caelestia 主五项可重复地优先 connected、paired/bonded、真实名称，匿名广播不挤占；完整 pairing page 仍可用。
8. 验证 gate 与稳定 plan 和当前多主机基线相容。

## 3. Non-goals

- 不删除 BlueZ、`bluetoothctl`、现有 pairing 数据或 Alias。
- 不为 non-Caelestia 主机增加第二个 GUI/TUI。
- 不 fork/重写完整 BlueZ Agent1 协议与 Blueman pairing UI。
- 不把 Caelestia/agent 提权为 root，不恢复 Blueman mechanism/polkit 面。
- 不 mask、force-enable 或全局替代 systemd-rfkill；不改变 Ramen TLP 配置。
- 不修改Caelestia全局notification persistence/history语义；不修复本任务之前存在的 pnpm insecure、Godot rename 或其他无关 flake failure。
- 不根据 MAC/OUI 推断产品名；本任务runner不得把PIN/passkey/MAC/object path写入user journal、desktop notification daemon、Caelestia内存history或`notifs.json`。

## 4. Definitions / Invariants

- **可见 surface**：会话 PATH/XDG 中的 command/desktop/autostart，或已注册的 D-Bus/systemd activation/control UI。
- **私有 store library**：仅被 runner closure/PYTHONPATH/绝对数据路径引用，未链接到任何 profile、D-Bus/systemd package 集合或会话 XDG 的 derivation。
- **公共 executable**：runner output `bin/` 下非点号且可执行的文件；hidden wrapper 可存在但必须只服务该 command。
- **真实名称**：`deviceName.trim()` 非空，或 Alias 非空且大小写无关地不等于 Address。
- **Agent state**：`absent`、`exported`、`registered`、`default`，只能按定义转换。
- **本地 unexport** 与 **远端 UnregisterAgent** 是不同动作；Release/name vanish 时不能混淆。

## 5. Proposed Design

### 5.1 所有权矩阵

| Bluetooth profile | Caelestia | 有效行为 |
|---:|---:|---|
| 否 | 否 | 无本任务 Bluetooth 行为 |
| 否 | 是 | Caelestia 可显示无 adapter；不运行 agent |
| 是 | 否 | BlueZ + CLI + AuthAgent；无 GUI 管理控制面 |
| 是 | 是 | BlueZ + CLI + AuthAgent；Caelestia 是唯一 GUI 管理控制面 |

AuthAgent 的条件只看 Bluetooth profile，不看 Caelestia。

### 5.2 最小 package 形状

#### 5.2.1 选择：私有 Blueman runtime + 独立 runner

```nix
let
  bluemanRuntime = pkgs.blueman.override { withPulseAudio = false; };
  bluemanAuthAgent = pkgs.stdenvNoCC.mkDerivation {
    # 安装唯一 runner 源文件；不复制 bluemanRuntime 的 share/etc/libexec。
    # wrapGAppsHook3 + wrapPythonProgramsIn 只包装该 runner。
    # pythonPath 直接引用 bluemanRuntime 与 pygobject/pycairo。
  };
in {
  # bluemanRuntime 不进入任何 profile、D-Bus/systemd package 集合或 session XDG。
  systemd.user.services.blueman-auth-agent.serviceConfig.ExecStart =
    "${bluemanAuthAgent}/bin/blueman-auth-agent";
}
```

`bluemanRuntime` 保留完整 2.4.6 output，但只作为 Python/UI/schema/icon store dependency。已审计的 stock surface 包括：

- `etc/xdg/autostart/blueman.desktop`、`share/applications/**`、`share/Thunar/sendto/**`；
- `lib/systemd/user/{blueman-applet,blueman-manager}.service` 与 `share/systemd/user/**`；
- `lib/systemd/system/blueman-mechanism.service`；
- `share/dbus-1/services/**`、`share/dbus-1/system-services/**`、`share/dbus-1/system.d/org.blueman.Mechanism.conf`；
- stock public commands及其 dot-prefixed wrappers、`libexec/blueman-mechanism`。

这些路径留在私有 store output，不会自动进入搜索路径。与 Revision 1 的 derivation surgery 相比，此方案：

- 不维护跨版本 output 删除清单或改写 Blueman `postFixup`；
- 不会因新增上游文件而静默暴露，因为完整 runtime 从未被链接；
- runner output 天然没有 stock surface；
- 仍能用 pinned 源码和 import tests 锁住私有 API。

#### 5.2.2 不可违反的链接边界

`bluemanRuntime` 不得出现在：

- `environment.systemPackages`；
- `user.packages` / `users.users.<name>.packages` / `home.packages`；
- `services.dbus.packages`；
- `systemd.packages`；
- `environment.pathsToLink` 或显式 session/Caelestia `XDG_DATA_DIRS`。

仅允许 runner 进程级环境引用：Python site-packages、`${pkgs.glib.getSchemaPath bluemanRuntime}`，以及 Blueman `Constants.py` 已写入的 UI/icon/locale 绝对路径。GApps wrapper 若给 runner 子进程增加私有 data dir，不得传播回 user manager/桌面/Caelestia；client进程的私有 XDG也不会把 descriptor注册进 system/session D-Bus daemon或systemd manager。

#### 5.2.3 runner output allowlist

允许：

- `bin/blueman-auth-agent`：唯一公共、非点号 executable；
- `bin/` 中 basename以`.`开头、由 Python/GApps hook生成且最终只被公共runner链接的 `blueman-auth-agent` wrapper chain（包括双点前缀）；
- `nix-support/**` 等构建元数据，但不得通过 `propagated-user-env-packages` 把 `bluemanRuntime` 或其他 GUI surface 传播到 profile。

禁止 runner output 中出现任何：

- `etc/**`；
- `share/applications/**`、`share/Thunar/**`；
- `share/dbus-1/**`；
- `lib/systemd/**`、`share/systemd/**`；
- `libexec/**`；
- 名称含 `blueman-applet|tray|manager|adapters|sendto|services|mechanism` 的公共或 hidden executable。

构建审计枚举所有 regular file/symlink 和 executable，不只 grep 已知文件名。

### 5.3 runner 的源码与测试边界

生产侧新增的 AuthAgent 源码严格限于 `modules/profiles/hardware/bluetooth-auth-agent.py`；Nix wiring 留在现有 `bluetooth.nix`，不新增第二个 daemon/helper。该 Python 文件只包含三个边界：

1. `RuntimeChecks`：环境、schema、GTK init；
2. `PrivateBluezAgentAdapter`：采纳 `BluezAgent` connection、local export/unexport、安全日志，并把module-level `Notification`固定到local `_NotificationDialog` factory；
3. `AgentStateMachine`：owner watch、四状态与逆序清理。

禁止复制/改写 PIN dialog、confirmation、service authorization 或 Device 逻辑；这些继续来自 pinned `BluezAgent`。adapter只补local factory和幂等`close_ui()`：destroy当前dialog，close并清空单个及service local-dialog列表，best-effort断开`_devhandlerids`后清空；这样name vanish/reuse不会留下旧prompt。它不修改 Blueman source tree，也不修改Caelestia。

测试边界固定为 `modules/profiles/hardware/tests/test-bluetooth-auth-agent.py`，由独立 Nix check 注入 fake connection/fake agent factory，不需真实 Bluetooth：

- 四状态正常路径；
- export/Register/Default 各步失败；
- Release、name vanish/reappear、owner replacement；
- SIGTERM/SIGINT 在每个状态；
- connection closed；
- GTK init failure时零 system-bus动作；
- 同一 connection identity；
- 全部五个notification call site都只构造`_NotificationDialog`，包括共享`ask_passkey()`的RequestPinCode与RequestPasskey；`_NotificationBubble`/desktop `Notify`调用为零；
- PIN/passkey/MAC/object-path 负向日志。

Pinned update gate 还要断言 `Constants.VERSION == 2.4.6`、所用 protected 属性/方法存在、构造后 `_regid is None`、`Notification`/`_NotificationDialog`签名符合预期，并证明 runner 采纳的 connection 就是 export 使用的 `_bus`。

### 5.4 图形会话启动与 GTK readiness

#### 5.4.1 unit ordering

```nix
systemd.user.services.blueman-auth-agent = {
  wantedBy = [ "graphical-session.target" ];
  partOf = [ "graphical-session.target" ];
  after = [ "graphical-session.target" ];
  conflicts = [
    "blueman-applet.service"
    "blueman-manager.service"
    "app-blueman@autostart.service"
  ];
  unitConfig.ConditionUser = config.user.name;
  environment.GSETTINGS_SCHEMA_DIR = pkgs.glib.getSchemaPath bluemanRuntime;
  serviceConfig = {
    Type = "notify";
    NotifyAccess = "main";
    ExecStart = "${bluemanAuthAgent}/bin/blueman-auth-agent";
    Restart = "on-failure";
    RestartSec = 2;
    TimeoutStartSec = 45;
  };
};
```

无 cycle 的理由：`WantedBy` 创建 target Wants service；systemd target 在推导默认 `target After service` 前会看到显式 `service After target`，因冲突而不添加默认 ordering（systemd 258.7 `target.c:35-60`）。UWSM 0.24.3 的 swayidle 示例也使用该组合。

`After=graphical-session.target` 确保 UWSM 的 `wayland-session-waitenv.service` 已完成。`PartOf` 在 session stop/restart 时停止 agent。

#### 5.4.2 runner 启动检查顺序

在创建 system-bus connection 前依次执行：

1. 只检查、不记录值：`XDG_RUNTIME_DIR`、`DBUS_SESSION_BUS_ADDRESS`、`GSETTINGS_SCHEMA_DIR` 存在；`WAYLAND_DISPLAY` 或 `DISPLAY` 至少一个存在；
2. schema path 可读，`Gio.SettingsSchemaSource` 能 lookup `org.blueman.general`；
3. 连接 session bus 成功；
4. 在 import 任何 Blueman/GTK 模块前执行 `gi.disable_legacy_autoinit()`；随后 import GTK3 并执行 `Gtk.init_check([])[0]`；
5. GTK init 成功后才 import Blueman；执行 `setup_icon_path()`，并断言默认 theme 能 lookup `blueman` icon；
6. 全部通过才连接 system bus、watch BlueZ、export Agent1。

任一步失败只记录 `event=startup_check result=failed stage=<allowlisted-stage>`，不记录环境值/异常文本，非零退出。`Type=notify` 只在 state=`default` 后 READY；不存在“GTK 不可用但 unit 假健康”。

### 5.5 单 connection Agent1 状态机

#### 5.5.1 connection invariant

启动检查通过后只构造一次 `PrivateBluezAgent`。其 `DbusService.__init__` 调用 `Gio.bus_get_sync(Gio.BusType.SYSTEM)`，但构造阶段尚未 export；runner 立即把实例的 `_bus` 采纳并强引用为唯一 `system_connection`，不再取得第二条 system connection。该同一对象完成：

- `NameOwnerChanged` subscribe 与初始 owner query；
- Agent1 object export/unexport；
- `RegisterAgent`；
- `RequestDefaultAgent`；
- `UnregisterAgent`。

不得调用上游异步 `BluezAgent.register_agent()`/`unregister_agent()`，也不得用 `busctl`/helper process、`new_for_bus_sync` 或第二条 connection执行上述所有权操作；只使用`DbusService.register()`/`unregister()`做local export。固定 object path 为 `/org/bluez/agent/blueman`；先取得并保存 `org.bluez` 当前 unique owner，随后以 policy允许的 well-known destination `org.bluez`，在 `/org/bluez` 的 `org.bluez.AgentManager1` 上调用 `RegisterAgent (os)`、`RequestDefaultAgent (o)`、`UnregisterAgent (o)`。每次 call前后都重查并比较 unique owner；owner 已替换则按 vanish清理，不把新旧 daemon混为一个registration。

测试必须比较对象 identity/unique name，证明 local export 与三个 AgentManager1 call 的 sender 完全相同。BluezAgent 在处理设备时创建的 Device proxy 不参与注册所有权，不得替代 `system_connection`。

所有 transition 在同一 GLib main context 串行执行；Unix signal source只排队 cleanup，不与同步 D-Bus call 并发。每个同步 call 有 5 秒 timeout，禁止无限等待。

#### 5.5.2 状态定义

| 状态 | 本地 object 已 export | BlueZ registered | default |
|---|---:|---:|---:|
| `absent` | 否 | 否 | 否 |
| `exported` | 是 | 否 | 否 |
| `registered` | 是 | 是 | 否 |
| `default` | 是 | 是 | 是 |

受控 cleanup严格逆序：`default`/`registered` 在 owner仍相同时先调用一次远端 `UnregisterAgent`（该动作同时撤销default），再 local unexport；`exported` 只 local unexport；`absent` no-op。Release、name vanish和closed connection使用第5.5.5节的特例，不调用不再有效的远端。

#### 5.5.3 正常路径

1. BlueZ owner 出现且 state=`absent`；
2. 使用启动时已创建但尚未 export 的 adapter，在其 `system_connection` 上 local `register_object` → `exported`；
3. 同一 connection `RegisterAgent(path, "KeyboardDisplay")` 成功 → `registered`；
4. 同一 connection `RequestDefaultAgent(path)` 成功 → `default`；
5. 记录固定 state transition，并 `sd_notify READY=1/STATUS=default`。

BlueZ 已存在时通过初始 `GetNameOwner` 走同一路径；owner replacement 等价于旧 owner vanish 后新 owner appear。

#### 5.5.4 部分失败的逆序清理

- export 失败：保持 adapter 未 export、无远端调用，非零退出以新进程/connection重试。
- Register 失败：local unexport，回 `absent`。
- RequestDefault 失败：若 owner 仍相同，先同步 `UnregisterAgent`；无论结果如何再 local unexport，回 `absent`。
- 清理后 owner 仍存在：非零退出，由 systemd 重启；owner 已消失：保持 `absent` 等待新 owner。
- cleanup 的每一步带幂等 guard；第二次调用是 no-op。

#### 5.5.5 Release、name vanish 与信号

- **Agent1 Release**：local subclass 覆盖 `_on_release`，执行幂等`close_ui()`并 local unexport；**不调用远端 UnregisterAgent**，因为 BlueZ 已注销。若当前 owner 仍是原 owner，视为异常并非零退出；若 owner 已消失，回 `absent` 等待。
- **name vanish/crash**：先清空 owner，再执行`close_ui()`、local unexport、清空状态；不调用已消失的 BlueZ。后续 name appear 从 `absent` 重建，避免 object-path registration conflict。
- **SIGTERM/SIGINT**：停止新 transition；若 state 为 registered/default 且 owner 仍相同，先同步 Unregister；然后`close_ui()`、local unexport、unsubscribe，退出 0。任何远端失败都不能阻止本地清理。
- **system connection closed**：连接断开已让 BlueZ 自动移除 sender；只做本地 best-effort cleanup，非零退出让 systemd 创建全新 connection。

### 5.6 安全日志与 local-only pairing UI

#### 5.6.1 日志

- 在 import Blueman 前配置唯一 root handler并把 root level设为 WARNING，抑制上游 `BluezAgent` INFO/DEBUG，包括明文 DisplayPasskey/DisplayPinCode；顶层与 GLib callback边界捕获异常，禁止未过滤 traceback落到 stderr。
- runner 使用独立 `blueman_auth_agent` logger，`propagate=false`，唯一允许字段为：
  - `event=startup_check|bluez_owner|state|request|cleanup|error`
  - `state/from/to/reason/stage/kind/result`
  - exception **class name**，不含 `str(exception)`/traceback。
- local subclass 包装 Agent1 handlers，只记录无参数 request kind，再调用上游逻辑。
- 所有 WARNING/ERROR handler 加最后一道 filter：重建 allowlisted message，清空 `record.args`、`exc_info`、`exc_text`、`stack_info`，并删除 BlueZ object-path、MAC 格式和疑似 PIN/passkey token；不输出 D-Bus payload或 traceback。
- 不启用 Blueman `--syslog` 或额外 handler。

#### 5.6.2 精确adapter seam

Pinned `blueman.main.applet.BluezAgent`把`Notification`作为module global导入，五条pairing路径都在运行时查找它。runner在构造agent前执行等价于以下的进程内适配：

```python
from blueman.gui.Notification import _NotificationDialog
import blueman.main.applet.BluezAgent as bluez_agent_module

def local_notification(summary, message, timeout=-1, transient=False,
                       actions=None, actions_cb=None, icon_name=None,
                       image_data=None):
    return _NotificationDialog(
        summary, message, timeout, transient,
        actions, actions_cb, "blueman", image_data,
    )

bluez_agent_module.Notification = local_notification
```

硬约束：

- `local_notification`不得调用上游`Notification()` factory、`_NotificationBubble`、`Gio.DBusProxy`或`org.freedesktop.Notifications.Notify`；
- RequestPinCode/RequestPasskey已有`applet-passkey.ui`保持不变，其附加提示走local dialog；
- DisplayPinCode、DisplayPasskey、RequestConfirmation、RequestAuthorization和AuthorizeService全部返回`_NotificationDialog`；actions/actions_cb原样透传，保持confirm/deny/always行为；
- `setup_icon_path()`只给local GTK window解析icon；不向Caelestia发送icon/body，不恢复任何Blueman XDG surface；
- transient hint与Caelestia过滤不作为安全边界；Caelestia production `Notifs.qml`完全不改。

`close_ui()`管理这些local dialog；PIN/passkey/MAC可短暂存在于GTK widget内，但不会跨进程进入notification daemon/history/disk。

### 5.7 全局删除 visible/activation surface

1. Bluetooth profile：删除 `services.blueman.enable`、stock `blueman` system package和无效 mask；保留 `bluez`。
2. 不把 private `bluemanRuntime` 注册到 DBus/systemd/packages/XDG。
3. Rofi：删除 Bluetooth desktop item；保留其他 Rofi 功能。
4. Hyprland：删除 `blueman-manager` window rules。
5. 保留 `bctl=bluetoothctl` CLI alias。

stock runtime 留在 Nix store 不等于 surface；验证目标是搜索路径、注册集合、生成 unit、bus names 和 runner output。

### 5.8 Bluetooth-only rfkill 收敛

#### 5.8.1 单一idempotent finalizer

`${bluetoothRfkillFinalize}`同时供ordinary ExecStopPost与独立boot/resume helper使用；它没有poll、sleep、systemctl或event identity：

1. 枚举sysfs中`type=bluetooth` entries；无entry则零写成功；
2. 全部`soft=0`则零写成功，避免CHANGE→socket reactivation loop；
3. 任一`soft=1`才执行一次`${pkgs.util-linux}/bin/rfkill unblock bluetooth`；
4. 重读Bluetooth entries，任一soft仍为1则non-zero；
5. hard只记布尔摘要；永不使用`unblock all`，永不读写WLAN state/radio。

finalizer不接受runtime command/path参数；test derivation只能在build time替换sysfs/rfkill路径。

#### 5.8.2 ordinary hosts：systemd-rfkill per-invocation ExecStopPost

```nix
systemd.services.systemd-rfkill = lib.mkIf (!config.services.tlp.enable) {
  overrideStrategy = "asDropin";
  serviceConfig.ExecStopPost = [ "${bluetoothRfkillFinalize}" ];
};
```

Axiom/Azar/Harusame/Udon走该分支。显式`asDropin`保证不替换vendor unit。它不改变stock unit的enablement、socket、ExecStart、restore、timeout或WLAN policy；只append一条**不带`-`前缀**的ExecStopPost。Pinned stock unit当前没有该directive；构建审计必须断言最终list**恰好只有本finalizer一条**。若上游新增任何command则fail closed回到RFC，不能让前置失败跳过finalizer，也不能用空`ExecStopPost=`静默重置上游行为。

Pinned语义形成严格final-writer：normal idle路径先drain events并在return cleanup保存queue/关闭fd；failure/signal路径不保证保存queue，但所有main processes都先停止，systemd随后才运行ExecStopPost。restart是stop→ExecStopPost→start，且stop-post计入unit ordering。同一unit处于deactivating/ExecStopPost时，socket到达的新start只能排队，不能与旧invocation并发；新invocation启动后仍带同一finalizer。因此无需识别某个ADD属于旧还是新instance。

| instance结束原因 | finalizer语义 |
|---|---|
| 正常5秒idle退出 | main处理/保存后finalize；blocked→0，已0 no-op |
| late ADD在旧instance退出后触发socket新instance | 旧finalizer完成后新instance才start；新restore后新finalizer再保证0 |
| explicit restart/reactivation | 每个旧/新invocation各自按stop-post顺序finalize |
| startup/runtime failure | ExecStopPost仍运行；`SERVICE_RESULT`保留原failure，finalizer不掩盖；finalizer失败也使unit失败可见 |
| shutdown stop | 仍运行一次，受stock `TimeoutStopSec`约束；只碰Bluetooth；无device no-op |
| finite repeated events | stop-post期间的event排队到下一invocation；最后event后instance退出，最后finalizer保证0 |

第一次finalizer若写1→0，socket可能因CHANGE启动一次后续instance；该instance只保存CHANGE，退出时finalizer看到0且不写，所以不会自激循环。若其中又有ADD，仍由该instance处理并在自己的ExecStopPost收敛。无限外部event stream不构成已完成activation，期间不声明收敛；显式stop/restart/shutdown仍会finalize。

#### 5.8.3 udev、boot与resume触发

udev保留systemd tag，但按host选择target：

```udev
# ordinary build output
ACTION=="add", SUBSYSTEM=="rfkill", ATTR{type}=="bluetooth", TAG+="systemd", ENV{SYSTEMD_WANTS}+="systemd-rfkill.service"

# TLP build output
ACTION=="add", SUBSYSTEM=="rfkill", ATTR{type}=="bluetooth", TAG+="systemd", ENV{SYSTEMD_WANTS}+="bluetooth-rfkill-unblock.service"
```

共同的`bluetooth-rfkill-unblock.service`只调用同一finalizer，保留`WantedBy=multi-user.target`与post-resume `systemctl --no-block restart`作为boot/resume safety net；它没有systemd-rfkill Wants/After。ordinary late add的权威收敛点是stock service ExecStopPost；boot/resume helper即使先运行，之后任何restore invocation仍会自行finalize。

#### 5.8.4 TLP hosts

Ramen求值时不生成`systemd-rfkill` ExecStopPost/drop-in，ordinary udev rule也不存在；不得force-enable/unmask被TLP关闭的service/socket。boot/add/resume只运行独立helper。

TLP的`tlp-sleep.service` stop阶段先执行`tlp resume`/`restore_device_states`；NixOS到达`suspend.target`后，`post-resume.service After=suspend.target`才执行resume helper。因此helper晚于TLP restore，且无`tlp-sleep`或systemd-rfkill依赖。finalizer只写Bluetooth，TLP配置与WLAN live/persisted state保持不变。

#### 5.8.5 failure与observability

- 无Bluetooth或already-unblocked是成功no-op，日志只含entry count/result；
- unblock后仍soft=1：finalizer non-zero；ordinary stock unit或独立helper变failed，阻塞发布；
- stock main failure不会因finalizer成功变成success；可从`SERVICE_RESULT`与unit result观察；
- 不使用event-specific polling或自定义等待窗口；只依赖per-invocation ExecStopPost、stock stop timeout和一次同步rfkill命令。

### 5.9 Caelestia policy 与 fixture

#### 5.9.1 单一 policy source

新增 `modules/desktop/caelestia-bluetooth-policy.js` 作为唯一 QML-compatible 实现；package override 把同一文件放入上游 `modules/bar/popouts/`，checked-in patch只让 `Bluetooth.qml` import/调用它。测试与生产不复制函数。函数：

- `hasHumanName(device)`；
- `isPrimaryCandidate(device)`；
- `sortLabel(device)`：优先使用非 address 的 trimmed Alias（`device.name`），其次 `deviceName`，最后 address；比较时用非 locale 的 `toLowerCase()`；
- `compareDevices(a,b)`：connected、paired/bonded、human-name 降序，再按 `sortLabel`、规范化 address 升序；
- `primaryDevices(devices, limit=5)`：复制并用原始 index 装饰输入、filter、sort、slice，以 index 作最终 tie-break，不修改原数组。

匿名且未 connected/paired/bonded 的设备排除；匿名资产仍保留。`BluetoothPairing.qml` 与 `BluetoothPage.qml` 不改。

#### 5.9.2 可重复 fixture

`modules/desktop/tests/caelestia-bluetooth-policy-test.js` 由 Nix check用 Node `vm` 加载 **同一生产 JS 文件**；fixture 固定覆盖 Name、custom Alias、Alias=Address 大小写差异、空白、anonymous connected/paired/bonded、排序 tie、超过五项与输入不变，并断言精确 ID 顺序和长度。

同一 derivation 读取 pinned `BluetoothPairing.qml`，断言：

- 仍有 `filter(d => !d.bonded)`；
- 不 import/call primary policy；
- 无 `.slice(0, 5)` 或 human-name filter。

Caelestia package build 与该 policy test 都必须通过；构建后还要比较installed policy文件与repository source的hash，保证测试和运行代码相同。package build本身不算 QML语义证明。

## 6. Alternatives / Decision

### 6.1 Auth backend

| 方案 | 结论 |
|---|---|
| stock applet + GSettings | 拒绝：不可卸载插件、tray/menu/API 与 rfkill 竞态仍在 |
| 自写完整 Agent1 | 拒绝：复制安全敏感 pairing/UI 逻辑 |
| 裁剪 Blueman derivation | 拒绝：output/wrapper surgery 大于收益 |
| session notification factory/transient hint | 拒绝：Caelestia仍持久化body |
| **私有完整 runtime + bounded runner + local GTK factory** | 采用：零管理surface、零notification history、保留 pinned UI |

custom runner 比 stock applet surface 更小的可验证理由：它只 import `BluezAgent` 依赖链，不实例化 applet/plugin manager；唯一公共 command；不注册 `org.blueman.*` name/mechanism；状态机和日志适配有 fake-bus tests。额外代码限于宿主生命周期，不重写用户交互。

### 6.2 rfkill

| 方案 | 结论 |
|---|---|
| 只删 block/unblock | 不足：stale state/慢设备不收敛 |
| 全局禁用/启用 systemd-rfkill | 拒绝：破坏 WLAN/TLP |
| 无界/周期轮询 helper | 拒绝：隐藏失败且没有停止理由 |
| OnSuccess/外部watcher | 不选：增加第二transaction或长期observer |
| **ordinary per-invocation ExecStopPost；TLP独立helper** | 采用：每个可能restore的instance自行finalize |

### 6.3 Decision

采用：**私有 Blueman runtime + 单command安全runner/local GTK pairing + 全局surface删除 + ordinary per-invocation rfkill finalizer/TLP独立helper + 同源可测试Caelestia JS policy**。有意放弃Bluetooth soft-block跨boot/resume保留语义；不放弃WLAN/hard-block/TLP语义，也不改变Caelestia全局notification persistence。

## 7. Migration / Rollout / Rollback

### 7.1 首次 switch 清理

顺序必须是先阻止新激活，再清理旧进程：

1. switch 到不再注册 stock Blueman package 的 generation；
2. user side 停止：
   - `app-blueman@autostart.service`
   - `blueman-applet.service`
   - `blueman-manager.service`
   - applet cgroup 内的 `blueman-tray`
3. system side 停止 `blueman-mechanism.service`；
4. system/user manager 各自 daemon-reload、reset-failed；user侧重新登录完整图形会话以重建XDG generator/launcher cache；system D-Bus配置随switch reload，若`org.blueman.Mechanism`仍显示activatable则必须先阻塞部署并重启，而不是假定user relogin会清理root activation；
5. 验证 session bus 不存在/不可激活 `org.blueman.Applet`、`org.blueman.Manager`、`org.blueman.Tray`；system bus 不存在/不可激活 `org.blueman.Mechanism`；
6. 再启动/验证 `blueman-auth-agent.service`。新 runner 只占一个 system-bus unique name，不拥有任何 `org.blueman.*` well-known name。

旧 store path 不手工删除；GC 与 surface 无关。迁移不解析或重写现有Caelestia `notifs.json`；Revision 3/4只阻止新pairing secret进入history，测试使用唯一sentinel区分历史基线。

### 7.2 Rollout

1. 完成第 10.1–10.3 节 pre-deploy gates。
2. Axiom canary：环境、agent lifecycle、日志、pairing、BlueZ restart、rfkill、reboot/resume。
3. Ramen：验证 TLP/systemd-rfkill enablement 和 WLAN 状态前后不变，再测 resume helper。
4. 其余主机逐台部署；至少验证 unit、surface、soft block。

### 7.3 Rollback

1. Caelestia policy 异常：只回退 package override/policy。
2. rfkill finalizer异常：ordinary先移除systemd-rfkill ExecStopPost与对应udev target，TLP/boot/resume停独立helper；仍不恢复旧block，必要时手工`rfkill unblock bluetooth`。
3. agent 异常：停新 unit，临时交互式 `bluetoothctl agent KeyboardDisplay`；不要先恢复 stock Blueman。
4. 整代回滚为最后手段；会恢复旧 applet/Rofi/mechanism/rfkill 竞态，回滚后仍需停止 `app-blueman@autostart` 和 mechanism。

不迁移/删除 BlueZ pairing 数据。Bluetooth rfkill 持久值可能已变为 unblocked，这是契约内变化。

## 8. Observability / Security

### 8.1 允许的状态证据

- user journal：startup-check stage、BlueZ owner present/absent、四状态 transition、request kind、cleanup reason、error stage/type；不含interaction参数。
- system journal：systemd-rfkill invocation result、ExecStopPost finalizer start/result、Bluetooth entry count与soft/hard摘要；不记录设备路径或WLAN值。
- state=`default` 后 `sd_notify READY=1`；状态变化可更新 `STATUS=`。
- pairing interaction期间desktop `Notify` call count必须为0；Caelestia list/`notifs.json`只作负向证据，不由runner写入。

### 8.2 禁止日志

- PIN/passkey 值；
- MAC、BlueZ device object path、Alias；
- D-Bus payload；
- Caelestia notification list/`notifs.json`中的新pairing body；
- exception message/traceback（仅 class + allowlisted stage）。

任何负向日志测试命中即阻塞发布。

### 8.3 权限边界

- agent 以 `config.user.name` 运行；ConditionUser 覆盖 `c1` 与 `hlissner`。
- root 仅运行固定参数 rfkill oneshot；没有 Blueman mechanism、polkit action或用户输入。
- private runtime 的 mechanism 文件不在 system DBus/systemd 搜索路径。

## 9. Failure Semantics

| 失败 | 行为 | 发布影响 |
|---|---|---|
| display/schema/session bus/GTK check 失败 | 注册前非零退出 | 阻塞；不得假健康 |
| Register/Default 失败 | 逆序清理；owner在则重启 | 阻塞若持续 |
| Release/name vanish | 不做错误 remote unregister；local cleanup；可重建 | BlueZ restart 必测 |
| system connection closed | 本地清理并重启 | 自动恢复，持续失败阻塞 |
| stock systemd-rfkill main/start失败 | ExecStopPost仍尝试Bluetooth finalization，原SERVICE_RESULT保持failed | 阻塞并保留两份结果 |
| ExecStopPost/独立helper后Bluetooth仍soft=1 | finalizer non-zero、所属unit失败 | 阻塞 |
| no-device/already-unblocked | finalizer零写成功；未来device add由udev另行触发 | 非故障；当前进程不等待且不得制造socket loop |
| hard blocked | 不修改，明确状态 | 外部物理状态，不算 soft-block修复失败 |
| pairing内容触达desktop Notify/history/state | 关闭local dialog、阻塞发布 | 不修改Caelestia persistence来掩盖 |
| unrelated pnpm/Godot baseline | 记录且隔离 | 不在本任务修复 |

## 10. Verification Strategy

### 10.1 可重复单元/集成测试（pre-deploy）

#### Agent runner

fake connection/agent tests必须证明：

1. 正常调用顺序 `export → RegisterAgent → RequestDefaultAgent`，三者 connection identity 相同；
2. Default失败顺序 `UnregisterAgent → local unexport`；Register失败只 local unexport；
3. Release不调用 Unregister；name vanish不调用消失的 owner；所有local dialog/handler被清理，reappear可再次到 default；
4. SIGTERM/SIGINT 在四状态均幂等逆序清理；
5. connection close非零退出；
6. GTK init_check失败时零 system-bus/export调用；
7. READY只在 default；内建 `sd_notify` 适配直接写 `NOTIFY_SOCKET`，不启动额外 helper process；
8. `sys.modules` 不含 `blueman.main.Applet`、PowerManager、KillSwitch/其他 applet plugin；
9. 原`Notification()` factory或`_NotificationBubble`一旦构造就让test失败；五条路径返回的对象全部是`_NotificationDialog`；
10. 使用sentinel后captured stdout/stderr全不含PIN/passkey/MAC/object path。

增加private D-Bus integration fixture：以隔离`dbus-daemon`的地址设置`DBUS_SYSTEM_BUS_ADDRESS`，fake `org.bluez.AgentManager1`验证sender connection存活、主动调用Release、name owner vanish/reappear与重新注册；测试不得接触宿主BlueZ。

#### Pairing privacy

在Xvfb/隔离session bus和private fake BlueZ上通过generated user unit运行**实际adapter与Agent1 handlers**，从而同时取得unit journal。test-only QML harness直接加载pinned Caelestia `Notifs.qml`，使用临时`XDG_STATE_HOME`并把`Notifs.list`序列化到测试输出；它不patch production persistence。fake BlueZ提供`/org/bluez/hci0/dev_AA_BB_CC_DD_EE_FF`与必要Device1属性。

依次执行并自动响应local dialog，覆盖全部五个module call site及共享call site的两个入口：

1. `RequestPinCode(...)`并输入`PIN2468`；
2. `RequestPasskey(...)`并输入`135790`；
3. `DisplayPinCode(..., "654321")`；
4. `DisplayPasskey(..., 123456, entered)`；
5. `RequestConfirmation(..., 456789)`；
6. `RequestAuthorization(...)`；
7. `AuthorizeService(..., test-uuid)`。

等待test Caelestia `loaded=true`且save timer静默后，记录journal capture、desktop notification method-call计数、`Notifs.list`序列化值和`notifs.json` bytes/hash；关闭dialog后等待2秒（大于Caelestia 1秒save timer）。必须同时满足：

- `org.freedesktop.Notifications.Notify`调用为0；
- 每个interaction只产生local `_NotificationDialog`且action callback得到预期结果；
- stdout/stderr/journal不含全部输入/display/confirmation sentinel、MAC或object path；
- test Caelestia内存list与baseline逐项相同；
- `${XDG_STATE_HOME}/caelestia/notifs.json` bytes/hash不变，解析后也不含sentinel。

#### rfkill per-invocation finalizer

NixOS VM/isolated-systemd fixture使用socket-reactivated fake `systemd-rfkill.service`，并复用同一finalizer source；测试sysfs/rfkill路径只能build-time固定。预置Bluetooth persisted/live=1与WLAN live/persisted唯一sentinel。最终unit审计先断言ordinary host的ExecStopPost list恰好只有finalizer一条，stock command未被reset；Ramen无该drop-in。

必须覆盖并记录每个invocation id的`main-start → restore/events → main-exit → exec-stop-post-start → exec-stop-post-end`：

1. normal restore：main写Bluetooth=1并退出，finalizer写0；CHANGE触发的后续instance保存0且finalizer no-op；
2. **adversarial idle-expiry/reactivation**：Bluetooth sysfs entry与udev trigger先可见，fixture把匹配ADD投递hold到旧instance退出并完成finalizer之后；socket再启动新instance，新instance恢复1后必须由自己的finalizer写0；
3. explicit restart与连续三次ADD/CHANGE：任何新start均晚于上一ExecStopPost，最后soft=0；
4. startup failure、runtime failure、shutdown stop：ExecStopPost都出现；原SERVICE_RESULT不被成功finalizer掩盖；
5. no-device与already-unblocked：finalizer完成但fake rfkill write count=0，不产生自激reactivation；
6. finalizer模拟失败：所属unit failed且发布gate失败。

每个存在Bluetooth entry的invocation都在ExecStopPost完成点断言soft=0（finalizer失败case除外并明确failed）；no-device case断言零写；所有case中WLAN live value、persisted bytes/hash及fake write log逐位证明未被finalizer触碰。Ramen fixture只运行独立boot/add/resume helper，并断言不会load/start masked systemd-rfkill。

#### Caelestia policy

构建并运行第 5.9.2 fixture；精确比较排序/截断结果，并静态断言 pairing page 未过滤匿名设备。

#### Package/surface

- 枚举 runner output 全部文件、symlink、executable；唯一公共 non-dot executable为 `blueman-auth-agent`；hidden wrappers只链接该 command。
- 递归确认 runner output没有 `etc`、D-Bus/systemd/desktop/libexec surface。
- 证明 `ExecStart` 属于 runner output；private runtime只出现在 runner closure及该进程的 PYTHONPATH/schema/UI/icon/可选私有 XDG 参数，不进入 manager/session/Caelestia 环境。
- repo production scan确认无 Rofi Bluetooth、stock Blueman package/service、Hyprland manager rule。

### 10.2 五主机 Bluetooth 专项 eval/assertion

对 `axiom`、`azar`、`harusame`、`ramen`、`udon` 分别生成 JSON并失败即停：

| 断言 | 期望 |
|---|---|
| profile/user | Bluetooth=true；用户分别为 c1/c1/hlissner/hlissner/hlissner |
| Caelestia | 当前五台 true，使用 patched package |
| stock service | `services.blueman.enable=false` |
| auth unit | 存在；WantedBy/PartOf/After 均含 graphical-session.target；ConditionUser正确 |
| private boundary | ExecStart为 runner；private runtime不在 DBus/systemd/system package集合 |
| visible surface | 全局 Rofi/Hyprland source scan为零；runner output audit通过 |
| rfkill path | 四台ordinary host的systemd-rfkill可load且ExecStopPost list恰好只有Bluetooth finalizer、udev targets stock service、boot/resume helper无依赖；Ramen无drop-in、udev targets独立helper、masked units不被引用 |

这些查询只触达 Bluetooth/user/Caelestia/TLP/unit 属性，不请求四台失败主机的完整 toplevel/user package closure。

### 10.3 构建 gate（与 stable plan 对齐）

必须构建：

- auth runner package及其 tests；
- private D-Bus integration test与local-dialog/Caelestia-state privacy harness；
- shared rfkill finalizer、per-invocation/socket-reactivation VM fixture与ordinary/TLP两种生成unit；
- patched Caelestia package；
- QML policy fixture derivation；
- c1 与 hlissner 两种生成 user unit，并用 `systemd-analyze --user verify` 检查；
- 对五台主机分别从专项 eval结果提取并 build其 AuthAgent runner、rfkill helper/unit输入和patched Caelestia derivation；相同store path可由Nix去重，但每台引用都必须被检查；
- synthetic `axiom.extendModules` + `caelestia=false` 的专项 audit及相关 derivations；
- **Axiom 完整 `config.system.build.toplevel`**。

不要求五台完整 toplevel。若运行 broad `drvPath`/`nix flake check`，预期的 Azar/Ramen pnpm insecure 与 Harusame/Udon Godot rename 写入 `docs/test-report.md` 的 baseline 区；不得在本任务修复，也不得掩盖新增的 Bluetooth failure。

### 10.4 部署后硬件 gate（静态测试不可替代）

#### Axiom / `c1`

1. 新会话生成unit通过`systemd-analyze --user verify`；`MainPID`环境实际含WAYLAND_DISPLAY、session bus、runtime dir、schema，且runner日志只写presence/result。
2. `Gtk.init_check`、schema、session bus、state=default/READY均成功。
3. 启动按runner PID/session-bus unique sender过滤的method monitor；记录Caelestia sidebar当前内存history（count/可见内容截图）和`notifs.json` baseline。用不随生产交付的test client，对已存在的测试设备object path依次调用installed runner的RequestPinCode(输入`PIN2468`)、RequestPasskey(输入`135790`)、DisplayPinCode(`654321`)、DisplayPasskey(`123456`)、RequestConfirmation(`456789`)、RequestAuthorization、AuthorizeService，并操作每个local GTK action（AuthorizeService只选accept/deny，不选会持久化Trusted的always）。全部call site均不得出现`Notify` call或Caelestia history项。
4. 从Caelestia发起至少一次真实confirmation/passkey pairing；同样只能出现local GTK dialog。关闭后等待2秒，sidebar内存history和`notifs.json`相对baseline都不得新增含测试设备、PIN/passkey、MAC或object path的条目；用唯一sentinel比较delta，不要求清理历史旧条目。
5. 对runner stdout/stderr、同一时间窗user journal做sentinel负向扫描；system `bluetoothd`既有日志另行记录，不归因于runner。
6. 用测试调用触发Agent1 Release：owner仍在时进程重启并回到default；随后`systemctl restart bluetooth.service`，无论Release或name vanish均cleanup并重新default。
7. 在维护窗口执行真实late-add finalizer gate：备份Bluetooth state file，记录全部WLAN live soft/hard与persisted bytes/hash并确认live/persisted sentinel一致；unbind Bluetooth driver使entry消失，等待旧systemd-rfkill invocation完成，在multi-user已active时把对应Bluetooth persisted state设为1并rebind。`udevadm monitor`必须显示tagged add；每个新invocation的journal/InvocationID都必须呈现main exit后`ExecStopPost` start/end。最终Bluetooth soft=0；若unblock CHANGE触发后续instance，该instance也必须finalize且no-op，persisted Bluetooth最终收敛0，WLAN sentinel逐位不变。cleanup总是rebind；失败恢复Bluetooth备份，成功保留0。
8. reboot一次、suspend/resume两次；每次Bluetooth最终soft=0，所有systemd-rfkill ExecStopPost和boot/resume helper均成功，Caelestia off→on可用。
9. session/system bus与进程/unit检查确认所有旧Blueman surface/name/mechanism消失。

#### Ramen / `hlissner`

1. unit环境与GTK检查同样通过，ConditionUser=`hlissner`。
2. 部署前后`services.tlp.enable=true`；`systemd-rfkill.service/socket`仍disabled/masked且没有ExecStopPost drop-in；independent helper不含它们或`tlp-sleep.service`依赖。
3. 记录WLAN soft/hard、persisted state与TLP状态；boot/helper/resume前后逐位相同。
4. suspend/resume journal必须显示`tlp resume`/`restore_device_states`完成，随后`post-resume.service`才启动independent helper；不得load ordinary systemd-rfkill或drop-in。
5. tagged add可拉起TLP分支helper并清除Bluetooth soft block；hard block不被伪装。

#### 其余主机

逐台至少验证 agent active/default、无旧 surface、Bluetooth soft=unblocked。真实硬件不能覆盖的 Agent1交互类型记录为 residual，不宣称已证明。

## 11. Rollback Triggers

- GTK/environment检查持续失败、agent无法回到 default、BlueZ restart后失效；
- 任何pairing敏感值进入journal、desktop `Notify`、Caelestia内存history或`notifs.json`；
- runner/private runtime进入会话 XDG、DBus/systemd activation或出现stock进程；
- ordinary ExecStopPost list不恰好等于finalizer、任一restore invocation未finalize/形成自激loop，或Ramen TLP/systemd-rfkill/WLAN状态变化；
- QML fixture失败或pairing page隐藏匿名设备；
- Axiom boot/resume后Bluetooth仍soft blocked。

按第7.3节组件级回滚；保留测试证据。

## 12. Milestones

### Milestone 1：安全 runner 与 surface 边界

- private runtime + runner package；GTK checks；单连接状态机；安全日志/local-dialog seam；user unit。
- 验收：runner/unit/private-bus/privacy-state/package tests通过，desktop Notify与Caelestia history增量为零，c1/hlissner unit verify通过。

### Milestone 2：全局 surface 与 rfkill

- 删除Blueman/Rofi/Hyprland surface；ordinary systemd-rfkill ExecStopPost与TLP独立helper；host-conditional tagged udev。
- 验收：idle-expiry→socket-reactivation adversarial fixture与WLAN-sentinel gate通过；五主机专项eval与Axiom/Ramen unit derivation通过。

### Milestone 3：Caelestia policy

- 同源 JS policy、QML patch、fixture。
- 验收：policy fixture、pairing-page invariant、patched package build通过。

### Milestone 4：构建与部署 gate

- Axiom full build、synthetic boundary、Axiom/Ramen硬件验证、其余主机逐台smoke。
- 验收：第10节证据写入后续 `docs/test-report.md`；无新增 baseline regression。

## 13. Residual Risks / Open Questions

无阻塞设计问题。必须保留的 residual：

- `BluezAgent`、`DbusService._bus`与`_NotificationDialog`都是pinned private API；每次flake update重跑完整lifecycle/privacy tests。
- direct installed-runner calls可覆盖七个interaction入口/全部五个notification call site，但单个真实设备未必自然触发全部Bluetooth pairing语义；未自然覆盖类型明确记录。
- systemd-rfkill的pinned private lifecycle不是本设计API，但ExecStopPost是stable unit语义；每次systemd update都重跑normal/failure/restart/shutdown/reactivation fixture。
- 无限外部rfkill event stream会延后该invocation退出与finalizer；验收只对有限boot/add/resume burst声明收敛，显式stop/restart/shutdown仍会finalize，production不添加poller掩盖持续输入。
- Bluetooth soft block不再跨boot/resume保留是有意行为；WLAN/hard block不在该变化内。

## 14. Re-review Closure

| Review blocker | 本版关闭位置 |
|---|---|
| 1. 图形环境/GTK时序 | 5.4、10.2–10.4 |
| 2. persistent connection与状态机 | 5.5、10.1、10.4 |
| 3. package路径/wrapper/迁移 | 5.2、5.7、7.1、10.1 |
| 4. udev tag/TLP/Ramen | 5.8、10.1–10.4 |
| 5. 基线相容gate/QML fixture | 5.9、10.1–10.3 |
| 6. PIN/passkey/MAC日志 | 5.6、8、10.1、10.4 |
| local pairing icon/backend与root/user cleanup | 5.6.2、7.1 |
| Revision 2/3剩余：ordinary rfkill final writer | 5.8.1–5.8.5、9、10.1–10.4 |
| Revision 2剩余：pairing history privacy | 5.6.2、8、9、10.1、10.4 |

Revision 4只替换Revision 3未关闭的ordinary final-writer；pairing privacy及其余gate保持不变。per-invocation finalizer与adversarial reactivation fixture均已定义，状态为 **Ready for re-review**。尚未授权生产实现。

## 15. References

- Contract：`../plan.md`
- Research：`research.md`
- Failed review：`review-rfc.md`
- 关键本仓库文件：
  - `modules/profiles/hardware/bluetooth.nix:9-39`
  - `modules/desktop/apps/rofi.nix:73-80`
  - `modules/desktop/caelestia.nix:36-43,130-135,231-237`
  - `modules/desktop/hyprland.nix:443-570,678-679`
  - `hosts/ramen/default.nix:10-12,100-113`
- Pinned sources与行号索引：见 `research.md`。

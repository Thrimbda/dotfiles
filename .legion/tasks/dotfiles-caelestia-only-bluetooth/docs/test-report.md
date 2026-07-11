# 验证报告：Caelestia-only Bluetooth Control（最终权威复验）

> 日期：2026-07-12
> 阶段：`verify-change` final authoritative verification
> 结论：**PASS**

## 1. 最终结论

此前三个 pre-deploy blocker 均已关闭：

| Gate | 结论 | 直接证据 |
|---|---|---|
| runner/process PATH 不得暴露 stock Blueman `bin` | **PASS / CLOSED** | focused derivation重建；runner output/wrapper与运行中环境审计继续通过。 |
| generated auth unit + private D-Bus/fake BlueZ + production `Notifs.qml` privacy fixture | **PASS / CLOSED** | NixOS VM实际启动生成的`blueman-auth-agent.service`，取得两个真实user-unit InvocationID；七个Agent1入口通过；Notify=0；QML memory与state bytes/hash均零变化；journal与完整VM build log无sentinel。 |
| real systemd socket/service per-invocation rfkill fixture | **PASS / CLOSED** | NixOS VM的PID 1实际加载socket-activated generated service/socket；16个manager InvocationID与journal逐一相等；normal/reactivation/restart/failure/shutdown/repeated/no-device/finalizer-failure通过，WLAN逐位不变。 |
| pinned vendor `ExecStopPost` drift audit | **PASS / CLOSED** | focused derivation重建继续解析真实systemd 258.7 vendor unit并得到`result=no-exec-stop-post`。 |

五主机专项断言、相关derivation、生成unit/surface、synthetic boundaries、Caelestia installed wiring与Axiom完整toplevel均通过。当前无剩余pre-deploy blocker；第11节仅保留真实硬件/部署后gate。

验证期间未修改生产代码，未操作宿主Bluetooth、BlueZ、rfkill或TLP，未配对设备，未启停相关live unit，未部署或激活generation。

## 2. 输入与证据选择

重新读取并按以下优先级验证：

- `plan.md`；
- `docs/rfc.md` Revision 4，重点为10.1–10.4；
- PASS `docs/review-rfc.md`；
- 当前diff及新增VM fixture：`_bluetooth-predeploy-vm-test.nix`、`vm-fake-bluez.py`、`vm-agent-call.py`、`vm-notifs-harness.qml`、`vm-rfkill-main.py`；
- 前次FAIL `docs/test-report.md`。

优先使用`--rebuild`重跑新VM derivation，因为它能同时覆盖两个剩余高风险seam；随后重建其他focused checks并回归所有受影响生成面。没有用旧Python ordering model替代real-systemd证据。

## 3. VM fixture独立审计与重建

### 3.1 实现不是模型

源码与求值结果确认：

- fixture由`pkgs.testers.runNixOSTest`创建QEMU NixOS VM；VM内systemd为真实PID 1。
- `blueman-auth-agent.service`由生产`mkBluemanAuthAgentService "fixture"`生成，VM只叠加Xvfb/private-bus测试环境；生成unit保持`Type=notify`、`ConditionUser=fixture`，`ExecStart=/nix/store/3vhfsp4gz06faxx32xy4rd6fgmqzff74-blueman-auth-agent-2.4.6/bin/blueman-auth-agent`。
- agent环境明确指向两个隔离bus：`/run/bluetooth-predeploy/system-bus`与`/run/bluetooth-predeploy/session-bus`；fake BlueZ在前者拥有`org.bluez`并导出真实`AgentManager1`及测试`Device1`。
- fixture通过generated user manager启动agent，检查`ActiveState=active`、`SubState=running`、`Type=notify`和systemd生成的InvocationID；不是在测试进程内直接构造adapter。
- rfkill fixture生成完整`vm-systemd-rfkill.service/.socket`并以`systemd-rfkill.service/.socket` alias加载；`ListenDatagram`为真实AF_UNIX socket，service从systemd传入FD 3、`INVOCATION_ID`、`NOTIFY_SOCKET`与`SERVICE_RESULT`。
- `ExecStopPost`复用production `bluetooth-rfkill-finalize.sh`，仅在build time替换fake sysfs与fake `rfkill` command；ordering由systemd transaction/socket activation产生，而不是Python driver自行调用下一instance。

关键求值命令：

```sh
nix eval --json --impure --expr '
  let f = builtins.getFlake (toString ./.);
      deps = f.nixosConfigurations.axiom.config.system.extraDependencies;
      vm = builtins.head (builtins.filter
        (x: x.name == "vm-test-run-bluetooth-predeploy-integration") deps);
      c = vm.nodes.machine.config;
  in {
    machineEtc = toString c.system.build.etc;
    auth = {
      execStart = c.systemd.user.services.blueman-auth-agent.serviceConfig.ExecStart;
      type = c.systemd.user.services.blueman-auth-agent.serviceConfig.Type;
      conditionUser = c.systemd.user.services.blueman-auth-agent.unitConfig.ConditionUser;
      environment = c.systemd.user.services.blueman-auth-agent.environment;
    };
    notifs.execStart = c.systemd.user.services.caelestia-notifs-harness.serviceConfig.ExecStart;
    rfkill = {
      serviceAliases = c.systemd.services.vm-systemd-rfkill.aliases;
      execStart = c.systemd.services.vm-systemd-rfkill.serviceConfig.ExecStart;
      execStopPost = c.systemd.services.vm-systemd-rfkill.serviceConfig.ExecStopPost;
      socketAliases = c.systemd.sockets.vm-systemd-rfkill.aliases;
      listen = c.systemd.sockets.vm-systemd-rfkill.socketConfig.ListenDatagram;
      socketService = c.systemd.sockets.vm-systemd-rfkill.socketConfig.Service;
    };
  }'
```

结果：VM `/etc`为`/nix/store/1l1zxx7g4ss3rsw09sjik371ba6b248n-etc`；generated auth、QML harness、service/socket及其aliases均与上述配置一致。对该生成树执行system与user `systemd-analyze verify`通过。

### 3.2 pinned production `Notifs.qml`

`notifsHarnessPackage`只将test shell安装为`shell.qml`；shell通过`import qs.services`使用包内原始service，不修改production persistence。独立比较：

```sh
cmp -s "/nix/store/c4dkk5bkjax215xgrmiy9dcvgbddl3ar-source/services/Notifs.qml" \
  "/nix/store/9sl200wq3ld43j1j8gs3822sw5xcv9r5-caelestia-shell-1.0.0/share/caelestia-shell/services/Notifs.qml"
cmp -s "/nix/store/9sl200wq3ld43j1j8gs3822sw5xcv9r5-caelestia-shell-1.0.0/share/caelestia-shell/services/Notifs.qml" \
  "/nix/store/xd8hdngn2rmcfg8l8pi0pax1vmf4mqlq-caelestia-notifs-harness-1.0.0/share/caelestia-shell/services/Notifs.qml"
sha256sum "/nix/store/9sl200wq3ld43j1j8gs3822sw5xcv9r5-caelestia-shell-1.0.0/share/caelestia-shell/services/Notifs.qml"
```

结果：两次`cmp`均通过；pinned input、实际production patched package与VM harness中的`Notifs.qml`完全相同，SHA-256均为：

```text
f2ee48b3bd5409c4538e421263c32f49e7b11d5bb4ec0fff8ecd547688a534de
```

### 3.3 authoritative rebuild

```sh
nix build --rebuild --no-link --print-out-paths --impure --expr '
  let f = builtins.getFlake (toString ./.);
      deps = f.nixosConfigurations.axiom.config.system.extraDependencies;
      matches = builtins.filter
        (x: x.name == "vm-test-run-bluetooth-predeploy-integration") deps;
  in if builtins.length matches == 1 then builtins.head matches
     else throw "expected exactly one Bluetooth predeploy VM test"'
```

结果：**PASS**。Nix重新执行并检查输出：

```text
/nix/store/9mx86i6ska977p3pjhdz86hp6g5ryj19-vm-test-run-bluetooth-predeploy-integration
test script finished in 38.19s
```

### 3.4 real-systemd InvocationID、ordering与WLAN

VM log最终摘要：

```text
real-systemd-rfkill invocations=16 service-results=success:14,exit-code:2 finalizer-failures=1 wlan-delta=0 result=pass
real-systemd-rfkill invocation-ids=0d13ea026bea4947b9e7ade0faf3f587,213f880baff6408faa0fae904c841f8c,38327a577efd4cdd965322a2b12e3959,3843a2995bbc4792baa8daeba81169b6,45bd903796b54877bfe12373b3b97949,4ac32e6fc480451f87887470845636e0,548f2e2c4e0e4712959d4f495f8bd3af,585a299cef0f4786b0e293ae56769bda,7eb957cb9bfb45b9a44a686574acd571,83660d6574664eaea80e25a2ba79cd5c,86fc45523ff34a43a025e8e67648742b,894477b5bab34814be42df23bf8852b4,bffac4959246463998e9e414147aa42c,cedb120790e744afadbc5edd183a6ea6,db442abf4b5b450ba061143dbfdaf3d3,ef2c0077ef2f4375872053206ce9aa7f
rfkill-wlan live-sha256=d1ba2e662226cc2d1e7a9a0de0aedd52fd97c75f07e9022077687a31cc0db82f persisted-sha256=381776e915ef1f30b8178d142536f3fa8add596a1a3c8b2cd07a1796c13a1a57
```

fixture对每个ID要求一对真实`ExecStopPost` start/end，并把events中的ID集合与journal `_SYSTEMD_INVOCATION_ID`集合精确比较。源码与fresh log共同确认：

- normal ADD执行`socket-receive → main-start → main-exit → ExecStopPost start/end`，finalizer触发真实CHANGE reactivation；第二instance持久化0并no-op，最终live/persisted Bluetooth均为0；
- adversarial case将旧instance实际hold在ExecStopPost，期间向真实socket排队ADD；日志中旧post end先于下一`socket-receive`，随后ADD restore=1、自己的finalizer=0、CHANGE instance再收敛；
- explicit `systemctl restart --no-block`证明旧post end先于新main start；
- startup/runtime failure均保留systemd提供的`SERVICE_RESULT=exit-code`且unit仍failed，成功finalizer不掩盖main failure；
- shutdown-style socket+service stop仍执行post；三次排队CHANGE形成三个串行real activations；
- no-device不增加fake rfkill write；verification failure令真实unit failed且`finalizer_status=1`。

独立按fixture字节重新计算WLAN hash，与VM摘要逐字相同；WLAN live sentinel和含NUL/`0xff`的persisted bytes在全部case后未变。production finalizer每次成功返回前也重新验证所有存在的Bluetooth entry为soft=0。

### 3.5 generated unit privacy与negative sentinels

VM log最终摘要：

```text
generated-auth-unit invocations=8e008190cf614ba9946214df958fd871,bacdef1d3b9a40769be349e793637ac1 interactions=7 ready=2 notify=0 qml-memory-delta=0 state-delta=0 result=pass
caelestia-notifs memory-sha256=6d86ba398b97faa09037e2b9426e4c09905951cfa9c52471b92d282a52f73ea2 state-sha256=6d86ba398b97faa09037e2b9426e4c09905951cfa9c52471b92d282a52f73ea2
```

Fresh log显示真实user unit向private fake BlueZ执行`RegisterAgent`/`RequestDefaultAgent`，systemd收到READY后进入active；restart后使用不同的第二个InvocationID并再次READY。七个入口均通过fake BlueZ connection调用installed runner的actual Agent1 handlers；Xvfb/xdotool实际响应local GTK dialog。focused private-D-Bus test另行精确断言PIN返回`PIN2468`和passkey返回`135790`。

production `Notifs.qml`在private session bus拥有`org.freedesktop.Notifications`。fixture在交互前后分别执行byte-for-byte `cmp`及SHA-256比较：内存序列化值与`notifs.json`都保持baseline hash `6d86...3ea2`；独立计算baseline字节得到同一hash。private-bus `dbus-monitor`的Notify method-call计数为0。

unit journal内部断言不含PIN/passkey/display/confirmation、MAC或object path。另对fresh完整VM build log执行：

```sh
LC_ALL=C rg -a -n \
  'PIN2468|135790|654321|123456|456789|AA:BB:CC:DD:EE:FF|/org/bluez/hci0/dev_AA_BB_CC_DD_EE_FF' \
  /home/c1/.local/share/opencode/tool-output/tool_f52f72cb80023Tb6Ri59YAKCSj
```

结果：`matches=0`。因此前次generated-unit/QML privacy blocker **CLOSED**。

## 4. Diff、语法与其余focused derivations

```sh
git diff --check
nix-instantiate --parse modules/profiles/hardware/bluetooth.nix >/dev/null
nix-instantiate --parse modules/profiles/hardware/tests/_bluetooth-predeploy-vm-test.nix >/dev/null
nix-instantiate --parse modules/desktop/caelestia.nix >/dev/null
nix-instantiate --parse modules/desktop/apps/rofi.nix >/dev/null
nix-instantiate --parse modules/desktop/hyprland.nix >/dev/null
python3 -c 'import ast,pathlib; paths=["modules/profiles/hardware/bluetooth-auth-agent.py","modules/profiles/hardware/tests/test-bluetooth-auth-agent.py","modules/profiles/hardware/tests/test-bluetooth-auth-agent-integration.py","modules/profiles/hardware/tests/test-systemd-rfkill-reactivation.py","modules/profiles/hardware/tests/vm-fake-bluez.py","modules/profiles/hardware/tests/vm-agent-call.py","modules/profiles/hardware/tests/vm-rfkill-main.py"]; [ast.parse(pathlib.Path(p).read_text(),filename=p) for p in paths]'
node --check modules/desktop/caelestia-bluetooth-policy.js
node --check modules/desktop/tests/caelestia-bluetooth-policy-test.js
dash -n modules/profiles/hardware/bluetooth-rfkill-finalize.sh
dash -n modules/profiles/hardware/tests/fake-rfkill.sh
dash -n modules/profiles/hardware/tests/test-bluetooth-rfkill.sh
```

结果：全部 **PASS**。

其余checks强制重建：

```sh
nix build --rebuild --no-link --print-out-paths --impure --expr '
  let f = builtins.getFlake (toString ./.);
  in builtins.filter
    (x: x.name != "vm-test-run-bluetooth-predeploy-integration")
    f.nixosConfigurations.axiom.config.system.extraDependencies'
```

结果：

- `/nix/store/ypg30s1py7z93bn7b98i3sczmkwpxg69-blueman-auth-agent-tests`：13 unit tests + pinned import + private-D-Bus integration PASS；`interactions=7 notify=0 state-delta=0 path-boundary=pass`。
- `/nix/store/hccblp3r8w6jhp2qy0rnq53p5ra170f2-bluetooth-rfkill-finalize-tests`：finalizer unit cases、20-invocation旧模型回归及真实vendor audit PASS；模型现在只作低成本补充，不承担real-systemd结论。
- `/nix/store/97fksp5g19m84ysrrw95qfsvbl23zbka-caelestia-bluetooth-policy-test`：PASS。

`nix log`仅出现本机readonly Nix binary-cache SQLite清理warning，不影响daemon build或输出验证。

## 5. 五主机专项断言与生成surface

对`axiom/azar/harusame/ramen/udon`重新执行实际配置专项JSON投影，断言profile/user、Bluetooth、Caelestia、stock Blueman disabled、generated auth unit、WantedBy/PartOf/After、ConditionUser、Type=notify、ExecStart与四个focused dependency。结果五台`pass=true`：

| Host | User | TLP | ExecStopPost | udev target |
|---|---|---:|---|---|
| Axiom | c1 | false | 唯一Bluetooth finalizer | `systemd-rfkill.service` |
| Azar | c1 | false | 唯一Bluetooth finalizer | `systemd-rfkill.service` |
| Harusame | hlissner | false | 唯一Bluetooth finalizer | `systemd-rfkill.service` |
| Ramen | hlissner | true | `[]` | 独立`bluetooth-rfkill-unblock.service` |
| Udon | hlissner | false | 唯一Bluetooth finalizer | `systemd-rfkill.service` |

五台均引用：auth tests、rfkill tests、real VM test、Caelestia policy test及patched Caelestia package。相关derivation build输出去重为：

```text
/nix/store/ypg30s1py7z93bn7b98i3sczmkwpxg69-blueman-auth-agent-tests
/nix/store/hccblp3r8w6jhp2qy0rnq53p5ra170f2-bluetooth-rfkill-finalize-tests
/nix/store/9mx86i6ska977p3pjhdz86hp6g5ryj19-vm-test-run-bluetooth-predeploy-integration
/nix/store/97fksp5g19m84ysrrw95qfsvbl23zbka-caelestia-bluetooth-policy-test
/nix/store/9sl200wq3ld43j1j8gs3822sw5xcv9r5-caelestia-shell-1.0.0
```

public package scan结果仍为：

```json
{"axiom":[],"azar":[],"harusame":[],"ramen":[],"udon":[]}
```

Rofi/Hyprland source scan无`rofi-bluetooth`、`Manage Bluetooth Devices`或`blueman-manager`。

生成树：

- Axiom `/nix/store/rpgcr9w2kq22vd5wk8bmfc50f1xsxs4d-etc`
- Azar `/nix/store/z0f9jm9hh5k903290p63vkspd4n0vh7y-etc`
- Harusame `/nix/store/wfsr9la4i0c469j4mihjrb8fg97fh4kv-etc`
- Ramen `/nix/store/p4zp6kqjnybimmn09kmdmnymdx1ip4ll-etc`
- Udon `/nix/store/93xwyxcp8g6fq2dymgc9kk2yxkrlc4aa-etc`

四台ordinary对stock service/socket、helper及user unit执行`systemd-analyze verify`通过；每台确有drop-in且求值确认唯一finalizer。Ramen的service/socket均为`/dev/null` mask、无drop-in；单独验证independent helper与user unit通过，依赖列表不含systemd-rfkill或TLP。Azar仍只有无关`LimitNRPC` warning。

一次未收窄的`systemd.services`查询触发Harusame既有Godot rename；使用与既有baseline一致的test-only package overrides后，Bluetooth生成surface全部通过。一次把Ramen masked unit当作ordinary unit交给`systemd-analyze verify`得到预期`Unit ... is masked`非零；随后按TLP契约改为mask断言+helper verify并通过。这两项均不是Bluetooth regression。

## 6. Synthetic boundaries

### Bluetooth=true / Caelestia=false

```sh
nix build --no-link --print-out-paths --impure --expr '
  let f = builtins.getFlake (toString ./.);
      c = (f.nixosConfigurations.axiom.extendModules { modules = [ ({ lib, ... }: {
        modules.desktop.caelestia.enable = lib.mkForce false; }) ]; }).config;
  in c.system.extraDependencies ++ [ c.system.build.etc ]'
```

结果：**PASS**。生成`/nix/store/vp61yh64fhylncqxzc5ldf7laahfvzx2-etc`；Bluetooth/auth/helper保留，stock Blueman=false，Caelestia=false。三个Bluetooth predeploy dependencies（含real VM）保留，Caelestia policy check不安装；generated system/user units verify通过。

### Bluetooth=false / Atlas

专项eval得到profile/Bluetooth/auth/helper/Blueman均false，Caelestia=true，extraDependencies仅Caelestia policy test。focused build输出`/nix/store/zambc736qmpc883dnq5jwpxqcwl16550-etc`；无auth unit、helper、drop-in或Bluetooth-specific udev target，**PASS**。

## 7. Caelestia installed wiring

```sh
cmp -s modules/desktop/caelestia-bluetooth-policy.js \
  /nix/store/9sl200wq3ld43j1j8gs3822sw5xcv9r5-caelestia-shell-1.0.0/share/caelestia-shell/modules/bar/popouts/BluetoothPolicy.js
sha256sum modules/desktop/caelestia-bluetooth-policy.js \
  /nix/store/9sl200wq3ld43j1j8gs3822sw5xcv9r5-caelestia-shell-1.0.0/share/caelestia-shell/modules/bar/popouts/BluetoothPolicy.js
```

结果：两个hash均为`bfd4c89d62072cf69817b5038698a2b442d426e4501368a707590a6bfe7cf291`。installed `Bluetooth.qml`调用`BluetoothPolicy.primaryDevices(Bluetooth.devices.values, 5)`；完整pairing page继续使用全量未bonded排序，不引用primary policy或5项截断。**PASS**。

## 8. Axiom完整toplevel

新增VM output已进入Axiom `extraDependencies`，因此重建完整稳定契约：

```sh
nix build --no-link --print-out-paths --impure \
  "path:$PWD#nixosConfigurations.axiom.config.system.build.toplevel"
```

结果：**PASS**：

```text
/nix/store/0zan9qw8x6c4qi41bn98xgxmdi8w6pf2-nixos-system-axiom-25.11.20260630.b6018f8
```

`nix-store --query --requisites`确认该toplevel包含fresh PASS VM output。该build之后的工作区变化仅为本报告证据文字写回，不涉及生产代码或测试fixture；未激活该generation。

## 9. Broad baseline

重新求值四台非Axiom完整`toplevel.drvPath`：Azar/Ramen仍被无关insecure `pnpm-10.29.2`阻断；Harusame/Udon仍被无关`godot_4-export-templates` rename阻断。与既有稳定baseline一致，未扩scope修复，也未用于掩盖Bluetooth专项结果。

## 10. Evidence boundary

本次VM证明的是：generated unit、installed runner、private buses、fake BlueZ协议交互、production QML persistence、真实systemd manager/socket/service transaction及synthetic rfkill sysfs。它不把fake device或fake sysfs宣称为真实硬件证据。

当前无skipped pre-deploy gate。QML的Xcb EGL/无Wayland/无Hyprland warning是刻意Xvfb harness环境中的非阻塞日志；fixture实际加载完成、拥有notification bus name并通过state/privacy断言。

## 11. 精确deploy-only residuals

以下必须在维护窗口部署后完成，且未被本报告宣称为已验证：

1. **Axiom真实session readiness**：实际UWSM/Wayland session中检查generated user unit的`MainPID`环境、schema/session bus/GTK/icon、`state=default`及READY；确认private runtime未进入session/Caelestia PATH/XDG。
2. **真实配对与privacy**：对测试设备完成至少一次真实confirmation/passkey pairing；其余可触发Agent1类型用installed runner test client补齐。只允许local dialog；Caelestia sidebar内存history、真实用户`notifs.json` bytes/hash、Notify monitor及runner user journal必须无新增sentinel/MAC/object path。
3. **Agent lifecycle**：在真实user session触发Agent1 Release并确认回到default；重启`bluetooth.service`后确认owner vanish/reappear cleanup及重新default。
4. **Axiom MediaTek/rfkill**：备份Bluetooth persisted state，记录WLAN soft/hard与persisted bytes/hash；执行真实late unbind/rebind，核对每个真实systemd-rfkill InvocationID的main exit→ExecStopPost链及最终Bluetooth soft=0；成功后persisted Bluetooth收敛0，WLAN逐位不变。
5. **Axiom power cycle**：reboot一次、suspend/resume两次；每次finalizer/boot/resume helper成功、Bluetooth soft=0，Caelestia off→on可用。
6. **Ramen/TLP**：确认TLP仍启用、systemd-rfkill service/socket仍masked且无drop-in；真实boot/add/resume中helper晚于TLP restore，不load masked unit，Bluetooth soft=0且WLAN live/persisted与TLP状态逐位不变。
7. **其余主机**：逐台确认agent active/default、无stock Blueman/Rofi/manager surface、ordinary finalizer effective及Bluetooth soft=0；真实设备未自然覆盖的Agent1类型明确记录，不补写虚假成功。

## 12. Definitive verdict

**PASS**。fresh NixOS VM rebuild真实关闭了generated-unit/QML privacy与real-systemd ordering两个剩余blocker；其余focused、multi-host、synthetic、installed-wiring及Axiom full-build gates均通过。实现可进入只读`review-change`，部署仍受第11节真实硬件gate约束。

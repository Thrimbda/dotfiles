# 验证报告：RFC Revision 5 TLP wiring authoritative rerun

> 日期：2026-07-12
> 阶段：`verify-change`
> 基线：`origin/master` `a26019e4a6c86b8533bd7051e1871bb1df805380`
> 分支HEAD：`6c69b7732f232a91ca511e5faee1e8730cb4b53c`，Revision 5为当前working-tree实现
> 结论：**PASS**

## 1. 结论

RFC Revision 5 的pre-deploy gates全部通过：

| Gate | 结论 | 权威证据 |
|---|---|---|
| Ramen production full `multi-user.target` graph | **PASS** | actual Ramen专项求值的105个unit links，以及82 services、8 targets、7 sockets、2 timers、3 slices的dependency graph，与用于构建完整unit tree的bounded projection完全相同；pinned systemd 258.7 full-target verify为status 0、diagnostic bytes 0。旧graph负向对照仍status 0但产生2条cycle/job-deleted诊断，并被同一scanner拒绝。 |
| Revision 5 static wiring | **PASS** | generic helper无multi-user link；`tlp.service`只有weak `Wants=bluetooth-rfkill-unblock.service`；helper/template均`After=tlp.service`；vendor `tlp-sleep.service`及drop-in无Bluetooth hook；`post-resume.service`脚本恰有一次nonblocking restart。 |
| Per-device ADD identity | **PASS** | udev只把`%k`放进`@%k`unit identity；template `ExecStart`逐字等于immutable finalizer store path，service fields无`%i/%I`或instance input。fresh VM同时观察base、`@rfkill1`、`@rfkill2`三个job和三个不同InvocationID。 |
| Faithful TLP VM | **PASS** | fresh `--rebuild`保留vendor TLP unit内容与`After=multi-user.target NetworkManager.service`，默认boot启动完整target；success/failure/timeout init、boot/add/three-way concurrency、helper failure/recovery、successful/failed resume、mask与byte/hash invariants均通过。 |
| Previously approved behavior | **PASS** | owner-query、auth/private D-Bus/privacy、ordinary rfkill、Caelestia、五主机focused boundaries、两个synthetic boundaries及Axiom完整toplevel全部重新验证。 |

验证过程中未修改production code、plan/tasks/log/review docs或宿主live state；未调用宿主`systemctl`、BlueZ、rfkill、TLP或配对设备。验证器只写回本报告。NixOS VM内的systemd操作均在隔离QEMU guest中。

## 2. 验证对象与base边界

执行：

```sh
git fetch origin master
git rev-parse HEAD origin/master
git merge-base HEAD origin/master
sha256sum \
  modules/profiles/hardware/bluetooth.nix \
  modules/profiles/hardware/tests/_bluetooth-predeploy-vm-test.nix \
  .legion/tasks/dotfiles-caelestia-only-bluetooth/docs/rfc.md \
  .legion/tasks/dotfiles-caelestia-only-bluetooth/docs/review-rfc.md
```

结果：

```text
HEAD          6c69b7732f232a91ca511e5faee1e8730cb4b53c
origin/master a26019e4a6c86b8533bd7051e1871bb1df805380
merge-base    a26019e4a6c86b8533bd7051e1871bb1df805380

a11c9491d863590879c29e924a4a99757d4798c20416ca2ffd7e44685518ed22  bluetooth.nix
c90d4aff81272b7c80b44cf5ded233569ddc0868b8c4ab078a9685e0b10fb8f7  _bluetooth-predeploy-vm-test.nix
71f23a4a7063d583f311c4921249038ca8469a66ae00bcaaf33f3237b46b3e18  rfc.md
e5d9ae6220b4b765376d6fdcd60b7089270d3793e58a8501b75f3271c8a7580f  review-rfc.md
```

`origin/master`在本次fetch后未前进；HEAD仍恰在latest base之上一个提交。Revision 5设计源与PASS review-rfc已读取。实现相对HEAD的production/test delta只在：

```text
modules/profiles/hardware/bluetooth.nix
modules/profiles/hardware/tests/_bluetooth-predeploy-vm-test.nix
```

语法与diff gate：

```sh
git diff --check origin/master
nix-instantiate --parse modules/profiles/hardware/bluetooth.nix >/dev/null
nix-instantiate --parse \
  modules/profiles/hardware/tests/_bluetooth-predeploy-vm-test.nix >/dev/null
```

结果：`syntax-and-diff-check pass`。

## 3. Actual Ramen full-target production graph

### 3.1 为什么使用bounded graph projection

直接请求Ramen完整`system.build.etc`会先触发与Bluetooth无关的既有host closure问题：`pkgs.nerdfonts` rename；仅去掉该font closure后又命中既有`pnpm-10.29.2` insecure baseline。RFC明确要求actual Ramen relevant unit tree，而不要求Ramen完整toplevel或无关package closure。

因此以下projection只把`fonts.packages`与`users.users.hlissner.packages`置空，以构建完整systemd tree；随后独立比较unmodified actual Ramen与projection的全部dependency/link graph，而不是假定override无影响：

```sh
nix build --no-link --print-out-paths --impure --expr '
  let
    f = builtins.getFlake (toString ./.);
    c = (f.nixosConfigurations.ramen.extendModules {
      modules = [ ({ lib, ... }: {
        fonts.packages = lib.mkForce [];
        users.users.hlissner.packages = lib.mkForce [];
      }) ];
    }).config;
  in c.system.build.etc'
```

结果：

```text
/nix/store/19dm0lf476hcv63li7vm0yv5acnzhash-etc
```

Graph identity命令比较全部services的`After/Before/Wants/Requires/WantedBy/RequiredBy/PartOf/Conflicts/UpheldBy`，以及全部units的link metadata：

```sh
nix eval --json --impure --expr '
  let
    f = builtins.getFlake (toString ./.);
    a = f.nixosConfigurations.ramen.config;
    p = (f.nixosConfigurations.ramen.extendModules {
      modules = [ ({ lib, ... }: {
        fonts.packages = lib.mkForce [];
        users.users.hlissner.packages = lib.mkForce [];
      }) ];
    }).config;
    normService = s: {
      after = s.after or []; before = s.before or [];
      wants = s.wants or []; requires = s.requires or [];
      wantedBy = s.wantedBy or []; requiredBy = s.requiredBy or [];
      partOf = s.partOf or []; conflicts = s.conflicts or [];
      upheldBy = s.upheldBy or [];
    };
    normUnit = u: {
      wantedBy = u.wantedBy; requiredBy = u.requiredBy;
      upheldBy = u.upheldBy; aliases = u.aliases; enable = u.enable;
    };
    services = builtins.attrNames a.systemd.services;
    units = builtins.attrNames a.systemd.units;
  in {
    serviceCount = builtins.length services;
    sameServiceNames = services == builtins.attrNames p.systemd.services;
    edgeChanges = builtins.filter
      (n: normService a.systemd.services.${n} != normService p.systemd.services.${n})
      services;
    unitCount = builtins.length units;
    sameUnitNames = units == builtins.attrNames p.systemd.units;
    linkChanges = builtins.filter
      (n: normUnit a.systemd.units.${n} != normUnit p.systemd.units.${n})
      units;
  }'
```

结果：

```json
{"edgeChanges":[],"linkChanges":[],"sameServiceNames":true,"sameUnitNames":true,"serviceCount":82,"unitCount":105}
```

以同一normalizer继续比较targets、sockets、paths、timers与slices：

```json
{"paths":{"changes":[],"count":0,"sameNames":true},"services":{"changes":[],"count":82,"sameNames":true},"slices":{"changes":[],"count":3,"sameNames":true},"sockets":{"changes":[],"count":7,"sameNames":true},"targets":{"changes":[],"count":8,"sameNames":true},"timers":{"changes":[],"count":2,"sameNames":true}}
```

`multi-user.target`、vendor TLP/TLP-sleep、base/template、post-resume及两个stock rfkill units这8个ordering-relevant unit derivation/store paths在actual与projection之间也逐项相同。

实际Ramen未覆盖求值还直接给出：

```text
systemd=/nix/store/ckb44g2gn1ma5y47kh2bhk0zximhgqyi-systemd-258.7
tlp=/nix/store/n9424da80zhp6939f3kijl31kzww7kj9-tlp-1.8.0
helperWantedBy=[]
helperAfter=["tlp.service"]
tlpWants=["bluetooth-rfkill-unblock.service"]
templateAfter=["tlp.service"]
systemdRfkillServiceEnable=false
systemdRfkillSocketEnable=false
tlpSleepPostStop=""
```

这使full-target ordering结论使用actual Ramen graph，而font/user package override只隔离与graph无关的已知baseline。

### 3.2 Pinned full-target diagnostic gate

执行：

```sh
units=/nix/store/19dm0lf476hcv63li7vm0yv5acnzhash-etc/etc/systemd/system
systemd=/nix/store/ckb44g2gn1ma5y47kh2bhk0zximhgqyi-systemd-258.7

set +e
output=$(LC_ALL=C SYSTEMD_COLORS=0 SYSTEMD_UNIT_PATH="$units" \
  "$systemd/bin/systemd-analyze" verify multi-user.target 2>&1)
rc=$?
set -e
printf '%s\n' "$output"
printf 'status=%d diagnostic-bytes=%d\n' "$rc" "${#output}"
test "$rc" -eq 0
if printf '%s\n' "$output" \
  | rg -i 'ordering cycle|found .* cycle|job .* deleted to break ordering cycle'; then
  exit 1
fi
```

结果：

```text
status=0 diagnostic-bytes=0
cycle-diagnostic=absent
```

完整tree的`multi-user.target.wants/tlp.service`存在；`multi-user.target.wants/bluetooth-rfkill-unblock.service`不存在。`tlp.service`和`tlp-sleep.service`都直接symlink到上述pinned TLP 1.8.0 vendor files，verify binary来自上述pinned systemd 258.7。

为了证明scanner不会再次把status 0误判为PASS，对旧production graph运行完全相同的命令与regex：

```text
multi-user.target: Found ordering cycle: bluetooth-rfkill-unblock.service/start after tlp.service/start after multi-user.target/start - after bluetooth-rfkill-unblock.service
multi-user.target: Job bluetooth-rfkill-unblock.service/start deleted to break ordering cycle starting with multi-user.target/start
negative-control status=0 cycle-diagnostic-lines=2 scanner=reject
```

因此本次PASS依赖diagnostic text为空，不依赖exit 0本身。

### 3.3 Effective production wiring

对上述完整tree执行read-only assertions：

```text
ramen-static result=pass helper-wanted-by=0 tlp-weak-wants=1 helper-after=tlp.service tlp-sleep-hook=0 post-resume-trigger=1 stock-masks=2
ramen-template udev-instance=%k execstart=/nix/store/ww0rbc9gd48y5498fjh9wf532rsblxan-bluetooth-rfkill-finalize instance-input=0
pinned tlp=/nix/store/n9424da80zhp6939f3kijl31kzww7kj9-tlp-1.8.0 systemd=/nix/store/ckb44g2gn1ma5y47kh2bhk0zximhgqyi-systemd-258.7
```

文件hash：

```text
tlp.service d9d927639129eb976ec7cef9d14690ed01f1c122106a4d864edf4227ce25b0da
helper      a00121b7d8a71ecb7948e52ee1a3b3fd2b05427f13aae815f98ef65449b4486b
template    d1be70aad155ceaaf7c8a4dd4e299d0f09760d50dee2ba2bb1ac26c651bfc533
```

具体断言：

- vendor `tlp.service`保留`After=multi-user.target NetworkManager.service`、`Type=oneshot`、`RemainAfterExit=yes`、`ExecStart=.../sbin/tlp init start`和`WantedBy=multi-user.target`；
- generated drop-in唯一的Bluetooth dependency是weak `Wants=bluetooth-rfkill-unblock.service`，无`Requires/PartOf/ExecStartPost`；
- generic helper没有`[Install]`/multi-user WantedBy，且`After=tlp.service`；
- udev exact rule只出现一次：`SYSTEMD_WANTS+="bluetooth-rfkill-unblock@%k.service"`；
- template service section的唯一`ExecStart`为上述finalizer，无参数、shell、`%i/%I`、instance-derived environment；`%I`只出现在Description；
- vendor `tlp-sleep.service`及generated drop-in均不含`bluetooth-rfkill-unblock`；
- generated `post-resume-start`恰有一次`systemctl --no-block restart bluetooth-rfkill-unblock.service`；
- `systemd-rfkill.service`与`.socket`均symlink到`/dev/null`。

## 4. Fresh faithful VM rebuild

### 4.1 Build与rebuild

先生成当前output，再用`--rebuild`强制独立重建并比较结果：

```sh
nix build --no-link --print-out-paths --impure --expr '
  let
    f = builtins.getFlake (toString ./.);
    deps = f.nixosConfigurations.axiom.config.system.extraDependencies;
    matches = builtins.filter
      (x: x.name == "vm-test-run-bluetooth-predeploy-integration") deps;
  in if builtins.length matches == 1 then builtins.head matches
     else throw "expected exactly one Bluetooth predeploy VM test"'

nix build --rebuild --no-link --print-out-paths --impure --expr '
  let
    f = builtins.getFlake (toString ./.);
    deps = f.nixosConfigurations.axiom.config.system.extraDependencies;
    matches = builtins.filter
      (x: x.name == "vm-test-run-bluetooth-predeploy-integration") deps;
  in if builtins.length matches == 1 then builtins.head matches
     else throw "expected exactly one Bluetooth predeploy VM test"'
```

结果：

```text
checking outputs of '/nix/store/73h64m7rd6hqppcizp8v1zpfy49rrmvw-vm-test-run-bluetooth-predeploy-integration.drv'...
/nix/store/azvr6yf5mxla58l4as55fvlwf10bwafc-vm-test-run-bluetooth-predeploy-integration
test script finished in 48.82s
```

### 4.2 Fixture fidelity

VM node由默认`start_all()`启动后等待完整`multi-user.target`，从未手工启动boot helper。fixture使用`pkgs.tlp.overrideAttrs`只替换`sbin/tlp`；fresh log中的实际comparison命令把fixture和vendor output path规范为`@TLP@`后，对`tlp.service`与`tlp-sleep.service`分别`cmp -s`成功：

```text
fixture TLP: /nix/store/ipf7p5jgp90zsyvl423s3m23069kd9wc-tlp-vm-fixture-1.8.0
vendor TLP:  /nix/store/6ccrgfnlhm8869jp2y3v7p0cbabp5kr0-tlp-1.8.0
vendor unit comparisons: 2/2 pass
```

VM runtime还直接断言effective TLP `After`同时含`multi-user.target`、`NetworkManager.service`和fixture-only init dependency，保留oneshot/RemainAfterExit/enablement；full-target verify的status与diagnostic text、PID 1 boot journal都通过相同cycle scanner。

### 4.3 Runtime scenarios与InvocationIDs

Fresh summary原文：

```text
tlp-rfkill verify-status=0 boot=62be042a30a44bbd8f8d156a9d25a2c6,48ef90fe33254003ab5817a0f0ff5f87 init-failure=d8597ce2dc81479cb12f32674e285416,829f96afc5c84f3e992598df7ebc3483 init-timeout=ab804d6a080b4a1bb91f960504820838,4c12434a413748359d0e6b407ffea505 init-restore=f7827791c7094f8cbb60890fa0b256d7,368c2ee1ea034d62ac1b4f522f1777b5 noop=48a7bfb03eb0478abd644e0aeb65a451,75637d3c581d4a0e8e23e3947110dca8 add=79e3f2a6a3e0492aa2c25ba5ab118816 concurrent=3a9e6495b54a424390667855712976d3,96d7e8fc940b4ba0806e56325a08fb9f,62b5646c358b4425a3d7ed7178b65776 concurrent-jobs=3 helper-failure=d3c4e57df6ca497386d4db542760e7b0 recovery=8630082a6e824c06b6c4a7b330b1c714 resume=a6ea3cf7426543d099f5790eed8773fb,522fd2f9e077478d8cd6e087f38604f2,4f903414f1764bca96ac694568244985,status:0 resume-failure=df20c7cc5d6049ba8612257d824db0ec,8d7a551866c948e398902de3b5ce31da,9e574a2b6c75493e8e39916a080ea90f,status:0 stock=masked wlan-delta=0 tlp-state-delta=0 result=pass
```

独立parser确认该行22个32位hex InvocationID全部唯一。覆盖结果：

1. **Boot success**：TLP ID与base helper ID不同；`init-end` monotonic timestamp严格早于helper第一条finalizer journal，Bluetooth soft最终为0。
2. **Init non-zero**：TLP保持`Result=exit-code/ActiveState=failed`；weak-Wants helper仍获得新ID并在failure-end之后运行。
3. **Init timeout**：runtime drop-in只把`TimeoutStartSec`缩为2秒；TLP保持`Result=timeout`；helper在timeout-end之后取得新ID并成功。
4. **Recovery/no-op**：正常TLP restore与helper重新成功；already-unblocked和no-device各有新ID，rfkill write count不变。
5. **ADD**：真实`hci_vhci`/pinned `btvirt`经udev产生`@rfkill0`新ID，base ID不变。
6. **Concurrent ADD**：hold base后，两个新的真实kernel rfkill devices产生`@rfkill1`与`@rfkill2`；PID 1同时列出三个jobs，三个InvocationID不同，证明不会与base或彼此coalesce。
7. **Helper failure/recovery**：command failure得到独立failed ID；reset后新ID成功。
8. **Resume success/failure**：走真实`sleep.target → systemd-suspend → suspend.target → post-resume.service`边；只替换sleep executor。两种variant都满足`tlp resume end < post-resume trigger/new base helper journal`。failure variant的vendor `tlp-sleep.service`明确`Failed with result 'exit-code'`，而post-resume/helper仍独立完成；summary中的`status:0`是post-resume/helper gate，不是把TLP failure改写为success。

Fresh journal直接包含：

```text
tlp-fixture phase=init-failure-end result=failed
tlp-fixture phase=init-timeout-end result=timeout
tlp-fixture phase=resume-end result=success
tlp-sleep.service: Deactivated successfully.
tlp-fixture phase=resume-failure-end result=failed
tlp-sleep.service: Failed with result 'exit-code'.
```

### 4.4 Mask与byte/hash invariants

开始、结束及中间场景均要求stock service/socket为masked、inactive、无InvocationID；stock journal也不得有`_SYSTEMD_INVOCATION_ID`。

全部TLP boot/init/add/concurrency/failure/resume场景前后先`cmp -s`，再比较hash：

```text
wlan-live-sha256      d1ba2e662226cc2d1e7a9a0de0aedd52fd97c75f07e9022077687a31cc0db82f
wlan-hard-sha256      9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
wlan-persisted-sha256 381776e915ef1f30b8178d142536f3fa8add596a1a3c8b2cd07a1796c13a1a57
tlp-state-sha256      015710a32fc66b2426abb2a2f8941e0272bdc8710c437a49327b55d9343ee4ad
tlp-config-sha256     e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

结果：`wlan-delta=0 tlp-state-delta=0`。WLAN soft/hard、含NUL与非UTF-8 sentinel的persisted bytes、TLP state及actual generated `/etc/tlp.conf`均未变化。

## 5. Previously approved regression gates

### 5.1 Owner-query与focused Nix checks

直接verbose test：

```sh
PYTHONDONTWRITEBYTECODE=1 python3 \
  modules/profiles/hardware/tests/test-bluetooth-auth-agent.py \
  modules/profiles/hardware/bluetooth-auth-agent.py -v
```

结果：18-test suite为17 pass、1 expected skip（宿主无Nix提供的PyGObject）。四条指定owner-query regression及initial-query failure均显示`ok`：post-Register、post-Default、Release、replacement、initial absent path继续fail closed。

Nix环境fresh rebuild：

```sh
nix build --rebuild --no-link --print-out-paths --impure --expr '
  let f = builtins.getFlake (toString ./.);
  in builtins.filter
    (x: x.name != "vm-test-run-bluetooth-predeploy-integration")
    f.nixosConfigurations.axiom.config.system.extraDependencies'
```

结果：

```text
/nix/store/aqxa28jb3jycydivlrn15q5j74z7jris-blueman-auth-agent-tests
/nix/store/hccblp3r8w6jhp2qy0rnq53p5ra170f2-bluetooth-rfkill-finalize-tests
/nix/store/mhnqm0c0ay9kp01f0y8xa4gwf3xp5c43-caelestia-bluetooth-policy-test
```

Auth log：18 unit tests无skip通过、pinned import通过、private D-Bus integration为：

```text
private-dbus-auth-agent: interactions=7 notify=0 state-delta=0 path-boundary=pass result=pass
```

Rfkill focused log：

```text
isolated-systemd-rfkill: invocations=20 result=pass
systemd-rfkill-vendor-audit: .../systemd-258.7/.../systemd-rfkill.service result=no-exec-stop-post
```

### 5.2 Ordinary real-systemd、auth与privacy

同一fresh VM的ordinary node保持Revision 4场景：

```text
real-systemd-rfkill invocations=16 service-results=success:14,exit-code:2 finalizer-failures=1 wlan-delta=0 result=pass
```

独立parser确认16个InvocationID全部唯一。normal/CHANGE、adversarial reactivation、restart、startup/runtime failure、shutdown、queued CHANGE、no-device和finalizer failure均继续通过。

Revision 5前后Axiom generated ordinary files逐字节比较通过：base helper、`systemd-rfkill.service.d/overrides.conf`、udev rule、post-resume unit共4个文件byte-identical。其SHA-256依次为：

```text
33c1cc53287f838ffd02ce6fd944deb0435ead28f9f6137dfb8db740c202309e
9a16bf6625300c0a93364edb2ab9b87af35223e41e5e9e5520a3c0f40b5a8d21
1d98cfc9ee0d9e31a2ae88ccfd158e716ae0e6b6ad6294ce9445f28f6bfb467d
b200fbfb570ccb7f9869f5600e09403e065d36f5c432a7c8d9175b9dd453b14f
```

Generated auth/privacy summary：

```text
generated-auth-unit invocations=7b23dc5dd76e4fcaa2f31a0a06e78489,147d511403fa439cb89fd45f6ae52ff9 interactions=7 ready=2 notify=0 qml-memory-delta=0 state-delta=0 result=pass
caelestia-notifs memory-sha256=6d86ba398b97faa09037e2b9426e4c09905951cfa9c52471b92d282a52f73ea2 state-sha256=6d86ba398b97faa09037e2b9426e4c09905951cfa9c52471b92d282a52f73ea2
```

完整fresh VM log扫描：cycle/job-deleted diagnostic为0；PIN/passkey/MAC/object-path sentinel为0。

### 5.3 Caelestia

Policy derivation fresh rebuild通过。当前package：

```text
/nix/store/048agagnby3hli9jbbyldiglxx70v0kh-caelestia-shell-1.0.0
```

Source与installed `BluetoothPolicy.js`逐字节相同：

```text
bfd4c89d62072cf69817b5038698a2b442d426e4501368a707590a6bfe7cf291
```

Installed `Bluetooth.qml`恰有一次`BluetoothPolicy.primaryDevices(Bluetooth.devices.values, 5)`。Fixture继续断言主列表排序/截断及anonymous policy，同时要求full pairing page保留`filter(d => !d.bonded)`、不引用`BluetoothPolicy`、不`.slice(0,5)`且不按human name过滤。

## 6. Five-host与synthetic boundaries

### 6.1 五台Bluetooth hosts

对`axiom/azar/harusame/ramen/udon`逐台focused eval。为避免已知font、pnpm与Godot package closure，求值只清空各host的font/user package lists；Bluetooth、Caelestia和全部Bluetooth-related systemd options保持production值。执行：

```sh
nix eval --json --impure --expr '
  let
    f = builtins.getFlake (toString ./.);
    names = [ "axiom" "azar" "harusame" "ramen" "udon" ];
    userOf = n: if builtins.elem n [ "axiom" "azar" ] then "c1" else "hlissner";
    cfg = n: (f.nixosConfigurations.${n}.extendModules {
      modules = [ ({ lib, ... }: {
        fonts.packages = lib.mkForce [];
        users.users.${userOf n}.packages = lib.mkForce [];
      }) ];
    }).config;
    one = n: let
      c = cfg n;
      s = c.systemd.services;
      a = c.systemd.user.services.blueman-auth-agent;
    in {
      name = n; user = c.user.name;
      bluetooth = builtins.elem "bluetooth" c.modules.profiles.hardware;
      caelestia = c.modules.desktop.caelestia.enable;
      blueman = c.services.blueman.enable; tlp = c.services.tlp.enable;
      auth = [ a.wantedBy a.partOf a.after a.unitConfig.ConditionUser a.serviceConfig.Type ];
      helperWantedBy = s.bluetooth-rfkill-unblock.wantedBy or [];
      helperAfter = s.bluetooth-rfkill-unblock.after or [];
      template = s ? "bluetooth-rfkill-unblock@";
      execStopPost = s.systemd-rfkill.serviceConfig.ExecStopPost or [];
      tlpWants = s.tlp.wants or [];
      tlpSleepHook = s.tlp-sleep.postStop or null;
      checks = map (x: x.name) c.system.extraDependencies;
    };
  in map one names'
```

每台随后构建actual selected system/user unit derivations与Caelestia package。

共同结果：

- Bluetooth profile=true、Caelestia=true、`services.blueman.enable=false`；
- user依次为`c1/c1/hlissner/hlissner/hlissner`；
- auth unit均`WantedBy/PartOf/After=graphical-session.target`、`Type=notify`、ConditionUser正确；
- 四台ordinary host：helper `WantedBy=multi-user.target`、无TLP After/template、唯一stock ExecStopPost finalizer；
- Ramen：helper WantedBy为空、After TLP、template=true、TLP weak Wants、stock service/socket disabled、TLP sleep hook为空、post-resume restart存在；
- 每台均引用四个focused checks和同一patched Caelestia package。

Selected build outputs：

```text
/nix/store/fyzzxhmxlg6y40gj35ph7zzn2zchq7jv-unit-bluetooth-rfkill-unblock-.service
/nix/store/z8ccd3wmmijh6i1lz3bsw1cd8sdmdfj0-unit-bluetooth-rfkill-unblock.service
/nix/store/70nz7mk92x6ix31pdagf617cd5g5qv5m-unit-bluetooth-rfkill-unblock.service
/nix/store/f8yvvhgqkmj6rhkgdiii5j9j29ba1pzg-unit-bluetooth-rfkill-unblock.service
/nix/store/wz2xnww921w55bh1x3b18bkjg6gsxz20-unit-blueman-auth-agent.service
/nix/store/kiq74dqy3bs4qsrka1zairahbzsd6dl5-unit-blueman-auth-agent.service
/nix/store/048agagnby3hli9jbbyldiglxx70v0kh-caelestia-shell-1.0.0
```

### 6.2 Synthetic Caelestia-off/Bluetooth-on

```sh
nix build --no-link --print-out-paths --impure --expr '
  let
    f = builtins.getFlake (toString ./.);
    c = (f.nixosConfigurations.axiom.extendModules {
      modules = [ ({ lib, ... }: {
        modules.desktop.caelestia.enable = lib.mkForce false;
      }) ];
    }).config;
  in c.system.extraDependencies ++ [ c.system.build.etc ]'
```

结果：`/nix/store/s3p6lwkh1mwj6cirk4bfvl37m2gn10hi-etc`及auth/rfkill/VM checks通过。Generated tree有auth与ordinary helper、无TLP template；Caelestia=false、Blueman=false。

### 6.3 Bluetooth-off / Atlas

Focused unmodified eval：Bluetooth=false、Caelestia=true、Blueman=false、auth/helper/template均不存在、无Bluetooth udev target，extraDependencies只有Caelestia policy test。

Atlas完整etc的普通build被latest baseline `docker-28.5.2` insecure policy拒绝；该失败未隐藏。作为额外结构检查，在单次命令显式`NIXPKGS_ALLOW_INSECURE=1`后构建得到：

```text
/nix/store/dpi2sqd0bhh18j36684hx9gjjak1z68z-etc
/nix/store/mhnqm0c0ay9kp01f0y8xa4gwf3xp5c43-caelestia-bluetooth-policy-test
```

对该tree复核仍无auth、base/template helper或Bluetooth udev target。Docker allowance只跨过已记录的unrelated package policy；Bluetooth-off verdict以未放宽policy的focused eval为准，该tree只作补充结构证据。

## 7. Axiom full toplevel

执行：

```sh
nix build --no-link --print-out-paths --impure \
  "path:$PWD#nixosConfigurations.axiom.config.system.build.toplevel"
```

结果：

```text
/nix/store/4866d0d8l91b4g5vhrwi84zldsqsfqh4-nixos-system-axiom-25.11.20260630.b6018f8
```

`nix-store --query --requisites`确认closure包含本次fresh VM和三个focused checks：

```text
/nix/store/aqxa28jb3jycydivlrn15q5j74z7jris-blueman-auth-agent-tests
/nix/store/azvr6yf5mxla58l4as55fvlwf10bwafc-vm-test-run-bluetooth-predeploy-integration
/nix/store/hccblp3r8w6jhp2qy0rnq53p5ra170f2-bluetooth-rfkill-finalize-tests
/nix/store/mhnqm0c0ay9kp01f0y8xa4gwf3xp5c43-caelestia-bluetooth-policy-test
```

未激活generation。

## 8. Non-blocking latest-base baselines

以下失败发生在Bluetooth外的host-wide closure，不由Revision 5引入，也未通过production修改掩盖：

- Ramen直接完整etc：先命中`pkgs.nerdfonts` rename；隔离font后命中`pnpm-10.29.2`既有CVE policy；
- Harusame/Udon broad service/package closure：`godot_4-export-templates`已rename为`godot_4-export-templates-bin`；
- Atlas完整etc：`docker-28.5.2`被标记insecure/unmaintained；
- eval中存在既有`xorg.xrandr`rename warning。

这些baseline不影响actual Ramen graph identity/full-target diagnostic gate、focused five-host assertions或Axiom full build；仍应由各自维护任务处理。

## 9. Evidence boundary与deploy-only residuals

Pre-deploy VM使用真实NixOS PID 1、pinned vendor TLP/systemd units、完整multi-user transaction、真实systemd jobs/journal/InvocationID、真实hci_vhci/btvirt rfkill ADD及production projection。Fake TLP executable、fake sleep executor、bounded rfkill value tree和sentinel files是明确的test seam，不替代硬件维护窗口。

仅剩以下deploy-only residuals：

1. **Ramen真实TLP hardware**：reboot后确认journal无cycle/job deletion、vendor TLP init完成后出现base helper新InvocationID且Bluetooth soft=0；制造至少两个distinct tagged rfkill ADD并观察不同template ID；suspend/resume两次，证明TLP resume完成后post-resume产生新base ID；全过程stock units masked、WLAN soft/hard/persisted bytes与真实TLP state不变。
2. **Axiom session/auth/privacy**：真实UWSM/Wayland环境中的generated user unit、GTK/schema/session bus/default/READY与private PATH/XDG；真实pairing的local-only dialogs、Caelestia history/`notifs.json`、Notify monitor与journal sentinel；真实Release及BlueZ restart恢复。
3. **Axiom MediaTek/rfkill/power**：维护窗口执行late unbind/rebind、真实`/dev/rfkill`与persisted state、每个ordinary InvocationID的main→ExecStopPost链；reboot一次、suspend/resume两次，WLAN不变且Caelestia可off→on。
4. **其余主机smoke**：agent active/default、无旧Blueman/Rofi surface、ordinary finalizer effective、Bluetooth soft=0；未自然覆盖的Agent1请求类型继续记录为residual。

## 10. Definitive verdict

**PASS**。RFC Revision 5的production Ramen cycle修复、weak-Wants boot wiring、instance-safe per-device template与post-resume恢复均由actual full-target graph、negative control及fresh faithful VM独立证明；previously approved gates在latest `origin/master`上保持通过。可以进入新的只读`review-change`；部署仍受第9节真实硬件gate约束。

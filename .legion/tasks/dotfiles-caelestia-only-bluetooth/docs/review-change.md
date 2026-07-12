# Final Change Review：Caelestia-only Bluetooth Control（RFC Revision 5）

> 日期：2026-07-12
> 结论：**PASS**
> Security lens：**已应用**（Agent1 authentication、system/session D-Bus、root rfkill、TLP、日志与notification隐私边界）

## Findings

**无blocking findings。** Revision 5关闭了此前唯一未关闭的Ramen ordering-cycle blocker；owner-query与rebase/auth-mini blocker保持关闭。完整current diff中未发现新增correctness、security、maintainability或scope blocker。

### Prior blocker disposition

| 前次 blocker | 最终结论 | 独立复核 |
|---|---|---|
| Ramen production ordering cycle与失真的TLP VM | **CLOSED** | Actual Ramen graph中base helper不再由`multi-user.target`直接Wants；`tlp.service` weak-Wants helper，helper单向`After=tlp.service`。完整`multi-user.target` verify为status 0、diagnostic bytes 0；fresh faithful VM保留pinned vendor TLP edges并通过默认boot、failure、ADD concurrency与真实post-resume graph。 |
| owner-query未知故障留下active但无Agent | **CLOSED** | Auth source/tests与上次关闭该finding的HEAD版本逐字相同。非`NameHasNoOwner`查询错误仍进入`OwnerQueryFailed`、逆序cleanup并exit 1；fresh host与Nix tests均通过。 |
| rebase/auth-mini范围外回退 | **CLOSED** | Fetch后`HEAD^=origin/master=a26019e4`；`packages/auth-mini`无diff。相对latest base的27个路径全部属于task docs或批准的Bluetooth/Caelestia/visible-surface范围。 |

## Independent evidence

### 1. Actual Ramen full target graph

当前Revision 5 source hashes与PASS `test-report.md`记录完全一致。为隔离既有font/user-package closure baseline，构建bounded Ramen `system.build.etc`后，重新把projection与未覆盖的actual Ramen配置逐项比较：

- 82个services与105个units的名称完全相同；dependency edge changes与link changes均为空；
- `multi-user.target`、TLP/TLP-sleep、base/template、post-resume及两个stock rfkill units的8个unit derivation path在actual与projection之间逐项相同；
- actual Ramen值为`helperWantedBy=[]`、`helperAfter=["tlp.service"]`、`tlpWants=["bluetooth-rfkill-unblock.service"]`、`templateAfter=["tlp.service"]`；stock systemd-rfkill service/socket仍disabled，`tlp-sleep.postStop`为空。

对生成的完整tree `/nix/store/19dm0lf476hcv63li7vm0yv5acnzhash-etc`使用pinned systemd 258.7重新执行：

```sh
LC_ALL=C SYSTEMD_COLORS=0 \
  SYSTEMD_UNIT_PATH=/nix/store/19dm0lf476hcv63li7vm0yv5acnzhash-etc/etc/systemd/system \
  /nix/store/ckb44g2gn1ma5y47kh2bhk0zximhgqyi-systemd-258.7/bin/systemd-analyze \
  verify multi-user.target
```

结果为`status=0 diagnostic-bytes=0`，且cycle/job-deletion scanner无命中。tree中存在`multi-user.target.wants/tlp.service`，不存在`multi-user.target.wants/bluetooth-rfkill-unblock.service`；vendor TLP仍有`After=multi-user.target NetworkManager.service`，其drop-in只有weak `Wants=bluetooth-rfkill-unblock.service`，base/template均只单向`After=tlp.service`。旧target→helper回边已实际消失，不是仅靠退出码判定。

### 2. Faithful TLP VM

Fresh `--rebuild`通过：

```text
/nix/store/azvr6yf5mxla58l4as55fvlwf10bwafc-vm-test-run-bluetooth-predeploy-integration
```

Fixture从`pkgs.tlp`派生且只替换`sbin/tlp`行为；fresh log中规范化output path后，`tlp.service`与`tlp-sleep.service`均与pinned vendor unit逐字比较通过。VM由默认boot进入完整`multi-user.target`，没有手工启动boot helper，并同时检查verify status、diagnostic text与PID 1 journal。

Fresh run取得22个唯一InvocationID，覆盖：TLP init success/non-zero/timeout及独立helper结果、boot ordering、no-device/already-unblocked、真实udev ADD、base加两个不同`@rfkillN`的三个并发job、helper failure/recovery，以及TLP resume success/failure后的新post-resume base invocation。全程stock systemd-rfkill保持masked且无InvocationID，`wlan-delta=0`、`tlp-state-delta=0`，无cycle/job-deleted诊断。此前失真的fake-unit fixture问题已关闭。

### 3. Owner-query、auth与privacy regressions

- `bluetooth-auth-agent.py`与owner-query tests的working-tree object hash均等于HEAD；Revision 5没有改动该安全边界。
- Fresh direct suite：18 tests中17 pass、1个仅因宿主缺PyGObject而expected skip。
- Fresh Nix rebuild `/nix/store/aqxa28jb3jycydivlrn15q5j74z7jris-blueman-auth-agent-tests`：18 tests无skip通过，private-D-Bus integration为`interactions=7 notify=0 state-delta=0 path-boundary=pass`。
- Fresh VM generated user unit完成两次READY与7个interaction；desktop Notify、Caelestia memory/state delta及完整PIN/passkey/MAC/object-path sentinel扫描均为0。

因此unknown owner query仍fail closed并由generated `Restart=on-failure`恢复；单system-connection identity、local-only GTK dialogs、逆序cleanup与无payload日志均未回归。

### 4. Complete diff、behavior与scope

- Fetch后的latest `origin/master`为`a26019e4a6c86b8533bd7051e1871bb1df805380`；HEAD为其直接子提交`6c69b7732f232a91ca511e5faee1e8730cb4b53c`。`git diff --check origin/master`通过。
- 完整diff共27个路径，allowlist外为0；没有auth-mini、其他host、dependency pin或无关应用修改。Revision 5 working-tree implementation delta只在`bluetooth.nix`与faithful VM，另有对应RFC/evidence docs。
- 五台Bluetooth host的focused eval继续显示profile/Caelestia=true、stock Blueman=false、auth unit与ConditionUser正确；四台ordinary host保持multi-user helper与唯一ExecStopPost，只有Ramen使用TLP weak-Wants/template分支。Atlas/Bluetooth-off无auth/helper/template。
- Fresh Axiom完整toplevel build通过：`/nix/store/2zs4qp6r85fkkg182pj2xnqa9k27yvca-nixos-system-axiom-25.11.20260630.b6018f8`。
- Rofi Bluetooth入口、Blueman manager Hyprland rules及stock package/service surface保持删除；Caelestia同源policy、installed wiring、主列表排序/截断和完整pairing page边界未回归。

跨host未隔离的broad eval仍会命中既有Godot rename；报告记录的Ramen font/pnpm、Atlas Docker policy与`xorg.xrandr` warning同样不由本change引入。隔离这些package-list baseline后的Bluetooth-focused graph/eval全部通过，未用production修改掩盖失败。

## Security-readiness assessment

未发现新增提权、用户输入进入root command、secret disclosure或activation-surface回归。Runner继续以配置用户运行且只持有一条system-bus connection；private Blueman runtime未进入system/session D-Bus、systemd或public XDG/PATH surface。Root base/template只执行同一immutable、无参数的Bluetooth finalizer；`%k/%I`只决定unit identity/Description，不进入`ExecStart`、Environment或shell。Finalizer仍只调用`rfkill unblock bluetooth`，不触碰WLAN、hard block或TLP state。

## Non-blocking suggestion

`bluetooth.nix`与`caelestia.nix`中的纯验证derivation后续可迁移到`system.checks`，避免把大型VM/check output附着到每个generation；这不影响本次行为或交付结论。

## Deploy-only residuals

以下是RFC明确保留的真实环境gate，不是pre-deploy blocker：

1. **Ramen hardware**：reboot后确认journal无cycle/job deletion、TLP init后取得base InvocationID且Bluetooth soft=0；制造至少两个distinct tagged ADD；suspend/resume两次；全过程stock units masked且WLAN live/hard/persisted与真实TLP state不变。
2. **Axiom auth/privacy**：真实UWSM/Wayland环境验证GTK/schema/session bus/default/READY、private PATH/XDG、local-only pairing dialogs、Notify monitor、Caelestia history/`notifs.json`及Release/BlueZ restart恢复。
3. **Axiom MediaTek/rfkill**：维护窗口执行late unbind/rebind、真实`/dev/rfkill`与persisted state、reboot一次及resume两次，确认每个ordinary invocation的ExecStopPost链、Bluetooth soft=0且WLAN不变。
4. **其余主机**：逐台确认agent active/default、无旧Blueman/Rofi surface、ordinary finalizer effective与Bluetooth soft=0；未自然覆盖的Agent1 request类型继续记为residual。

## Delivery readiness

**PASS — ready for delivery，仍须执行上述deploy-only hardware gates。**

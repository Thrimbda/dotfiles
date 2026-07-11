# Change Review：Caelestia-only Bluetooth Control

> 日期：2026-07-12
> 结论：**FAIL**
> Security lens：**已应用**（Agent1 authentication、system/session D-Bus、root rfkill 与隐私边界）

## Findings

### 1. HIGH / BLOCKING — owner 查询故障会留下“active 但无 Agent”的假健康服务

**位置**：

- `modules/profiles/hardware/bluetooth-auth-agent.py:433-444`
- `modules/profiles/hardware/bluetooth-auth-agent.py:518-536`
- `modules/profiles/hardware/bluetooth-auth-agent.py:594-604`

`_safe_current_owner()` 把所有非 `NameHasNoOwner` 的查询异常也压成 `None`。`_activate()` 与 `on_release()` 随后把这个 `None` 当成“已确认 BlueZ 不存在”，既不退出，也不安排重试。

这在 unit 已经发送 `READY=1` 后会形成永久假健康：本地 object 已 unexport、state 为 `absent`，但进程和 systemd unit 仍为 active；若 `RegisterAgent` 已成功而其后的 owner 复查失败，BlueZ 还可能继续持有同一未关闭 connection 上、但已无本地 object 的 registration。没有后续 `NameOwnerChanged` 时，配对能力不会自行恢复。

独立故障注入复现了该状态：先到 `default`，在 owner replacement 的 `RegisterAgent` 成功后令 post-call 及后续 `GetNameOwner` 抛出普通 `RuntimeError`，最终得到：

```text
state=absent owner=None exit_requested=False exit_code=0
```

这违反 RFC 5.5.4/9 的 fail/restart 语义，也未被现有只覆盖 `NameHasNoOwner` 的 fake 覆盖。

**最小修复方向**：区分“明确无 owner”和“owner 查询未知/失败”；只有前者可以留在 `absent` 等待，后者必须完成本地清理并非零退出以关闭 connection、交给 systemd 重启。为 post-Register/post-Default、Release 和 replacement 路径增加普通 owner-query failure 回归测试。

### 2. HIGH / BLOCKING — RFC 要求的 TLP pre-deploy runtime gate 实际缺失

**位置**：

- `modules/profiles/hardware/bluetooth.nix:293-296,327-342`
- `modules/profiles/hardware/tests/_bluetooth-predeploy-vm-test.nix:268-297`
- `.legion/tasks/dotfiles-caelestia-only-bluetooth/docs/rfc.md:547-560`
- `.legion/tasks/dotfiles-caelestia-only-bluetooth/docs/review-rfc.md:80-84`
- `.legion/tasks/dotfiles-caelestia-only-bluetooth/docs/test-report.md:234,288-303`

Revision 4 与 PASS review-rfc 明确要求 Ramen/TLP fixture 通过真实 systemd 覆盖独立 helper 的 boot/add/resume，并证明 masked `systemd-rfkill` 不会被 load/start。仓库中的 VM 只构造 ordinary 分支的自定义 `vm-systemd-rfkill.service/.socket`；整个 tests 目录没有 TLP、生产 `bluetooth-rfkill-unblock.service`、生产 udev rule 或 post-resume 路径的 runtime fixture。

生成 unit/mask 的静态求值是有效证据，但不能证明：

- TLP resume 完成后 helper 才成为最后 writer；
- udev add 在 oneshot helper 已 activating 时不会被 start-job 合并而漏掉第二次收敛；
- boot/add/resume 三条路径均不触碰 masked stock unit，且 WLAN/TLP 状态保持不变。

因此 `test-report.md:292` 的“无 skipped pre-deploy gate”结论不成立；真实硬件 deploy gate不能替代 RFC 已要求的 synthetic pre-deploy gate。

**最小修复方向**：加入使用真实 PID 1 和生产生成 helper/udev/resume wiring 的 TLP fixture，保持 stock service/socket masked，并覆盖 boot、add（包括 helper active 时的 add）、resume-after-TLP、failure 与 WLAN byte/hash invariant。若 fixture 暴露 start coalescing 或 ordering 问题，先退回实现修复，再重新执行 `verify-change`。

### 3. MEDIUM / BLOCKING — 当前审查树落后 `origin/master`，完整 two-dot diff 含范围外基线回退

**位置**：`packages/auth-mini/default.nix:10-14`

当前分支 HEAD `d49234ed` 落后 `origin/master` 一个提交（`a26019e4`）。因此 `git diff origin/master` 还包含把 auth-mini 从 `latest-2026-07-10`/新 hash 回退到 `latest-2026-07-05`/旧 hash 的范围外差异。该文件不是工作区主动修改，但说明最终 PASS build 与本次 fresh rebuild都不在当前 master 基线上。

**最小修复方向**：先更新/rebase 到 `origin/master`，确认 auth-mini 从完整 diff 消失，再在新基线上重跑 focused derivations、VM、主机投影与 Axiom toplevel。

## Non-blocking suggestions

1. `modules/profiles/hardware/bluetooth.nix:344-350` 与 `modules/desktop/caelestia.nix:454` 把纯 build-time checks 放进 `system.extraDependencies`。当前 NixOS 已提供 `system.checks`，更符合“不在 generation 留痕”的用途，也更清楚地区分产品 closure 与验证 gate。
2. `modules/profiles/hardware/bluetooth.nix:225-259` 的 vendor drift gate只检查存在 `ExecStart` 且不存在 `ExecStopPost`，而 VM 在 `_bluetooth-predeploy-vm-test.nix:268-297` 固定重建 Type/socket/timeout。当前 pinned systemd 258.7 已人工核对，但建议把依赖的 effective vendor invariants做成 fail-closed assertions，避免未来 systemd 更新后 fixture仍自证通过。

## Independently checked evidence

- 已读取 stable plan、RFC Revision 4、PASS review-rfc、最终 test report，以及相对 `origin/master` 的 tracked/untracked complete change。
- fresh `--rebuild`：
  - `vm-test-run-bluetooth-predeploy-integration` PASS，38.18s；16 个真实 systemd InvocationID，`success:14/exit-code:2`，WLAN delta 0。
  - auth tests PASS（13 unit + private-D-Bus integration）。
  - rfkill finalizer/model/vendor audit PASS。
  - Caelestia policy/installed-source check PASS。
- fresh VM 证据确认 generated auth unit 两次不同 InvocationID、`Type=notify`、7 个 Agent1 interaction、desktop Notify=0、QML memory/state delta=0；对完整 fresh VM log 的 PIN/passkey/MAC/object-path sentinel 扫描为 0。
- 五台 Bluetooth 主机求值为 profile=true、Caelestia=true、stock Blueman=false、auth unit=true；Ramen 为 TLP 分支。Atlas/no-Bluetooth 为 auth unit=false。
- Axiom generated unit确认 `ConditionUser=c1`、`WantedBy/PartOf/After=graphical-session.target`、`Type=notify`；runner PATH不含 Blueman `bin`，private runtime只进入进程级 Python/schema边界。
- Axiom ordinary generated tree只有一条 Bluetooth finalizer drop-in；Ramen stock service/socket为 mask，helper独立。生成 tree中未发现 stock Blueman applet/manager/tray/mechanism activation surface。
- Caelestia production patch调用同源 `BluetoothPolicy.primaryDevices(..., 5)`；patch apply、installed source compare和完整 pairing page invariant均 fail-closed/通过。

这些正向证据可信地关闭了当前 fixture 所覆盖的 privacy、ordinary systemd ordering、WLAN 与 visible-surface问题，但不能覆盖 Finding 1 的未测试异常路径或 Finding 2 缺失的 TLP runtime gate。

## Security-readiness assessment

未发现 stock Blueman mechanism/polkit 恢复、root 运行 Caelestia、runner PATH/XDG 暴露 stock UI、WLAN 越界或已覆盖路径中的 pairing secret持久化。local `_NotificationDialog`、固定参数 root finalizer和私有 runtime边界在 fresh evidence中成立。

Finding 1 是 authentication availability/state-integrity blocker：systemd readiness 与实际 Agent1 registration/export状态可以失配。当前没有证据表明存在直接提权或 secret disclosure，但在该状态机问题关闭前不能判定 security-ready。

## Residual deploy-only risks

下列仍是实现与 pre-deploy blockers关闭后的真实部署 gate，不得改写为已验证：

1. Axiom UWSM/Wayland session中的环境、GTK/icon、default/READY和私有 PATH/XDG边界。
2. 真实 pairing、local-only dialog、Caelestia history/`notifs.json`与 journal privacy；真实 Release/BlueZ restart恢复。
3. Axiom MediaTek late rebind、power cycle、两次 resume、真实 `/dev/rfkill` invocation链及 WLAN/hard-block边界。
4. Ramen 的真实 TLP boot/add/resume顺序、masked stock units与 WLAN/TLP byte-level不变。
5. 其余主机逐台确认 agent/default、无旧 surface、Bluetooth soft=0；自然未覆盖的 Agent1 类型继续记录为 residual。

## Delivery readiness

**Not ready for delivery.** 先退回 `engineer` 修复 Finding 1，并补齐 Finding 2 所需 fixture；随后在更新后的 `origin/master` 基线上重新进入 `verify-change`，再做一次只读 `review-change`。当前不可创建 ready-to-merge PR，也不可把部署硬件 gate当作上述 pre-deploy blocker的替代。

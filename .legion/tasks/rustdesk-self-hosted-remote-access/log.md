# RustDesk 自托管远程访问 - 日志

## 会话进展 (2026-07-11)

### ✅ 已完成

- 收敛任务合同并完成首轮 RFC/research
- review-rfc 发现本地 IPC 信任边界与 merge-before-switch 顺序问题
- 用户在安全/维护取舍中选择简化自动部署
- 简化1.4.8设计通过review-rfc
- 三台host配置实现完成
- Acorn/Axiom完整build及Charlie静态/事务验证PASS

(暂无)
### 🟡 进行中

- 初始化任务日志。
- 按 review findings 修订 contract 与 RFC 后重新审查
- 将设计收敛到 RustDesk 1.4.8、逐机 agenix password和最小有限 provisioning
- 提交并rebase配置分支，在Charlie完成Darwin build与store签名预检
### ⚠️ 阻塞/待定

(暂无)

(暂无)
(暂无)
(暂无)
---

## 关键文件

(暂无)
---

## 关键决策

| 决策 | 原因 | 替代方案 | 日期 |
|------|------|----------|------|
| (暂无) | - | - | - |
---

## 快速交接

**下次继续从这里开始：**

1. commit并rebase origin/master
2. push分支后在Charlie build但不switch
3. review-change通过后创建并合并配置PR

**注意事项：**

- 生产switch必须等待配置PR merge
- DNS与Aliyun SG仍是merge后部署gate
---

*最后更新: 2026-07-11 14:01 by Legion CLI*

## 2026-07-11 final review blocker implementation

- 修复 Acorn/Axiom/Charlie 的 secret target 类型、owner/group/mode 校验；consumer 只读取解析后的普通文件。
- 修复 Axiom/Charlie 1.4.8 per-user IPC readiness，并绑定预期 `--server` 进程、PID、socket owner 和 open socket。
- Charlie 增加 revision+boot-bound agenix completion gate；已从 pinned nix-darwin 生成 activation 确认实际 load 顺序仍为 provision -> service -> agenix，gate 在 preActivation 关闭、agenix 成功 EXIT 后发布、postActivation 等待完成。
- Charlie public/provision helper 在每条 RustDesk CLI 路径前执行本地 `codesign` 和 `spctl` gate。
- Cheap checks：3 个 Nix 文件 parse、3 host system drv eval、Linux helper derivation build、generated helper `bash -n`/ShellCheck、activation/order/metadata focused assertions 通过。Acorn/Axiom full toplevel build 与 Charlie Darwin build/signature 仍待 `verify-change`。
- 实现 agent 按职责未 commit、push、deploy 或 switch host；既有未提交 `docs/test-report.md` 修改保持原样，未提前把本轮结果写成新的 PASS。

## 2026-07-12 RustDesk 1.4.9 security revision

- Upstream 1.4.9与CVE-2026-57850确认1.4.8不可继续部署；阶段退回design review，旧1.4.8 PASS/evidence全部标记superseded。
- RFC改为Axiom从同一1.4.9 source显式重建cargoDeps、Charlie pin官方1.4.9 ARM64 DMG，并禁止rollback到`<1.4.9`。
- Public config proof改用fresh-empty caller fallback context与IPC失败负控，避免`--option` local fallback假阳性。
- 两端采用明确的per-revision attempt/stamp状态机；Charlie launchctl parser要求完整service/user-agent fixture与top-level brace-depth语义。
- Round 5 review-rfc初次结果为FAIL；findings已写回RFC，等待新一轮review-rfc。

## 2026-07-12 Round 6 RustDesk 1.4.9 implementation

- Axiom基于锁定的`pkgs.unstable.rustdesk`仅override version/source/cargo hash/cargoDeps；source固定到`6c578292e8ebbbec708b76986ba8c4bc7c509747`并含唯一`libs/hbb_common` submodule，cargo vendor从同一source显式重建。完整1.4.9 package与Axiom toplevel build通过，nixpkgs reproducibility patch、postPatch、依赖和wrapper均保留，`lib/rustdesk/rustdesk`存在且`--version`为1.4.9。
- Charlie改为官方`rustdesk-1.4.9-aarch64.dmg`及批准SRI，保持no-fixup/no-strip/no-resign copy，并在store/staging/destination/runtime gate中验证bundle id、TeamIdentifier和Gatekeeper origin。Linux评估可生成完整Darwin system；本机缺少aarch64-darwin builder，真实bundle build/signature仍留给orchestrator/Charlie。
- 两端public config只在user server与稳定PID/socket存在后由provision执行；每个apply/query使用独立fresh-empty root-owned 0700 HOME/XDG context。当前stamp fast-skip不检查reservation、不需要session且不调用管理CLI；password使用持久root/service context、exact `Done!` ACK，并在restart与IPC proof后才写stamp。
- 两端实现同一per-revision attempt/stamp状态机：canonical metadata/content fail closed，current reservation在readiness/secret前拒绝，reservation在public proof后原子publish、filesystem sync并复核，secret读取和password前再次复核；失败保留reservation，新revision可替换合法stale对象。
- Charlie service与user-agent统一使用brace-depth launchctl parser，只读取顶层state/pid/program/arguments并忽略nested coalition fields；保留UID、command/executable、lsof socket与PID稳定检查。
- Verification：Nix parse/eval、Axiom source/cargo derivation linkage、submodule identity、retained patch application、1.4.9 source CLI/IPC call sites、generated helper `bash -n`/ShellCheck、完整fallback正/负控（IPC阻断时zero secret/reservation/password action）、全部状态表行及directory/symlink/device/FIFO/mode/owner/content malformed cases、完整modern launchctl service/agent fixtures及truncated/duplicate/wrong-field cases均PASS。Acorn与Axiom完整toplevel build PASS；未commit、push、deploy、switch或读取secret。

## 2026-07-12 Round 7 manual-finalize implementation

- Axiom provision/finalize现共享root-owned `flock` operation lock；Charlie共享atomic root-owned lock directory，既有/stale lock不自动清理。两端对current stamp保持lock内fast-skip，并严格拒绝malformed state、stamp、reservation、ready与lock对象。
- Provision在exact `Done!\n`后强制替换全部auth-serving PID、复核public config与稳定identity，只原子发布绑定host/revision/PID/start/executable/UID的`ready-to-finalize`，保留current reservation且不再写stamp。Axiom恢复upstream `pkill -f "rustdesk --"` ExecStop并要求main/user-server双PID替换；Charlie继续要求privileged/user-server双PID替换并以exact `ps` fields hash绑定start identity。
- 两端system PATH新增root-only `rustdesk-provision-finalize --confirm-remote-auth`。Finalizer不包含agenix path、secret resolver或`--password`，在共享lock内重验current reservation/ready/revision与同一live process identities后才sync stamp并移除/sync ready；未实现history或anti-rollback ledger。
- Targeted generated-artifact harness覆盖ACK/restart/post-restart-public失败、双PID未替换、pending reboot/interval replay、exact finalize参数、process drift、并发/stale lock、stale revision fixed-forward，以及Axiom 15 ready + 15 state malformed cases和Charlie 14 ready + 15 state malformed cases，全部PASS。Harness同时发现并修复`publish_revision_object`参数被inspector全局变量覆盖的问题。
- Verification PASS：两端Nix parse/eval、Axiom完整toplevel build、四个generated provision/finalizer的`bash -n`与ShellCheck、finalizer zero-secret/zero-password assertion、Axiom `/proc` start parser、systemd Wants/After/ExecStop、Charlie plist/bundle-id/version/hash assertions。Charlie full aarch64-darwin build与真机launchd/signature/runtime remote-auth仍是orchestrator gate；未连接Charlie，未commit/push/deploy/switch或读取secret。

## 2026-07-12 review finding repair

- Charlie activation现以完整signature/identity/Gatekeeper gate、CDHash和递归内容比较识别相同bundle；相同时不移动或复制app。真正的app/revision transition先bootout并确认旧provision job absent，marker/app失败回滚仍在同一transaction内；service与user-server plist均绑定composite revision。
- Axiom与Charlie均改为先原子publish/sync/revalidate current reservation，再删除/sync stale ready并证明absent，随后重验runtime才允许读取secret；生成脚本的publish rename前/后与ready unlink前/后共20个failure-injection case均证明失败路径zero secret/zero password。
- 三端Nix parse/eval、Axiom完整toplevel build、四个generated provision/finalizer及Charlie activation的`bash -n`/ShellCheck、Charlie plist/完整parser fixture与双PID post-ACK assertions均PASS。Charlie真机bundle/build/launchd/runtime gate仍未执行；未连接host、读取secret、commit、push、deploy或switch。

## 2026-07-12 Charlie pre-merge artifact verification

- `charlie-tunnel`恢复后，只清理了本任务隔离worktree中旧1.4.8 temporary patch；未触碰Charlie主工作区。当前三个host files通过SHA-256确认与本地candidate逐字一致。
- Charlie完整`aarch64-darwin` system build PASS。Store app确认为arm64 RustDesk 1.4.9、bundle id `com.carriez.rustdesk`、Team `HZF9JMC8YN`；deep/strict codesign与Gatekeeper Notarized Developer ID/origin全部PASS。
- `ditto`临时copy保持recursive content、CDHash、签名与Gatekeeper identity；临时copy已删除，未安装到`/Applications`。
- Generated brace-depth parser在Charlie真实完整`launchctl print`输出上通过2-argument server和3-argument service形状，正确忽略nested coalition states；临时jobs均已移除。目标`ps` PID/start identity格式稳定，generated provision/finalizer/activate通过Charlie `/bin/bash -n`。
- 无deploy/switch、无RustDesk app/jobs/mutable state变更、无RustDesk secret读取。隔离worktree仍是detached dirty verification tree并保留`.cache/`，不得用于switch。

## 2026-07-12 final rebase and review

- Feature无冲突rebase到live `origin/master` `0d61c714`并推送新v3 branch，未force-push旧remote history。最终HEAD为`3db55d1c`，ahead 5/behind 0。
- Rebased Acorn、Axiom、Charlie full systems全部build PASS；Charlie final closure继续引用同一已验证RustDesk 1.4.9 store app，exact app verifier与final activation syntax再次PASS。
- Charlie隔离worktree已fetch并detached到exact `3db55d1c`；tracked tree clean，仅有`.cache/`，继续禁止用于switch。
- Final `review-change`无blocking finding并给出**PASS for configuration PR**。DNS/SG、destination install/signature、runtime jobs、password正负测、manual finalize、Wayland/TCC/sleep仍是merge后gate。

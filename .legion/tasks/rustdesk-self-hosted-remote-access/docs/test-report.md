# RustDesk 自托管远程访问：verify-change 测试报告

## Current report — RustDesk Client 1.4.9 pre-merge candidate

> 日期：2026-07-12
> Target：当前未提交worktree及逐字一致的Charlie隔离worktree host files
> Verdict：**PASS — pre-merge implementation/build/signature evidence**
> Deployment：**NOT RUN**；未commit、push、install、deploy或switch，未读取任何RustDesk secret

### Candidate and build evidence

- `nix-instantiate --parse hosts/{acorn,axiom,charlie}/default.nix`，并eval三台system derivation：**PASS**。
- Axiom effective service为`/nix/store/...-rustdesk-1.4.9/bin/rustdesk --service`；完整NixOS toplevel build：**PASS**，output `/nix/store/qd11d8v18lqq6ghwwlv3mwk26d0i0ajn-nixos-system-axiom-25.11.20260630.b6018f8`。
- Charlie完整`aarch64-darwin` system build：**PASS**，output `/nix/store/wva41w464n1qmm6bvg2c1lhv7mp8jjay-darwin-system-25.11.ebec37a`。
- Charlie store app `/nix/store/ll7kiyvhxzqs0j9clqf66a08s262szq0-rustdesk-macos-1.4.9/Applications/RustDesk.app`：arm64、version `1.4.9`、bundle id `com.carriez.rustdesk`：**PASS**。
- Store app `codesign --verify --deep --strict`：**PASS**；Identifier `com.carriez.rustdesk`、TeamIdentifier `HZF9JMC8YN`、Authority/origin `Developer ID Application: zhou huabing (HZF9JMC8YN)`：**PASS**。
- Store app `spctl -a -vv -t execute`：**accepted**，source `Notarized Developer ID`。Generated `rustdeskAppVerify`对同一store app：**PASS**。
- 以`ditto`复制到临时writable destination后，recursive diff、CDHash `b7875331e94925544cf71e9da560a1bc8d581285`、deep/strict signature、Team和Gatekeeper origin均保持一致：**PASS**；临时copy已删除。

### Generated helper and state evidence

- 四个generated provision/finalizer、Charlie activation的`bash -n`与ShellCheck 0.11.0：**PASS**。Finalizer要求exact `--confirm-remote-auth`，且静态/故障测试证明zero secret resolver、zero secret read、zero `--password`。
- 两端state matrix覆盖reservation absent/stale、publish rename前后失败、ready unlink前后失败、success、malformed object、operation-lock exclusion、reboot/interval replay和process drift：**PASS**。
- 新reservation先atomic publish/sync/revalidate，再删除stale ready；任一失败都发生在secret access前。Provision只在ACK、双process replacement、public proof和PID/start identity稳定后发布ready，绝不写stamp：**PASS**。
- Axiom保留upstream等价`ExecStop`，post-ACK root service与user server两个PID都必须更换；完整toplevel build及generated assertions：**PASS**。
- Charlie service/server plist均绑定同一non-secret composite revision，upstream `ProgramArguments`不变；provision plist保持8分钟timeout、300秒interval、`/dev/null`日志和Core=0：**PASS**。
- Charlie activation先卸载旧provision job；verified identical bundle不重复替换，artifact/revision变化会使service/server plist reload；post-ACK仍独立kickstart并要求双PID replacement：**PASS**。

### Charlie target-platform evidence

- Generated brace-depth parser在Charlie `/usr/bin/awk`上解析两个真实完整`launchctl print` user-domain jobs：**PASS**。
- Server形状`/bin/sleep 120`与service形状`/bin/sh -c /usr/bin/yes`均返回唯一真实PID；完整输出含nested environment、resource coalition与jetsam coalition `state`，未误取嵌套字段。两个临时jobs均已移除。
- Charlie `/bin/ps -ww -p PID -o pid= -o uid= -o ruid= -o lstart= -o comm= -o command=`连续两次输出一致，确认ready使用的PID/start identity格式在目标系统可用：**PASS**。
- Exact generated provision/finalizer及完整Darwin activation在Charlie `/bin/bash -n`：**PASS**。
- Charlie隔离worktree已清除旧1.4.8 cumulative patch，并应用当前host diff；Acorn/Axiom/Charlie三个host file的本地与远端SHA-256逐字一致。隔离tree仍为detached dirty verification tree并保留untracked `.cache/`，不得用于switch。

### Remaining gates

1. Reconcile current candidate with live `origin/master`，重新运行eval/build/review并提交、push、创建配置PR。
2. 配置PR merge后只从同一clean merged commit部署；不得从Charlie detached verification tree switch。
3. DNS、Aliyun SG、Acorn/Axiom/Charlie runtime、destination signature、launchd/systemd PID、Wayland/TCC及direct/relay仍需逐机验证。
4. 两端password ACK后先保持reservation+ready、无stamp；从fresh controller完成新密码成功与旧/错误/跨机密码认证拒绝后，才运行`rustdesk-provision-finalize --confirm-remote-auth`。
5. 任一reservation发布后的失败都禁止generation rollback；保持RustDesk停止并fixed-forward到全新revision。

本PASS只授权candidate进入最终`review-change`，不授权merge或deployment。

---

## Historical superseded 1.4.8 report

> **SUPERSEDED / NOT A CURRENT GATE**：本报告只覆盖已禁止的RustDesk 1.4.8 candidate。CVE-2026-57850触发1.4.9安全修订后，本报告的PASS、build/signature identity和runtime instructions均不得用于merge、deploy或rollback。必须在新review-rfc PASS及1.4.9实现完成后生成全新的test report。

> 日期：2026-07-12
> 阶段：配置 PR pre-merge verification（未部署）
> Verification target：candidate tree = committed HEAD `e8dcd484a2c162a9f8bddefa36ebc3f868b3b456` + `hosts/charlie/default.nix` 未提交的单 hunk AWK 换行修复
> Base：`origin/master` `a26019e4a6c86b8533bd7051e1871bb1df805380`
> Verdict：**SUPERSEDED — 1.4.8 evidence is unusable for the current design**
> Deployment status：**NOT RUN**；没有 host 被 switch，本报告只允许 candidate 返回 `review-change`，不授权 merge 或部署
> Secret boundary：未解密或读取 secret plaintext/ciphertext，未读取主工作区凭据，未输出 RustDesk public-key value 或 secret-derived value

## 1. 结论与 scope

**PASS for the candidate tree。** `e8dcd484` 的 committed helper 把 `&&` 放在 AWK 续行开头，GNU Awk 与 nawk 都会在合法输入上语法失败。当前未提交 production fix 只把这 7 个 `&&` 移到前一行末尾；state/PID/program/arguments 的判断 token、identity contract 和 helper 其余流程均未改变。

从 candidate Nix eval 得到 provision plist 所引用的 exact `charlie-rustdesk-provision` derivation，并直接从该 derivation 的 `env.text` 提取 embedded AWK 后：

- GNU Awk 5.3.2：合法 baseline 返回唯一 PID；18 个 invalid samples 全部拒绝。
- nawk 20250116：同一合法 baseline 与 18 个 invalid samples得到相同结果。
- Exact generated helper 的 `bash -n`、ShellCheck 0.11.0、ordering/identity assertions 全部通过。
- 三台 host Nix parse、Charlie system eval 和 3 个 RustDesk plist eval/parse通过。

因此上一版报告的唯一 current pre-merge implementation blocker已关闭；未发现新的 blocker。Production fix仍未提交，`review-change`、PR checks、remote temporary-worktree cleanup及全部 merge 后 runtime gates仍必须完成。

### Candidate identity and worktree scope

- HEAD：`e8dcd484a2c162a9f8bddefa36ebc3f868b3b456`
- merge-base / `origin/master`：`a26019e4a6c86b8533bd7051e1871bb1df805380`
- 相对 `origin/master`：ahead 3、behind 0。
- Production candidate delta against HEAD：仅 `hosts/charlie/default.nix` 一个 hunk，`+8/-8`；该 8 行重排只把 7 个行首 `&&` 分别移到前一条件行末。
- 另一个未提交文件是本报告；verifier未修改 production code，未commit、push、deploy、switch或读取secret。

## 2. Blocker closure

### 2.1 Differential reproduction

从 committed `e8dcd484` Charlie system derivation中重新提取旧 `charlie-rustdesk-provision` AWK。对同一合法 `launchctl print` baseline：

| Generated artifact | GNU Awk 5.3.2 | nawk 20250116 |
|---|---|---|
| committed HEAD parser（续行以 `&&` 开头） | **expected rejection reproduced** | **expected rejection reproduced** |
| candidate parser（前一行以 `&&` 结尾） | **PASS，输出 `4242`** | **PASS，输出 `4242`** |

这证明结果变化来自当前换行修复，而不是测试样例或解释器变化。

### 2.2 Candidate parser matrix

合法 baseline精确包含一个：

- `state = running`
- numeric PID `4242`（大于 1）
- `program = /bin/sh`
- arguments block：`/bin/sh`、`-c`、`/Applications/RustDesk.app/Contents/MacOS/service`

每个解释器均执行 **1 valid + 18 invalid** cases。Invalid matrix：

1. missing / duplicate / wrong state
2. missing / duplicate / PID 1 / nonnumeric PID
3. missing / duplicate / wrong program
4. missing / duplicate / unterminated arguments block
5. missing / extra argument
6. wrong arg0 / arg1 / arg2

两个解释器都只接受合法 case并只输出一个 PID；invalid cases均 nonzero 且无 PID stdout。另有 generated-shape assertion确认 condition 的任何续行都不再以 `&&` 开头。

### 2.3 Identity/PID contract remains intact

Exact generated helper的顺序断言通过：

1. metadata-checked valid stamp仍在 readiness前 fast-skip；
2. readiness后先固定 privileged service PID与user server PID；
3. secret前、password调用前及调用后仍复核同一组PID；
4. password成功后才执行两个 `kickstart -k`；
5. restart后重新等待稳定，要求service/server均为新PID，再复核并原子提交stamp。

当前 source diff未改变上述流程，也未改变 AWK 的 state/PID/program/arguments 判断内容。

## 3. Executed checks

所有 candidate Nix检查使用本地dirty tree：

```text
path:/home/c1/dotfiles/.worktrees/rustdesk-self-hosted-remote-access
```

| Executed command / check | Result | Evidence |
|---|---|---|
| `git status --short`; `git rev-parse HEAD`; `git merge-base HEAD origin/master`; `git rev-list --left-right --count origin/master...HEAD`; `git diff --check` | **PASS** | 确认target/base/topology、仅一个production candidate file与无whitespace error。 |
| `nix-instantiate --parse hosts/{acorn,axiom,charlie}/default.nix` | **PASS 3/3** | Candidate Nix source语法。 |
| `nix eval --raw path:...#darwinConfigurations.charlie.system.drvPath` | **PASS** | Candidate完整Charlie module merge可实例化为system derivation。 |
| Eval service/server/provision plist `text`，以Python `plistlib`解析并断言ProgramArguments、session、timeout、Core和`/dev/null` | **PASS 3/3** | Provision plist引用candidate exact generated helper；privileged service声明仍与parser期望一致。 |
| `nix derivation show --recursive <candidate-system.drv>`定位plist引用的 provision drv；从其`env.text`提取exact helper | **PASS** | 后续不是手抄source片段，而是对candidate generated artifact验证。 |
| Exact helper `env.text | bash -n` | **PASS** | 外层generated shell语法。 |
| Exact helper `env.text | shellcheck -s bash -`，locked ShellCheck 0.11.0 | **PASS** | 无exclusion的focused lint。 |
| 从exact helper提取embedded AWK；GNU Awk 5.3.2运行1 valid + 18 invalid | **PASS 19/19** | 直接关闭原syntax blocker并复核fail-closed parser contract。 |
| 同一exact AWK与cases；locked nawk 20250116 | **PASS 19/19** | 覆盖One True Awk兼容实现。 |
| 同一harness提取committed HEAD helper并运行valid baseline | **expected FAIL reproduced 2/2** | 两个解释器均重现旧syntax rejection，提供差分证据。 |
| Python ordering assertions over exact generated helper | **PASS** | Fast-skip、双PID、secret/password/restart/stamp边界未漂移。 |
| 递归比较 committed/candidate system closure中的`rustdesk-macos-1.4.8` drv/output | **PASS：identity相同** | 既有Darwin store-bundle signature evidence仍对应candidate使用的同一app derivation。 |

这些targeted checks比再次只跑大而空的system build更直接：原问题位于build不会执行的embedded AWK。合法与invalid samples实际执行了candidate parser，而`bash -n`/ShellCheck/Nix eval分别覆盖外层shell、lint和module/generated-artifact边界。

### Command adjustments and focused-build disposition

- Exact provision derivation的本地`nix-store --realise`尝试在执行前按预期停止：derivation要求`aarch64-darwin`，当前builder只有`x86_64-linux`。记为 **SKIP (platform unavailable)**，不是implementation failure。
- 不把该SKIP伪装为candidate full Darwin build。上一轮已观察的Charlie full build对应pre-fix tree；本轮确认candidate仍引用完全相同的`rustdesk-macos-1.4.8` drv/output，因此其store bundle既有`codesign --verify --deep --strict`与`spctl`证据仍有效。当前唯一production delta是writeShellScript文本换行，已通过exact `env.text`直接验证；realize该derivation只会写出该文本，不会执行AWK。
- 一个早期ShellCheck调用漏写store output名中的`-bin`，修正为locked 0.11.0 binary后PASS；一个plist assertion最初硬编码了错误的coreutils store hash，改为校验evaluated store-path shape与完整参数后PASS。这些是verification command修正，不是production failure。
- Differential harness最初依赖英文`syntax`字样，但GNU Awk诊断受locale影响；改为断言nonzero、无PID stdout且有diagnostic后，两个旧parser rejection均重现。
- nawk使用其支持的`-version`确认`20250116`；不支持的`-W version`不作为测试结果。
- Acorn/Axiom没有candidate production delta，未重复full build。没有运行remote command、secret ceremony、真实password测试、deploy或switch。

## 4. Prior build/signature evidence boundary

保留且不夸大的既有证据：

1. `e8dcd484` pre-fix production tree的Axiom full NixOS toplevel build通过。
2. Charlie isolated worktree曾完成pre-fix full Darwin system build；其store `RustDesk.app`通过deep/strict codesign与Gatekeeper，source为`Notarized Developer ID`。
3. 本轮closure comparison确认candidate使用的`rustdesk-macos-1.4.8` drv和output与上述签名对象完全相同。
4. Acorn在preceding hardening tree完成full toplevel build；`e8dcd484`及当前candidate对Acorn均为zero production delta。
5. 这些是build/static artifact evidence，不是deployed state；destination signature、真实launchd/runtime行为仍为post-merge gate。

## 5. Charlie remote temporary-worktree cleanup gate

隔离路径：

```text
/Users/c1/dotfiles/.worktrees/rustdesk-self-hosted-remote-access-charlie
```

最终Charlie build/signature完成后，`charlie-tunnel`在temporary cumulative patch reverse之前离线。因此该worktree**可能仍含tracked temporary production patch以及untracked `.cache/`**；本轮没有连接远端或声称已清理。

这是明确的**remote temporary-worktree cleanup gate**：恢复连接后必须先无secret地检查状态，并在任何switch前清理temporary patch/`.cache/`，或把worktree安全更新到最终已merge commit并确认tracked tree clean。不得从这个可能patched的detached/isolated tree执行switch。

## 6. Remaining review, merge and runtime gates

1. 当前production fix仍未提交；先完成`review-change`、required PR checks和配置PR merge，再把主工作区刷新到clean `origin/master`。三台只允许从同一merged commit switch。
2. 完成上节`charlie-tunnel` remote temporary-worktree cleanup/update gate。
3. 从公共resolver确认DNS-only `rustdesk.0xc1.wang`；Aliyun SG只开放TCP 21115-21117和UDP 21116，并负测21114/21118/21119，确认relay费用/流量owner。
4. Acorn switch后验证resolved secret inode与keypair一致性（只记PASS/FAIL）、hbbs/hbbr active/restart/listeners、host firewall和SG。
5. Axiom runtime验证1.4.8 main/user server、真实PID/socket、public config、success stamp、reboot fast-skip及active Hyprland/Wayland；lock/login/DPMS按平台边界分项记录。
6. Charlie runtime验证store/staging/destination signature、三个launchd jobs、current-boot agenix gate、privileged/user PID stability、attempt/stamp/restart和人工TCC；覆盖Aqua/LoginWindow、sleep/FileVault边界。
7. 逐机正确密码成功，旧/错误/跨机密码失败；direct/forced relay与SSH/reverse SSH/ToDesk fallback通过。证据只记录无secret的PASS/FAIL。
8. 部署后通过独立follow-up evidence PR收口；任何host gate失败即停止后续rollout并按RFC rollback。

本轮没有修改DNS、SG、TCC、systemd/launchd runtime、`/Applications/RustDesk.app`或RustDesk mutable state。

## 7. Final disposition

**PASS for the uncommitted candidate tree；return to `review-change`。** Charlie generated privileged-service AWK syntax blocker已由两种解释器上的exact generated parser正/负例关闭，且未发现新的implementation blocker。本PASS不等于commit、merge或deployment approval；remote cleanup和全部post-merge runtime/DNS/SG/TCC/Wayland gates继续保留。

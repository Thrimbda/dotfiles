# RustDesk 自托管远程访问：verify-change 测试报告

> 日期：2026-07-11
> 阶段：配置 PR 前独立复验
> Verdict：**PASS for change review**
> Merge status：**仍受 Darwin build/signature pre-merge gate 约束；不代表允许部署**
> Secret boundary：未解密、未读取任何 secret plaintext；报告不包含 ciphertext 或 RustDesk public-key value

## 1. 结论

Engineer 仅处理上一轮 F1/F2；本轮独立复验确认两项均关闭：

1. Axiom 的 RustDesk bootstrap hosts override 已删除，module eval 与最终生成的 `/etc/hosts` 都不再包含 RustDesk 静态映射。
2. Charlie activation 已改为 root-owned fail-closed lock、同 filesystem 唯一 transaction directory、app+marker 成对保存，并把 rollback保护延续到 public config成功后的明确 commit point。一次性 synthetic probe 39/39通过。

未发现新的实现 blocker。当前变更可进入 `review-change`；在可信 `aarch64-darwin` builder完成 full build和 store-bundle signature前仍不得 merge，更不得部署。

本结论不重新否决用户已接受的短暂 password argv 与 non-core crash metadata residual，也不要求已排除的 password-file patch、crash framework、synthetic crash attestation或长期测试 harness。

## 2. F1 closure：Axiom DNS-only — PASS

- `hosts/axiom/default.nix` 已无 `networking.hosts` RustDesk条目。
- 对最终 module merge结果求值，`config.networking.hosts` 的全部映射均不含 `rustdesk.0xc1.wang`。
- Axiom full toplevel build后，直接检查 `config.environment.etc.hosts.source`，生成的 `/etc/hosts` 同样不含该 hostname。
- Public config仍只使用 canonical hostname；现有 `acornPublicIp` 仅服务于已有 SSH/FRP direct-route配置，不再形成 RustDesk第二解析来源。

因此公共 DNS失败会继续作为 client rollout stop condition，而不会被 Axiom本地 override绕过。

## 3. F2 closure：Charlie activation transaction — PASS

### 3.1 Generated transaction structure

最终生成的 activation shell具备以下顺序与边界：

1. 先验证 store bundle。
2. 以 `mkdir` 原子获取 `/Applications/.RustDesk.app.nix-lock`，随后校验 root ownership与 `0700`；已存在的 active/stale lock均 fail closed，不静默删除。
3. 在 `/Applications` 下用 `mktemp -d` 创建唯一、root-owned `0700` transaction directory，确保 app与marker的全部 rename在同一 filesystem。
4. 在任何 destination mutation前完成 staging签名、new marker写入，并发布 `prepared` marker。
5. 升级路径把 old app与old marker移动到同一 transaction；首次安装路径明确记录无旧对象。
6. 原子发布 new app、复核 destination signature、原子发布 new marker。
7. public config apply成功后才创建 `committed` marker；`commit_done=1` 只发生在其后。
8. pre-commit failure/signal由 EXIT trap恢复旧 app+marker同代状态；首次安装则恢复到二者都不存在。
9. rollback或cleanup本身失败时返回失败并保留 lock/transaction供 operator恢复，不把不完整状态伪装成成功。
10. commit后正常 cleanup删除本次 transaction与lock；独立 stale transaction directory不会与新 transaction碰撞或被误删。

旧的 `$$` staging/backup/marker-temp路径已不存在。

### 3.2 One-shot synthetic probe

本轮从实际 `nix eval` 生成的 activation shell做一次性内存转换，仅将 production path、Darwin signature/ownership命令和public helper替换为临时 synthetic等价物；每个转换都要求精确命中，测试结束后临时目录自动删除，仓库未新增 harness。

结果：**39/39 PASS**。

| Probe group | Cases | Expected and observed result |
|---|---:|---|
| 首次安装、升级正常成功 | 2 | new app+new marker同代提交；本次 lock/transaction清理 |
| stale lock、无锁的独立 stale transaction | 2 | stale lock无 mutation地拒绝；唯一 transaction不碰撞且不误删旧目录 |
| public config失败 | 2 | 升级恢复精确 old pair；首次安装恢复到 app/marker均不存在 |
| 升级的4个 atomic move，before/after × failure/signal | 16 | 所有 pre-commit case恢复精确 old app+old marker |
| 首次安装的2个 atomic move，before/after × failure/signal | 8 | 所有 pre-commit case清除 new app+marker |
| public-config边界，before/after × failure/signal | 4 | commit前始终 rollback |
| commit边界，before/after × failure/signal | 4 | commit前 rollback；commit marker后保留同代 new pair |
| 强制 rollback restore失败 | 1 | 返回失败，old app+marker保留在 transaction，lock保留 |

Probe覆盖四个升级 rename：old app、old marker、new app、new marker；首次安装覆盖其两个发布 rename。所有成功 rollback还断言本次 transaction与lock无残留。

### 3.3 Static tooling

- Generated activation `bash -n`：PASS。
- ShellCheck 0.11.0：PASS，无 exclusion。
- 三个 raw plist XML：PASS。
- Raw service/server topology、`LoginWindow` + `Aqua`、三个 job soft/hard `Core=0`、stdout/stderr `/dev/null`：PASS。

Synthetic probe不替代真实 Darwin filesystem、codesign或spctl；这些仍是下述pre-merge/deployment gates。

## 4. Full regression evidence

### 4.1 Scope 与 secret surface — PASS

- Git变更仍恰好为 **10个 production files + 8个 task docs**；production diff为 `+643/-3`。相对上一轮的增量只来自删除F1映射和收紧F2 transaction。
- `hosts/axiom/rustdesk-password-file.patch`、`test/rustdesk-round3-linux.py`、`test/rustdesk-charlie-safety.py` 均不存在；一次性 probe未留下文件。
- 三个 `.age` 文件仍是单 recipient age envelope且ciphertext彼此不同；没有解密或输出内容。
- RustDesk public material保持canonical Ed25519 shape，Axiom/Charlie生成helper引用同一值；值未输出。
- Changed source、generated shell/unit/plist/activation未发现age identity、private-key marker、age envelope正文或secret literal。Provision只包含host-local runtime secret path。
- `git diff --check`：PASS。

这些检查证明repository/generated surface未暴露plaintext；它们不声称在禁止读取plaintext的前提下完成client payload内容比较或server private/public keypair解密比对。

### 4.2 Acorn — PASS

- `rustdesk-server` 1.1.14 eval与full NixOS toplevel build：PASS。
- Private key target、public material symlink、双 `-k _`、四项preflight、service identity、`Restart=on-failure`、`RestartSec=5s`、`LimitCORE=0`：PASS。
- `openFirewall=false`；只新增TCP 21115-21117与UDP 21116，未新增21114/21118/21119。
- 两个generated units通过`systemd-analyze verify`。
- 锁定1.1.14 source再次确认 `_` 从working-directory private key派生public key，malformed private key退出。

### 4.3 Axiom — PASS

- 锁定`pkgs.unstable.rustdesk` 1.4.8；source为tag 1.4.8，仅保留nixpkgs自带reproducibility patch，无task-owned override/patch。
- 锁定source再次确认 `--config`、`--option`、root user-main IPC scope与 `--password` 的单行 `Done!` 成功语义。
- Public helper、main service、provision readiness/secret/result/restart/stamp顺序未漂移。
- Provision对main仍只有`Wants=` + `After=`；无restart propagation，unit无自动`Restart=`，每次执行最多一次bounded password invocation。
- Full NixOS toplevel build：PASS。
- 三个generated units `systemd-analyze verify`：PASS。
- 两个generated shell `bash -n` 与ShellCheck：PASS。
- Eval和最终generated `/etc/hosts` 均确认F1已消失。

### 4.4 Charlie artifact/provision/plist — PASS，Darwin build gate保留

- GitHub 1.4.8 ARM64 DMG digest、asset size、Nix SRI与RFC/实现完全一致。
- Linux inspection derivation可解包bundle；Info.plist version与bundle ID正确，RustDesk/service executables存在。
- App derivation为`aarch64-darwin`，source使用fixed-output fetch；install只复制bundle，`dontFixup=1`、`dontStrip=1`，无修改或re-sign step。
- Public/provision helper以及activation全部通过`bash -n`和ShellCheck。
- Provision的readiness-before-secret、reservation-before-password、single invocation、hard timeout、result check、kickstart/post-check/stamp顺序未漂移。
- Raw plist topology/Core/devnull字段与XML均通过。

## 5. Executed commands and rationale

| Command / evidence | Result | Why this proves the claim |
|---|---|---|
| Targeted `nix eval` of Axiom `networking.hosts` | PASS | 检查最终module merge，而非只grep source |
| Read generated Axiom `environment.etc.hosts.source` | PASS | 直接证明部署生成物无RustDesk静态映射 |
| Generated Charlie activation structure/order assertions | PASS | 验证lock、prepared、四个rename、public config与commit的真实生成顺序 |
| One-shot transformed activation semantic probe | PASS 39/39 | 覆盖stale、首次安装、升级、signal/failure、rollback/commit/cleanup终态 |
| `nix-instantiate --parse` on 6 changed Nix files | PASS 6/6 | 语法门禁 |
| Targeted three-host eval | PASS | 版本、secret metadata、firewall、unit/plist字段 |
| `nix build --no-link .#nixosConfigurations.acorn.config.system.build.toplevel -L` | PASS | Acorn full closure |
| `nix build --no-link .#nixosConfigurations.axiom.config.system.build.toplevel -L` | PASS | Axiom full closure及生成物 |
| Generated unit `systemd-analyze verify` | PASS 5/5 | 最终systemd语法与引用检查 |
| Generated shell `bash -n` + ShellCheck 0.11.0 | PASS 5/5 | Axiom 2个、Charlie 3个真实生成shell |
| Locked RustDesk client/server source assertions | PASS | 精确验证CLI和`-k _`语义 |
| GitHub API + `nix store prefetch-file` + bundle/derivation inspection | PASS | 交叉验证Charlie artifact和derivation |
| Scope/envelope/generated-surface assertions + `git diff --check` | PASS | Scope与无plaintext表面证据 |

选择这些命令而不是只跑一个大而空的flake check，是因为targeted eval/generated artifact/probe能直接证明F1/F2；Acorn/Axiom full build再覆盖组合闭包。

## 6. Remaining gates

### 6.1 Pre-merge Darwin gate

在可信`aarch64-darwin` builder上必须完成：

1. `nix build --extra-experimental-features dynamic-derivations --no-link .#darwinConfigurations.charlie.system -L`。
2. 对store中的`RustDesk.app`执行`codesign --verify --deep --strict`与`spctl -a -t exec`，确认官方签名在undmg/copy后仍有效。
3. 确认构建未fixup、strip、修改Info.plist或ad-hoc re-sign。

Linux runner实际执行同一full build命令时按预期停在缺少`aarch64-darwin` builder；没有伪造platform。该SKIP不降低gate。

当前分支还落后`origin/master` 1个commit；最终PR合并前需刷新/rebase并重跑受影响的eval/build/diff checks。Darwin gate与required review/checks通过前不得merge。

### 6.2 Merge后 deployment gates

配置PR合并后，必须从clean、与`origin/master`对齐的同一commit按顺序执行：

1. **DNS**：公共resolver确认DNS-only canonical record；Axiom继续无hosts override。
2. **Acorn**：按指定命令switch；验证runtime secret target权限与keypair一致性、hbbs/hbbr active/restart/listeners、host firewall；Aliyun SG只开放TCP 21115-21117与UDP 21116，并负测21114/21118/21119。
3. **Axiom**：switch后验证1.4.8 service/user process、public config、readiness、success stamp、reboot fast-skip与active Hyprland/Wayland场景。
4. **Charlie**：switch前处理任何stale transaction lock；验证store/staging/destination signature、三个launchd jobs、reservation/one-attempt/stamp/restart和Aqua/LoginWindow；人工授予Screen Recording、Accessibility、Input Monitoring。
5. **Authentication/network**：逐机正确密码成功，旧/错误/跨机密码失败；验证direct与forced relay、锁屏/sleep/FileVault边界。
6. **Rollback/fallback**：SSH、reverse SSH、ToDesk持续可用；任何host失败即停止后续rollout并按RFC逐机rollback。
7. **Evidence**：只记录无secret的PASS/FAIL，通过独立follow-up evidence PR收口。

## 7. Final disposition

**PASS for change review。** F1/F2已关闭，本轮未发现实现 blocker。下一步进入新的`review-change`并关闭Darwin pre-merge gate；本报告不授权生产部署。

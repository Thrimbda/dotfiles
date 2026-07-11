# RFC: RustDesk 自托管远程访问（简化自动部署）

> **Profile**: RFC Heavy / High Risk
> **Status**: `review-rfc` PASS
> **Audience**: 技术负责人和实施/评审人员
> **Design source of truth**: 本文件
> **Updated**: 2026-07-11

## Executive Summary

- **Decision**：acorn 运行 `rustdesk-server` 1.1.14；axiom 使用当前 flake 锁定的 `pkgs.unstable.rustdesk` 1.4.8；charlie 使用官方签名的 1.4.8 ARM64 DMG。
- **Trust material**：RustDesk server key 与 SSH key 分离；server private key、axiom password、charlie password 是三个独立 agenix secret，两台 client 的密码不同。
- **Provisioning**：两台 client 用短小、有限时的 oneshot 从 runtime secret 读取密码并调用上游 `--password`。不维护 `--password-file` patch，不构建 crash attestation 或 synthetic crash framework。
- **Accepted boundary**：axiom 与 charlie 是 single-owner trusted endpoints。用户接受设置密码时短暂出现在 argv，以及恰在该窗口崩溃时可能写入非核心 crash metadata 的低概率残余。
- **Normal-path invariant**：明文不得进入 Git、Nix store、derivation/unit/plist、常规日志或 PR；helper 禁止 trace，RustDesk stdout/stderr 不写 journal，匹配 stamp 时不重放。
- **Exposure**：仅开放 TCP 21115-21117 和 UDP 21116；DNS 与 Aliyun security group 是部署门禁。
- **Rollout**：配置 PR 先 merge；三台只从 clean merged baseline 依次 switch；部署证据通过 follow-up evidence PR 收口。
- **Rollback**：每台主机独立回滚，先关闭公网入口/停止 provision，再处理 generation、mutable client state 与 `/Applications/RustDesk.app`；始终保留 SSH、reverse SSH 和 ToDesk。

## 1. Context and Evidence

证据摘要见 [`research.md`](./research.md)。当前设计依赖以下事实：

1. NixOS 的 RustDesk server module 可运行 1.1.14，但默认 firewall 范围过宽、key 缺失会触发上游自动生成，因此必须显式最小化端口并做 fail-closed preflight。
2. 当前 flake 的 `pkgs.unstable.rustdesk` 求值为 1.4.8；其上游源码已对 Linux/macOS service-scoped IPC 增加 peer-uid、peer executable 和消息类型约束。
3. 1.4.8 永久密码管理 CLI 仍只有 `--password <value>`，没有 stdin/file 参数；本任务选择接受可信个人设备上的短暂 argv，而不是维护 source patch。
4. nixpkgs 的 RustDesk client 不支持 Darwin。Charlie 必须使用官方 DMG，且上游管理 CLI 和 launchd jobs 依赖固定的 `/Applications/RustDesk.app`。
5. `LimitCORE=0`/launchd `Core=0` 可降低传统 memory core 风险，但不能保证 systemd metadata 或 Apple crash metadata 不记录 argv；本设计不作超出该能力的声明。

## 2. Goals and Non-goals

### Goals

- 在 acorn 提供使用独立身份密钥的 hbbs/hbbr，并将公网暴露限制到 native client 必需端口。
- 在 axiom 与 charlie 安装 1.4.8 client，固定 ID server、公钥和关闭自动更新，并启用上游等价系统服务。
- 自动设置逐机不同的高熵永久密码，同时保证正常路径不把明文写入 Git、Nix store 或常规日志。
- 让配置发布、生产部署、验证和回滚均有明确顺序与 stop condition。

### Non-goals

- RustDesk Pro、Web client、Docker、WebSocket 公网端口或移除现有回退通道。
- 自维护 password-file patch、修改 RustDesk 协议/密码存储、建立共享跨平台 RustDesk framework。
- 全局 core handler、全局关闭 crash reporting、exact-OS crash attestation 或 synthetic crash test suite。
- 承诺 macOS FileVault preboot、睡眠唤醒、Wayland 登录屏或锁屏场景必然可控。
- 对同机 root/admin 或 single-owner 可信进程隐藏 RustDesk 的运行时密码状态。

## 3. Decision

### 3.1 Shared contract

| Item | Decision |
|---|---|
| Canonical server | `rustdesk.0xc1.wang` |
| Server version | `rustdesk-server` 1.1.14 |
| Client version | 1.4.8 on both clients |
| Client public config | canonical host、匹配 public key、permanent-password approval、auto-update off |
| Server ingress | TCP 21115-21117；UDP 21116；21114/21118/21119 不开放 |
| Client ingress | 不新增 client firewall ingress |
| Secret source | host-local agenix runtime path |
| Deployment source | clean commit，已 merge 且与 `origin/master` 对齐 |

DNS 是长期配置。不得把 bootstrap IP 作为第二套永久 client 配置；DNS 未通过公共解析验证时停止 client rollout。

### 3.2 Acorn server

- 使用 NixOS `services.rustdesk-server`，assert package version 为 1.1.14；不引入 Docker 或自建 server module。
- 生成独立 RustDesk keypair。private key 仅以 `rustdesk-server-key.age` 入库，runtime target 为 `/var/lib/rustdesk/id_ed25519`；public key 可提交并供两台 client pin。
- hbbs 与 hbbr 都使用 `-k _`，从同一 key material 派生/校验 public key。
- 两个 unit 在启动前以 service identity 检查 private/public key 可读且非空。任何检查失败都拒绝启动，不允许上游自动生成替代 key。
- `openFirewall = false`；在 acorn 现有 firewall 列表中显式加入 TCP 21115-21117、UDP 21116，Aliyun SG 使用相同 allowlist。
- 两个 unit 使用 `Restart=on-failure` 和短 `RestartSec`。可保留 per-unit `LimitCORE=0` 作为低成本 hardening；不改全局 `core_pattern`，不做 crash attestation，也不声称它消除 metadata。

### 3.3 Axiom client

- 直接使用 `pkgs.unstable.rustdesk`，assert version 为 1.4.8；不做 `overrideAttrs`，不追加 task-owned RustDesk source patch。
- host-local systemd service 对齐上游 `rustdesk --service` 形状，并提供其运行所需的确定性 PATH。公开 host/key/options 在 service/provision 前写入并仅反查白名单字段。
- `rustdesk-provision.service` 对 main service **只能**声明 `Wants=` + `After=`。禁止 `Requires=`、`PartOf=`、`BindsTo=` 或 main service 到 provision 的反向依赖。
- Provision helper 有限等待 main service、MainPID 和 IPC readiness；未 ready 时失败且不读取密码。
- 匹配 revision/stamp 时直接成功，避免每次 boot 重放。需要设置时，helper 最多执行一次有 timeout 的上游 `--password` 调用；成功后显式 restart main service、复核公开配置并原子写 success stamp。
- Helper 不启用自动无限 restart。失败由 operator 修复 readiness/secret/revision 后显式重试。
- 可对 config/main/provision units 设置 `LimitCORE=0`；它只降低 memory core 风险，不是 argv 或 crash metadata 保密证明。

### 3.4 Charlie client

- 使用官方 release 1.4.8 的 `rustdesk-1.4.8-aarch64.dmg`：
  - GitHub digest：`sha256:7f8acfb0dcab21d4c8fe570902be70a02ed0db007daa5ebfe1e0119487a5fc17`
  - Nix SRI：`sha256-f4rPsNyrIdTI/lcJAr5woC7Q2wB9ql6/4eARlIel/Bc=`
- Host-local fixed-output derivation 只解包/复制 bundle，禁用会改写 bundle 的 fixup/strip；不修改 binary/Info.plist，不 ad-hoc re-sign。
- 安装位置固定为 `/Applications/RustDesk.app`。未知来源的同名 app 不静默覆盖；store bundle 和最终 destination 都必须在 Charlie 上通过 `codesign --verify --deep --strict` 与 `spctl` 后才能加载 jobs。
- 保留上游 topology：`com.carriez.RustDesk_service` LaunchDaemon 和 `com.carriez.RustDesk_server` LaunchAgent；server agent 覆盖 `LoginWindow` 与 `Aqua`。关闭 app auto-update。
- 增加一个小型 root provision LaunchDaemon。它 `RunAtLoad`，并以保守 `StartInterval=300` 仅重试 app/service/IPC/readiness；readiness 失败不读取密码。
- 对同一 revision，实际 password invocation 只允许一次自动尝试。调用前持久化 attempt reservation；失败后不再由 interval 自动重试，需 operator 明确 reset 或变更 revision。成功后写 success stamp。
- service/server/provision jobs 可设 soft/hard `Core=0`；这不控制 Apple `ReportCrash`，也不替代本 RFC 的 accepted residual。
- Screen Recording、Accessibility、Input Monitoring 由用户对固定签名 app 人工授权；Nix 不宣称绕过 TCC。

### 3.5 Minimal provisioning contract

两台 client 使用同一结果合同，平台只在 supervisor/readiness 上不同：

1. Secret 是各 host 独立的 root-only agenix runtime file；建议为单行 32-64 字符 base64url。格式、权限或可读性不满足时 fail closed。
2. Public config 先写入并反查；password 只在 main process 与 IPC ready 后读取。
3. Helper 禁止 `set -x`，不把 password 放入 Nix 字符串、unit/plist、environment 或日志。调用窗口内不采集 process inventory。
4. Helper 从 runtime file 读入最短生命周期变量，调用官方 `rustdesk --password "$password"`，随后立即 unset。子进程 argv 的短暂明文是明确接受的边界。
5. 调用有硬 timeout；stdout/stderr 进入 root-only runtime temporary output 或 `/dev/null`，不进入 journal/launchd log。若使用 temporary output，只匹配上游成功结果并立即删除，绝不转录内容。
6. 只有调用成功且公开配置复核通过才原子写 success stamp。Stamp 由 package/public-config/provision/secret-ciphertext revision 驱动，不保存 plaintext。
7. 远端正确密码成功、旧/错误/另一台密码失败是部署验收，不通过本地读取 password 证明。

## 4. Options Considered

### Option A — Upstream 1.4.8 + bounded argv oneshot（选择）

- **优点**：代码最少；Linux/macOS 使用同一官方 CLI；保留 binary cache 与 macOS 官方签名；升级时无需 rebase 私有 patch。
- **代价**：single-owner endpoint 上存在短暂 argv；极低概率 crash metadata 残余需明确接受。

### Option B — 自维护 `--password-file` source patch

- **优点**：managed argv 不含密码。
- **缺点**：Axiom 失去简单上游包路径，产生持续 source review/build/test 负担；Charlie 不能应用而不破坏官方签名，最终仍是两套安全模型。
- **结论**：不选；删除现有 patch 与专用测试。

### Option C — 完全人工 GUI/CLI 设置密码

- **优点**：无需自动读取 secret。
- **缺点**：不可重复、轮换依赖人工、无法由 agenix revision 驱动，三机部署更易漂移。
- **结论**：不选；TCC 仍保留人工步骤，但 password provisioning 自动化。

### Option D — 全局 core handler、exact-OS attestation 或大型事务 harness

- **优点**：可追求更强的 crash artifact 断言。
- **缺点**：影响全机诊断，OS 绑定强，代码和验证面远大于个人可信 endpoint 的实际风险；容易产生无法长期维护的虚假保证。
- **结论**：不选。只保留 per-unit resource limit 与诚实的 residual 声明。

### Option E — 共享跨平台模块

- **优点**：表面减少重复。
- **缺点**：NixOS package/systemd 与 DMG/launchd/TCC 的生命周期不同；两台 client 不足以抵消抽象成本。
- **结论**：不选；使用 host-local config。

## 5. Secret Lifecycle

### Creation and storage

- Server keypair 独立生成，不复用 OpenSSH key。只提交 age ciphertext 和 public key。
- Axiom、Charlie 各生成一个不同的高熵 password，分别写入各自 `.age` payload；不复制、不从同一低熵口令派生。
- PR、日志和 evidence 只记录 recipient mapping、owner/mode 与 PASS/FAIL，不记录 secret、secret digest 或可还原输出。

### Runtime use and rotation

- Agenix 解密到 runtime path；derivation 和 supervisor 配置只包含该 path。
- RustDesk 写入的 host-local derived config 是可变运行时状态，不是 source of truth，也不进入 Git。
- 单 client 轮换只更新该 host ciphertext/revision，merge 后 switch 并重放一次 provision；从另一台 client 做新密码正测和旧密码负测。
- Server key rotation 没有双 key grace：保留旧 key，安排维护窗口，同步切换 server 与两台 client；任一 client 失败则关闭 ingress 并整体回旧 key。

### Revocation and disposal

- 删除 `.age` 文件不会自动清除 RustDesk derived password。Decommission 时先停止自动 provision；可安全调用现有 CLI 时清空/替换 password，否则保持服务停止并删除相应 mutable RustDesk config。
- 怀疑 password 泄露时只轮换对应 client；怀疑 server private key 泄露时轮换 server key 和全部 client public-key pin。

## 6. Deployment

### Phase 1 — Configuration PR

- 在隔离 worktree 实现 host-local 配置和三个独立 secret payload；删除旧 patch/harness。
- 完成 eval/build、版本/hash、generated unit/plist、secret-path 和 scope 检查。
- `review-rfc`、change review 和 required checks 通过后 merge 配置 PR。本阶段不做 production switch。

### Phase 2 — Clean baseline

- 刷新主工作区到已 merge 的 `origin/master`，确认 tracked tree clean，并记录部署 commit。
- 三台必须使用同一 merged baseline；不得从 feature worktree 或未 merge commit switch。

### Phase 3 — Acorn

1. 创建并从公共 resolver 验证 DNS-only `rustdesk.0xc1.wang -> 8.159.128.125`。
2. 从 clean merged source 以交互 TTY 执行已确认命令：

   `nixos-rebuild switch --flake .#acorn --target-host c1@8.159.128.125 --build-host localhost --sudo --ask-sudo-password --use-substitutes -L`

3. 本地验证 key preflight、units、listeners、restart 和 host firewall 后，再由明确 owner 把 Aliyun SG 限定为 TCP 21115-21117、UDP 21116。
4. 外部验证允许端口和 21114/21118/21119 负测；失败则关 SG、回滚 acorn，不推进 client。

### Phase 4 — Axiom then Charlie

- 从同一 baseline 先 switch axiom，验证 1.4.8、systemd topology、stamp、公开配置和 active Hyprland session；失败即回滚，不推进 Charlie。
- 再在 Charlie build/switch；先完成 DMG hash、store/destination signature 和 launchd topology gate，再等待 provision，最后人工授予 TCC。
- 完成双向控制、逐机 password 正/负测和强制 relay。锁屏、登录屏、sleep/FileVault 结果分项记录，不扩大能力声明。

### Phase 5 — Evidence closeout

- 观察一个正常使用窗口并保留 SSH/reverse SSH/ToDesk。
- 从真实部署收集不含 secrets 的 runtime PASS/FAIL，以独立 follow-up evidence PR 收口；配置 PR 不倒置承载部署后证据。

## 7. Rollback

### Triggers

- key mismatch、secret 缺失却生成新 key、意外公网端口、异常 relay 流量或服务 crash-loop。
- package/app 不是 1.4.8、Charlie 签名失败、public host/key/options 漂移。
- provision 重放失控、password 正/负测失败、日志出现明文，或 SSH/ToDesk 回退受损。

### Immediate containment

1. 先关闭 Aliyun SG 的 RustDesk ingress；仅 relay 滥用时可先关闭 21117。
2. 停止/disable client provision，再停止 RustDesk services/jobs；保留既有远程入口。
3. 若可能发生 secret disclosure，按对应 credential incident 轮换；不要把可疑 argv/crash artifact 复制进 PR。

### Per-host rollback

- **Acorn**：回滚到已知 generation，确认 hbbs/hbbr 与 host firewall 状态；SG/DNS 是外部状态，单独回退。Key rotation 必须 server 和两台 client 整体回旧。
- **Axiom**：回滚 generation 前先停 provision/service。Generation rollback 不会撤销 RustDesk mutable password；若不继续使用，清空或删除 root/user RustDesk config，并做旧密码负测。
- **Charlie**：先 unload provision/service/server jobs，再 `darwin-rebuild --rollback`。`/Applications/RustDesk.app` 是 mutable 外部状态；只恢复已知受管旧 bundle，无法证明 ownership 时保持 jobs 停止并人工处理。TCC 可保留，完全卸载时人工 reset。

部分成功不是继续 rollout 的理由；每台主机都是独立 stop/rollback boundary。

## 8. Verification

### Static and build

- Eval assert：Acorn server 1.1.14；Axiom `pkgs.unstable.rustdesk` 1.4.8；Charlie URL、digest 和 SRI 恰好匹配本 RFC。
- 确认 Axiom 没有 task-owned RustDesk source override/patch；删除 `rustdesk-password-file.patch` 和两个旧 Python harness。
- Build Acorn/Axiom toplevel；在 Darwin builder build Charlie，并验证 bundle 未 strip/fixup/re-sign。
- 检查 generated Axiom provision 只有 `Wants/After`，不存在 `Requires/PartOf/BindsTo`；Charlie provision 的 readiness retry 与一次-per-revision password budget 生效。
- 检查 unit/plist/store/Git diff 只含 runtime secret path，不含 plaintext；stdout/stderr 不进入常规日志。

### Runtime

- **Acorn**：service identity 可读 key 但不输出内容；hbbs/hbbr active，restart policy 生效；本机 firewall 与 Aliyun SG 最小；实际 registration/direct/relay 成功。
- **Axiom**：`rustdesk --version` 为 1.4.8；main service、active-user process、public config、success stamp 和 reboot fast-skip 正常；main restart 不终止正在收尾的 provision。
- **Charlie**：store/destination `codesign`/`spctl` 通过；两个上游 jobs 和 provision job 状态正确；readiness retry 不消耗 password attempt，失败 attempt 不无限重放。
- **Secrets**：两台 password 不同；正确密码成功，旧/错误/另一台密码失败。结果只记录 PASS/FAIL。
- **Manual gates**：Charlie TCC；Axiom active Hyprland/Wayland；两端 lock/login/sleep 场景；回退通道。

不运行真实-secret crash injection，不要求 synthetic crash framework。若配置了 core limit，只验证 effective limit 与文档一致，不据此声称 crash metadata 不含 argv。

## 9. Observability

- Acorn 观察 systemd active/restart、listen socket、registration/relay、CPU/memory/network egress 和 Aliyun 费用；异常 relay 的第一动作是关 21117。
- Axiom 观察 config/main/provision unit result、失败 stage 和 Wayland portal；Charlie 观察 launchd job、signature 和 TCC 状态。
- Provision 日志只能写 stage/category/revision，不写 command line、password、secret digest 或完整 RustDesk config。
- 没有 HTTP health endpoint 时，以 supervisor active + socket + 实际 client registration/connection 组合判断健康。

## 10. Accepted Residuals

以下风险由用户针对 single-owner endpoints 明确接受，不应在实现或评审中被重新包装成“已消除”：

1. Provision 调用期间，password 会短暂出现在 RustDesk 子进程 argv；同机 root 或足够权限的可信进程可能观察到。
2. 若 RustDesk 恰在该短窗口崩溃，systemd/Apple 可能保存包含 argv 的非核心 crash metadata。概率低但非零。
3. `LimitCORE=0`/`Core=0` 只降低传统 memory core 风险，不关闭 systemd metadata 或 Apple `ReportCrash`，也不构成 attestation。
4. Agenix 保护 source/runtime distribution，不防同机 root/admin；RustDesk derived config 与允许的本地 IPC 路径仍属于 endpoint 信任边界。
5. 1.4.8 的 service IPC peer-uid/executable hardening 缩小攻击面，但不提供 password-file CLI，也不取消上述 argv residual。
6. 公网 hbbs/hbbr 仍有扫描、DoS 和 relay 费用风险；最小 SG 与 egress 观察只能缓解。
7. macOS TCC/FileVault/sleep 与 Wayland portal/login screen 是平台边界，只能由真机结果界定。

若设备改为 multi-owner、开始运行不可信本地代码，或用户不再接受 argv/crash-metadata residual，必须停用自动 provision、轮换 password 并重新 RFC。

## 11. Milestones and Implementation Boundary

### M1 — Configuration PR merged

- Scope：简化三台 host 配置、secret ciphertext/public key、删除旧 patch/harness、完成 build/static review。
- Acceptance：`review-rfc` PASS；配置 PR checks/review PASS 并 merge；未做 production switch。

### M2 — Deployment from merged baseline

- Scope：按 acorn -> axiom -> charlie 部署，完成 DNS/SG、signature、TCC、Wayland、双向认证和 relay gates。
- Acceptance：三台来自同一 clean merged commit，回退路径仍可用。

### M3 — Follow-up evidence PR

- Scope：提交非秘密 runtime evidence、walkthrough 和 closeout。
- Acceptance：evidence 可追溯到部署 commit，失败和 residual 如实记录。

生产实现边界回到 host/secrets 文件：

- `hosts/acorn/default.nix`
- `hosts/acorn/secrets/{secrets.nix,rustdesk-server-key.age,rustdesk-server-key.pub}`
- `hosts/axiom/default.nix`
- `hosts/axiom/secrets/{secrets.nix,rustdesk-password.age}`
- `hosts/charlie/default.nix`
- `hosts/charlie/secrets/{secrets.nix,rustdesk-password.age}`

实施时明确删除：

- `hosts/axiom/rustdesk-password-file.patch`
- `test/rustdesk-round3-linux.py`
- `test/rustdesk-charlie-safety.py`

默认不新增 `modules/**`、`packages/**` 或 `test/**` RustDesk framework。

## 12. Remaining Gates and Review Readiness

### Design blockers

无。Contract、选项、secret lifecycle、rollback、verification 和 accepted residual 均已裁决，因此本 RFC **Ready for `review-rfc`**；尚未 Ready for implementation，需先取得新的 review PASS。

### Deployment/acceptance gates

- [ ] `review-rfc` 与配置 change review PASS。
- [ ] 配置 PR merge，主工作区刷新到 clean merged baseline。
- [ ] DNS-only A record 经公共 resolver 验证。
- [ ] Aliyun SG owner、最小规则和 relay 费用观察已确认。
- [ ] Acorn/Axiom eval/build 与 Charlie Darwin build/signature PASS。
- [ ] Charlie destination signature、launchd topology 与人工 TCC PASS。
- [ ] Axiom active Hyprland/Wayland 和 Charlie Aqua/LoginWindow 场景按矩阵验收。
- [ ] 双向 password 正/负测、direct/relay 和回退路径 PASS。

## References

- Contract：`../plan.md`
- Evidence：[`research.md`](./research.md)
- RustDesk client source：tag 1.4.8
- RustDesk server source：tag 1.1.14
- Official release：`https://github.com/rustdesk/rustdesk/releases/tag/1.4.8`
- Official client configuration：`https://rustdesk.com/docs/en/self-host/client-configuration/`

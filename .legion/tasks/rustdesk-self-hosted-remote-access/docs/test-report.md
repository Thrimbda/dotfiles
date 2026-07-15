# RustDesk 自托管远程访问：verify-change 测试报告

## Current authoritative report — Acorn force-relay same-intranet patch verification

> 日期：2026-07-15
> Verifier：`verify-change-fizzy-capybara`（build/static）；`verify-change-fizzy-yak`（final runtime复核）
> Direct author：`engineer-jolly-gecko`
> Worktree：`/home/c1/dotfiles/.worktrees/rustdesk-force-relay-intranet`
> Branch：`legion/rustdesk-force-relay-intranet`
> Baseline / HEAD / `origin/master`：`d85c80f3be5cfea3c857f10c26cfa72a4fa6e289`
> Candidate：Acorn package override/source patch，加 Charlie v10 marker 与 user-domain restart修复；本节记录static/build和最终runtime证据
> Verdict：**PASS — static/build、same-intranet relay、远程画面/输入、认证正负测、manual finalize 与 fast-skip**
> Runtime/deployment：**PASS**；长期relay带宽、容量与云费用仍为未关闭的运营风险
> Build location：Acorn closure只在Axiom构建并复制；没有在Acorn执行任何Nix build

### 1. Verdict、scope 与证据边界

验证开始时，HEAD、merge-base 与 `origin/master` 都是 `d85c80f3`，ahead/behind 为 `0/0`。最终 production candidate 为：

- `M hosts/acorn/default.nix`：在既有 RustDesk Server 1.1.14 package 上用 `overrideAttrs`追加一个 patch；`+5/-0`。
- `A hosts/acorn/patches/rustdesk-server-force-relay-intranet.patch`：13 行，只修改上游 `src/rendezvous_server.rs` 的 `same_intranet`赋值。
- `M hosts/charlie/default.nix`：推进fresh provision marker到v10，并通过`launchctl asuser`重启GUI-domain server。

没有 Axiom、其他 package、`.age`、key、port 或 RFC production/design change。`git diff --check`通过。

实际 candidate 而非 handoff 描述已独立验证：

- Baseline 与 candidate 都是同一官方 source、同一 version `1.1.14`；baseline无patch，candidate恰有这一份byte-identical patch，package output按预期变化。
- Patch对exact pinned source以`--fuzz=0` dry-run通过。Nix `applyPatches`产物与原source递归比较后，唯一内容变化是`src/rendezvous_server.rs`，且该文件严格等于old block执行一次exact replacement的结果。
- 8-case source truth table通过：atomic flag为`true`时，`same_intranet`对全部`ws`/intranet-predicate组合均为`false`；flag为`false`时，结果逐项等于旧表达式`!ws && intranet_predicate`。
- Patched package在Axiom以`--rebuild --builders ""`重新执行patch、release build与`checkPhase`；Rust tests为1 passed、0 failed，package passthru version test与`hbbs`/`hbbr --version`均为1.1.14。
- 完整dirty-candidate Acorn toplevel及其`--rebuild` output check通过。Built closure链接到本轮patched package和两份candidate generated units。

Static/source/build证据不单独证明runtime；最终runtime结论来自下列部署、服务端日志、state/PID检查和operator-observed远程控制结果。

### 1.1 Final deployment and runtime acceptance

#### Acorn build safety and activation

- Acorn candidate从Axiom执行用户指定命令：`nixos-rebuild switch --flake .#acorn --target-host c1@8.159.128.125 --build-host localhost --sudo --ask-sudo-password --use-substitutes -L`。
- 输出明确显示patched package及system closure从`ssh://localhost`复制到`ssh://c1@8.159.128.125`；Acorn未执行Nix build。
- Live system为`/nix/store/2akwxh4qxfbkyjscx5qsr0rabqwaw1fs-nixos-system-acorn-25.11.20260630.b6018f8`，shared package为`/nix/store/59f33dp0236z7s4bc0nz2ji6195wmpvk-rustdesk-server-1.1.14`。
- hbbs PID `531765`，环境含`ALWAYS_USE_RELAY=Y`；hbbr PID `531870`；TCP 21115-21117与UDP 21116监听正常。

#### Same-intranet relay proof

- Patch前，同出口请求在Charlie日志进入`Handle intranet`，监听LAN地址后以accept timeout结束；hbbr没有对应request。
- Patch后，同一出口地址成功进入hbbr：`18:16:40` request `48180396-5c42-4b7c-8a43-1b3b99472a74` paired。
- v10正向认证会话`19:27:48` request `a9847770-6607-4f95-a185-2399fe473a08` paired；负向认证会话`19:28:13` request `ef1e8a1f-b248-4209-9927-c051432eb45b` paired。
- 这些日志独立证明same-public-IP连接不再赢得`FetchLocalAddr` direct path，而是由Acorn hbbr承载。

#### Charlie v10 and remote-auth acceptance

- TCC手工授予Screen Recording与Accessibility；Input Monitoring未开启，但operator确认键盘输入正常。
- 打开RustDesk GUI使v8 ready绑定PID失效，v8未被finalize。v9在root GUI kickstart处fail closed且未发布ready。v10首次run在readiness前退出、未发布current reservation；修正GUI-domain restart后合法重跑同一v10并成功退出`0`。
- Current revision为`charlie-rustdesk-provision-v4:7ed736b14dd87b5637ad1fa776457e7c34afd8c28c90c2ea3c8bc2868aee36a4`，ID `237104984`，service/server PID为`48507/48510`。
- Operator-observed正向测试：正确密码、画面、鼠标点击和键盘输入均PASS。Operator-observed负向测试：错误密码被拒绝。
- Manual finalizer成功：`attempt`与`stamp`存在，`ready-to-finalize`与`operation.lock`不存在。随后手动触发provision，runs增加到14、exit `0`，PID仍为`48507/48510`，证明current-stamp fast-skip。
- 诊断用临时hosts/route已清理，Charlie恢复fake-IP/`utun4`路径后，operator-observed最终连接smoke仍PASS。

### 2. Executed commands and evidence

| Gate | Executed command / method | Result |
|---|---|---|
| Host / topology / scope | `hostname`; `git rev-parse HEAD origin/master`; `git merge-base`; `git rev-list --left-right --count`; `git status --porcelain=v1 --untracked-files=all`; full production diff；`git diff --check` | **PASS**：build host为Axiom；initial production scope恰为上述2 paths，baseline拓扑为`0/0`。 |
| Nix parse / package metadata | `nix-instantiate --parse hosts/acorn/default.nix`; candidate/base `builtins.getFlake` eval package version/source/patches/drv/out与systemd options | **PASS**：version与source identity不变；candidate唯一新增patch；package path变化。 |
| Effective option differential | Clean baseline `git+file://...?rev=d85c80f3...` vs dirty candidate `path:...`；除expected package path外，exact比较server options、normalized ExecStart、其余serviceConfig、env、restart-trigger names、key metadata与firewall | **PASS**：args、key gates、ports、env及service policy无旁路漂移。 |
| Patch input | Exact 13-line byte assertion；candidate patch与derivation input `/nix/store/qjx2...-rustdesk-server-force-relay-intranet.patch` byte comparison；`patch --dry-run --fuzz=0 -p1` against pinned source | **PASS**：derivation patch SHA-256为`f45d2bea8ed13a77eaf2ac7bafd6ca13e667c4eda9aaff64038298da79bced51`；zero-fuzz exact apply通过。 |
| Patched source | `nix build --builders "" ... pkgs.applyPatches { src = p.src; patches = p.patches; }`；Python递归tree/content与exact replacement assertion | **PASS**：patched-source output见第3节；只有目标Rust file变化。 |
| True/false small source test | 对exact old/new source blocks运行8-case truth table：`force ∈ {false,true}` × `ws ∈ {false,true}` × `intranet_predicate ∈ {false,true}` | **PASS 8/8**：true恒为false；false完全保持旧语义。该test为verification-only，没有新增repo test file。 |
| Package build/checks | `nix build --builders "" --no-link --print-out-paths --rebuild -L --impure --expr 'let f = builtins.getFlake "path:..."; in f.nixosConfigurations.acorn.config.services.rustdesk-server.package'` | **PASS**：fresh local rebuild实际应用patch、编译hbbs/hbbr并运行Rust check/tests；1 passed、0 failed。 |
| Package version test | 同样使用`--builders ""`构建`p.passthru.tests.version`；直接运行built `hbbs --version`与`hbbr --version` | **PASS**：passthru test输出`hbbr 1.1.14`；两个binary均输出1.1.14。 |
| Full Acorn build | `nix build --builders "" --no-link --print-out-paths -L 'path:...#nixosConfigurations.acorn.config.system.build.toplevel'`，随后同一installable加`--rebuild` | **PASS**：final report-inclusive realization见第4节；未activation/switch。 |
| Generated units / closure | Realize candidate units；base/candidate unit byte comparison；从exact toplevel解析unit symlink并用`nix-store --query --requisites`检查package+units | **PASS**：两unit均引用同一patched package；各自相对baseline的唯一文本变化都是shared package path。 |

选择这些命令是因为单纯grep patch不能证明它精确应用到pinned source，单纯package build不能证明true/false合同，单纯toplevel exit code也不能证明两个generated unit实际引用patched output。Zero-fuzz apply、patched-tree exact differential、truth table、fresh package tests、generated-unit differential与完整closure组合直接覆盖当前claims。

### 3. Exact patched-source and logic evidence

Pinned source保持：

```text
/nix/store/6nrhjs57c3145lwj66s9mncwgfqlyhz8-source
```

Verification-only `applyPatches` output：

```text
/nix/store/am69c0b8kiq0dh3r7ngkmhk2ifp5pcxa-rustdesk-server-1.1.14-patched-source
```

Exact replacement为：

```rust
-            let same_intranet: bool = !ws
+            let same_intranet: bool = !ALWAYS_USE_RELAY.load(Ordering::SeqCst)
+                && !ws
                 && (peer_is_lan && is_lan || {
```

Recursive path/type/content assertion证明两个source trees路径集合相同，只有`src/rendezvous_server.rs`内容改变；patched file严格等于baseline file执行上述single replacement，old block出现0次、new block出现1次。

令`old = !ws && intranet_predicate`，candidate即`new = !force && old`：

| `force` | 4个`ws × intranet_predicate`组合的结果 |
|---|---|
| `false` | `new == old`，4/4 |
| `true` | `new == false`，4/4 |

因此requested source-level合同成立：`ALWAYS_USE_RELAY=true`时不再进入same-intranet local-address分支；`false`时原有`ws`、LAN与same-IP判断语义不变。

### 4. Package tests and full Acorn build

```text
candidate package drv: /nix/store/vd5qzz23zkj6x1bsn1xk147nx65vy49b-rustdesk-server-1.1.14.drv
baseline package out: /nix/store/vgwrc4gvcqypaxwlkdvphcwzams9xl8z-rustdesk-server-1.1.14
candidate package out: /nix/store/59f33dp0236z7s4bc0nz2ji6195wmpvk-rustdesk-server-1.1.14
version test out:      /nix/store/3gxvhxh9rvgn6ijyan79r7kyq9sn64ja-rustdesk-server-1.1.14-test-version
Acorn toplevel:        final report-inclusive realization PASS（exact path见terminal handoff）
```

Fresh package `--rebuild` log依次显示`patching file src/rendezvous_server.rs`、release build、`checkPhase`与：

```text
test database::tests::test_insert ... ok
test result: ok. 1 passed; 0 failed
```

其余hbbr/hbbs/utils/doc targets为0 tests、0 failed。Build保留上游既有warnings但没有error。完整toplevel普通realization与随后`--rebuild` output check都返回同一output。所有这些build均由Axiom本地命令以`--builders ""`执行；没有连接或在Acorn执行build。 本报告自身属于`path:` flake input；为避免把final output path写回报告后再次改变input，本节记录exact command/PASS，最终exact path留在terminal五字段handoff。

### 5. Exact generated hbbs/hbbr evidence

```text
baseline hbbs unit:  /nix/store/47q0dk93ibnlxp7m51ywab1r8s1f5ix6-unit-rustdesk-signal.service
candidate hbbs unit: /nix/store/xdm57rln6rxg9dzpmj093y7y463aaafg-unit-rustdesk-signal.service
baseline hbbr unit:  /nix/store/rjxp8xn033h5ll9cwpxbhn87b83z87rn-unit-rustdesk-relay.service
candidate hbbr unit: /nix/store/2fi62f9hwfhgwa31965ah4qd16yxq5r3-unit-rustdesk-relay.service

hbbs ExecStart: /nix/store/59f33dp0236z7s4bc0nz2ji6195wmpvk-rustdesk-server-1.1.14/bin/hbbs --relay-servers rustdesk.0xc1.wang -k _
hbbr ExecStart: /nix/store/59f33dp0236z7s4bc0nz2ji6195wmpvk-rustdesk-server-1.1.14/bin/hbbr -k _
```

对每个unit，candidate文本都严格等于baseline文本只把baseline package path替换为candidate package path；没有第二处diff。由此同时证明：

- hbbs和hbbr都引用同一个patched 1.1.14 package；exact Acorn toplevel symlink与closure也指向这两份candidate unit和该package。
- hbbs继续恰有一次`Environment="ALWAYS_USE_RELAY=Y"`；hbbr仍为0次，两个environment均与baseline相同。
- hbbs args仍是`--relay-servers rustdesk.0xc1.wang -k _`，hbbr仍是`-k _`。
- 两unit各有3项相同的`ExecStartPre`，shared key preflight、public-key readable/non-empty gates、`LimitCORE=0`、`Restart=on-failure`、`RestartSec=5s`均保持。
- Agenix key metadata仍是`/var/lib/rustdesk/id_ed25519`、`rustdesk:rustdesk`、`0400`；两unit restart-trigger names仍是server key ciphertext与public-key文件。未读取其payload。
- `openFirewall=false`；TCP仍为`[22,443,2222,2223,2224,2225,7000,21115,21116,21117,34197]`，UDP仍为`[21116,34197]`。

### 6. Deployment/runtime risk and evidence boundary

- **Shared package restart observed**：Acorn activation按预期同时重启hbbs/hbbr；两项均恢复active/listeners，fresh relay会话随后成功。
- **Runtime relay PASS**：same-intranet direct failure被hbbr paired-session正证取代，正负认证均通过Acorn relay。
- **运营边界**：长期relay带宽、容量、延迟与云费用未做代表性周期测量；Acorn/hbbr仍是数据面单点。
- **Secret boundary**：仅求值声明式path/owner/group/mode与restart-trigger文件名；未打开、hash、解密或输出secret ciphertext/plaintext，也未读取RustDesk mutable state。

### 7. Verification command adjustments and failures

没有implementation failure被隐藏；required static/build gate均未skip。Verification-only corrections为：

1. 首次baseline flake URL手写了错误full hash，Nix在evaluation前以`object not found`拒绝；随后直接使用`git rev-parse`所得exact `d85c80f3be...`重跑通过。
2. 首次effective comparison把raw `ExecStart`纳入exact equality，因expected package path变化而失败；修正为只规范化该package prefix，同时继续exact比较args与其余serviceConfig后PASS。
3. 修正上述Nix assertion里`replaceStrings`单元素list的括号语法后PASS；production未改。
4. Specialized read tool不允许直接打开`/nix/store` source path；改用只读Python exact tree/source assertion完成同一gate，没有修改store或workspace source。

### 8. 会话注意力摘要

- **Attention state**：runtime gate CLOSED；可进入最终read-only review与PR lifecycle。
- **已关闭**：production scope、patch application/语义、build/tests、双unit恢复、same-intranet relay、远程画面/输入、正负认证、finalizer、fast-skip和临时路由清理。
- **保留运营风险**：长期带宽、容量、延迟、云费用与Acorn单点未做周期性验证，不阻塞本次correctness交付。
- **Design-source disposition**：用户明确要求不重开RFC；本报告不把旧RFC描述冒充当前实现。

---

## Historical report — Acorn hbbs force-relay verification

> 日期：2026-07-15
> Verifier：`verify-change-dapper-lemur`
> Direct author：`engineer-dapper-fox`
> Worktree：`/home/c1/dotfiles/.worktrees/rustdesk-acorn-force-relay`
> Branch：`legion/rustdesk-acorn-force-relay`
> Baseline / HEAD / `origin/master`：`662575240a1d3117be3c1773a3b2f825f839aebf`
> Candidate：该 HEAD 上未提交的 `hosts/acorn/default.nix` 单行修改；本节是 verifier 随后增加的 task-local evidence
> Verdict：**PASS — scope/diff、Nix parse/eval、generated units、完整 Acorn toplevel build 与 RustDesk Server 1.1.14 官方源码语义**
> Runtime/deployment：**NOT RUN / NOT PASS**；未 switch、deploy、restart 服务、建立 RustDesk 会话、commit 或 push，未解密或读取 secret payload

### 1. Verdict、scope 与证据边界

验证开始时，`git status --porcelain=v1` 只有 `M hosts/acorn/default.nix`；HEAD、merge-base 与 `origin/master` 相同，ahead/behind 为 `0/0`。`git diff --check` 通过，production diff 精确为一行：

```nix
systemd.services.rustdesk-signal.environment.ALWAYS_USE_RELAY = "Y";
```

实际 candidate 而非 handoff 描述已独立验证：

- Candidate option 与 generated hbbs unit 都只相对 clean HEAD 新增 `ALWAYS_USE_RELAY=Y`；generated directive 恰出现一次。hbbr option/unit 没有该变量，且 hbbr generated unit store path 与 baseline 完全相同。
- hbbs/hbbr 的 `ExecStart`、三项 `ExecStartPre`、shared key preflight、private/public key paths、key metadata、`-k _`、relay host、restart triggers/policy、`LimitCORE`、RustDesk package 1.1.14 以及完整 host firewall lists 均保持 baseline 值。
- Dirty candidate 的完整 Acorn NixOS toplevel已构建，并以 `--rebuild`完成输出复核；built closure包含 exact 1.1.14 server package和两份上述 generated units。
- Candidate实际使用的 fixed-output source来自官方 `rustdesk/rustdesk-server` tag `1.1.14`。官方 README与实现共同证明：hbbs启动时把值为`Y`的`ALWAYS_USE_RELAY`置为true；hole-punch路径随后把NAT type置为`SYMMETRIC`，源码注释为`will force relay`；README称其禁止direct peer connection。

本轮 PASS 只证明配置、构建产物与上游语义。Nix build不会启动 hbbs/hbbr，也不能证明真实连接已走 relay；因此本报告**不把 build 冒充 runtime relay PASS**。

### 2. Executed commands and evidence

| Gate | Executed command / method | Result |
|---|---|---|
| Scope / topology / whitespace | `git rev-parse HEAD`; branch/merge-base/ahead-behind；`git status --porcelain=v1`; `git diff --check`; `git diff --name-status`; `git diff --numstat`; full host diff | **PASS**：初始 candidate 仅一个 production path、一个 insertion，无 RFC、`.age`、module、package或其他host改动。 |
| Nix parse | `nix-instantiate --parse hosts/acorn/default.nix` | **PASS**。 |
| Candidate eval | `builtins.getFlake "path:..."`读取 Acorn package、RustDesk options、systemd services、secret metadata/path、tmpfiles、firewall与unit outputs | **PASS**：package=`1.1.14`，candidate可完整module-eval。 |
| Clean-HEAD differential eval | baseline使用`git+file://...?rev=662575...`，candidate使用dirty `path:`；Nix assertion要求全部 approved non-environment fields相等、hbbs env精确等于baseline env加`ALWAYS_USE_RELAY="Y"`、hbbr env精确相等且无该attr | **PASS**：只允许的effective option delta得到证明。 |
| Generated units | Realize baseline/candidate hbbs与candidate hbbr unit；逐行比较baseline/candidate hbbs并对hbbr做zero-occurrence和baseline identity assertions | **PASS**：hbbs unit唯一新增行是`Environment="ALWAYS_USE_RELAY=Y"`；hbbr中零次出现且unit output baseline-identical。 |
| Generated regression | 对两份 exact unit断言 `ExecStart`、三项`ExecStartPre`、`LimitCORE=0`、`Restart=on-failure`、`RestartSec=5s`；另检查 exact shared preflight | **PASS**：命令、key path与fail-closed metadata/readability gates均保留。 |
| Full Acorn build | `nix build --no-link --print-out-paths path:...#nixosConfigurations.acorn.config.system.build.toplevel`，随后同一installable加`--rebuild` | **PASS**：首次完整realization实际构建19个待构建derivation；随后`--rebuild`输出复核通过。 |
| Built closure | 从 exact toplevel读取两份systemd unit并解析target；`nix-store --query --requisites`断言1.1.14 package及两unit都在closure | **PASS**：built system链接到本轮已比较的exact units。 |
| Pinned official source | Eval package/source drv；`nix derivation show`；`git ls-remote https://github.com/rustdesk/rustdesk-server.git refs/tags/1.1.14*` | **PASS**：fetch URL、tag、official commit及fixed source identity见第5节。 |
| Official byte/semantic proof | Candidate fixed-output source与official raw tag的`README.md`、`src/rendezvous_server.rs`逐字比较；对startup、relay branch和README exact text做assertions | **PASS**：两文件byte-equal，environment-to-force-relay语义成立。 |

这些命令使用clean-HEAD/candidate exact equality、actual generated units、built toplevel closure和candidate package的fixed-output source；它们比只grep一行Nix或只看build exit code更直接证明placement、无旁路漂移、integration build和上游语义。

### 3. Exact generated configuration evidence

```text
baseline hbbs unit:  /nix/store/rp3padhimvskqdd2nfia4dfwwr874f0q-unit-rustdesk-signal.service
candidate hbbs unit: /nix/store/47q0dk93ibnlxp7m51ywab1r8s1f5ix6-unit-rustdesk-signal.service
baseline/candidate hbbr unit: /nix/store/rjxp8xn033h5ll9cwpxbhn87b83z87rn-unit-rustdesk-relay.service

hbbs only-added directive: Environment="ALWAYS_USE_RELAY=Y"
hbbr ALWAYS_USE_RELAY occurrences: 0
hbbs ExecStart: /nix/store/vgwrc4gvcqypaxwlkdvphcwzams9xl8z-rustdesk-server-1.1.14/bin/hbbs --relay-servers rustdesk.0xc1.wang -k _
hbbr ExecStart: /nix/store/vgwrc4gvcqypaxwlkdvphcwzams9xl8z-rustdesk-server-1.1.14/bin/hbbr -k _
both: LimitCORE=0, Restart=on-failure, RestartSec=5s
```

两unit继续使用同一个preflight output，并继续检查public key readable/non-empty：

```text
/nix/store/n4b5ld5b0qh0gjh8p4p7ns0n4ap7zx4x-acorn-rustdesk-key-preflight
/nix/store/hqkszxk2c0cxvd04xa4gsaqs182dw8l2-coreutils-9.8/bin/test -r /var/lib/rustdesk/id_ed25519.pub
/nix/store/hqkszxk2c0cxvd04xa4gsaqs182dw8l2-coreutils-9.8/bin/test -s /var/lib/rustdesk/id_ed25519.pub
```

Exact preflight仍resolve `/var/lib/rustdesk/id_ed25519`，并要求target为non-symlink regular file、`rustdesk:rustdesk:400`、readable且non-empty。Evaluated agenix metadata仍为path `/var/lib/rustdesk/id_ed25519`、owner/group `rustdesk:rustdesk`、mode `0400`；tmpfiles仍把`/var/lib/rustdesk/id_ed25519.pub`链接到declarative public-key store object。未打开private key、ciphertext或public-key内容。

Firewall与restart regression assertion对clean HEAD逐项相等：

```text
services.rustdesk-server.openFirewall = false
TCP = [ 22 443 2222 2223 2224 2225 7000 21115 21116 21117 34197 ]
UDP = [ 21116 34197 ]
restartTriggers = [ rustdesk-server-key.age rustdesk-server-key.pub ]  # both units
```

RustDesk exposure仍是TCP 21115-21117与UDP 21116；21114、21118、21119仍未加入host firewall。完整lists中的既有非RustDesk端口也没有漂移。

### 4. Complete Acorn toplevel build

```text
/nix/store/3b8r5a4sywqsv5ldrbckd6fz1jh4mc2n-nixos-system-acorn-25.11.20260630.b6018f8
```

Plain full realization构建了19个当时缺失/invalid的derivation并成功生成上述toplevel；紧随其后的`--rebuild`执行output check并返回同一路径。Closure含exact `rustdesk-server-1.1.14` package；toplevel的hbbs/hbbr symlink分别解析到第3节candidate unit与baseline-identical relay unit。没有运行该system output的activation或switch。

### 5. RustDesk Server 1.1.14 official semantics

```text
package drv: /nix/store/48n1d3rmp8phjmramq4nw9ik1246jh8m-rustdesk-server-1.1.14.drv
package out: /nix/store/vgwrc4gvcqypaxwlkdvphcwzams9xl8z-rustdesk-server-1.1.14
source drv: /nix/store/ximdab7lhsfndsn10x6bbg21zn1if8a3-source.drv
source out: /nix/store/6nrhjs57c3145lwj66s9mncwgfqlyhz8-source
fetch URL: https://github.com/rustdesk/rustdesk-server.git
fetch rev: refs/tags/1.1.14
official tag commit: 8557c4ab8259a9084879ad78a41c5a9539fd75a3
fixed NAR sha256: e4b44c7b2d5cc668cb835b3d46d57080f8c78f060b4901dae93cafeebfd7110b
README.md sha256: db1aea2af27d027307f378a4d06d502dacd89284ac99e84f3841896bb1edefe7
src/rendezvous_server.rs sha256: 223703727cb7ee69aa9da8bace9756385cf48e6d15b6bb7fcc25e7bfb402b471
```

语义链：

1. [`README.md` tag 1.1.14](https://github.com/rustdesk/rustdesk-server/blob/1.1.14/README.md#L342-L345)把`ALWAYS_USE_RELAY`归属到`hbbs`，并说明设为`"Y"`会`disallow direct peer connection`。
2. [`rendezvous_server.rs` startup](https://github.com/rustdesk/rustdesk-server/blob/1.1.14/src/rendezvous_server.rs#L146-L159)读取该环境变量，转为大写后与`Y`比较，匹配时把global atomic flag置为true。
3. [同文件hole-punch路径](https://github.com/rustdesk/rustdesk-server/blob/1.1.14/src/rendezvous_server.rs#L710-L719)在flag为true时把response NAT type设为`SYMMETRIC`，源码原注释为`will force relay`。

因此把`ALWAYS_USE_RELAY=Y`仅注入hbbs generated unit与1.1.14官方force-relay机制一致；hbbr不需要也未收到该变量。

### 6. Runtime boundary、command adjustments 与 attention

- **Runtime relay intentionally NOT RUN**：未activate/switch、未restart hbbs/hbbr、未建立controller/controlled会话、未观测hbbr流量或direct-path negative control。真实forced-relay验收仍需在批准的clean merged deployment后证明direct peer被禁止且会话实际经relay。
- 首次unit assertion按未加引号的systemd文本匹配，实际generator输出`Environment="ALWAYS_USE_RELAY=Y"`；只修正test literal后exact baseline differential PASS，production未改。
- 第一次在output尚invalid时直接用`--rebuild`得到Nix的`checking is not possible`。随后标准full build完成19个derivation，再跑同一`--rebuild`已PASS；这不是implementation failure。
- Google URL analysis helper因当前session无access token未执行；改用candidate fixed-output source、official fetch drv、`git ls-remote`和official raw-tag byte comparison完成更直接的immutable-source gate。无required static/build/source gate skipped。
- 未修改RFC。**Attention remains OPEN**：当前RFC仍把Acorn rollout视为已完成，并未把本次Acorn force-relay one-line production change写入当前implementation boundary。按用户指令本 verifier只记录该design-source lag；本PASS不自行授权merge/deploy，下一阶段需在`review-change`/orchestrator处置该attention。

---

## Historical report — Charlie user-server runtime fixed-forward verification

> 日期：2026-07-14
> Verifier：`verify-change-swift-ferret`
> Direct author：`engineer-swift-marten`
> Worktree：`/home/c1/dotfiles/.worktrees/rustdesk-charlie-runtime-fix`
> Branch：`legion/rustdesk-charlie-runtime-fix`
> Baseline / HEAD：`2de54e09ed907defb3b116dea7c9d29429a40c41`
> Candidate：该 HEAD 上未提交的 `hosts/charlie/default.nix` 修改；本节是 verifier 随后增加的 task-local evidence
> Verdict：**PASS — requested static、generated-artifact、full aarch64-darwin build 与 store-bundle signature gates**
> Runtime/deployment：**NOT RUN**；未 switch、activate、deploy、commit 或 push，未读取 secret 或 RustDesk mutable config 内容

### 1. Verdict、scope 与边界

验证开始时，`git status --short` 只有 `M hosts/charlie/default.nix`；`git diff --check` 通过，production diff 为 `+30/-9`，无 `.age`、Acorn、Axiom、module 或 package 修改。本 verifier 只新增本测试报告，没有修改 RFC 或 production implementation。

实际 candidate 而非 engineer handoff 已独立验证：

- provision 与 finalizer 的 generated `validate_user_server` 都从 c1 primary gid 改为 exact UID c1 + wheel gid `0`；目录仍要求 non-symlink directory `0700`，IPC 仍要求 non-symlink socket `0600`，PID file 仍要求 non-symlink regular file `0600`。
- `postActivation` 的新增 user-agent recovery 位于 agenix revision gate 完成之后。仅当 `gui/<uid>` domain 存在时，缺失 job 才 bootstrap `/Library/LaunchAgents/com.carriez.RustDesk_server.plist`，随后 kickstart；domain 不存在时没有失败分支。
- Provision marker 从 v7 变为 v8；old/new composite revision digest 不同，合法 prefix `charlie-rustdesk-provision-v4:` 保持不变。
- 当前 dirty local source 已由本机 eval 为 exact aarch64-darwin system derivation，并在 Charlie remote store 完整构建成功。该 system closure 中的 RustDesk 1.4.9 store app 已在 Charlie 上通过 arm64、deep/strict codesign、TeamIdentifier 与 Gatekeeper notarization 检查。

本轮 PASS 只证明 pre-merge implementation/build/artifact claims，不是 deployment、TCC、remote-auth 或 manual-finalize PASS。

### 2. Executed commands and evidence

| Gate | Executed command / method | Result |
|---|---|---|
| Scope / whitespace | `git status --short`; `git diff --check`; `git diff --stat`; `git diff --name-only`; full `git diff -- hosts/charlie/default.nix`; assert only one initial changed path and no `*.age` change | **PASS**：初始 implementation diff 仅 `hosts/charlie/default.nix`。 |
| Nix parse / system eval | `nix-instantiate --parse hosts/charlie/default.nix`; `nix eval --raw path:$PWD#darwinConfigurations.charlie.system.drvPath` | **PASS**：candidate system drv 为 `/nix/store/xnj4lmp15p55778iajvasr3j0r2gy6qc-darwin-system-25.11.ebec37a.drv`，platform为`aarch64-darwin`。 |
| Generated artifacts | 从 evaluated provision plist 与 finalizer system package 的 string context 定位 exact drvs；以 `nix derivation show` 读取 generated `env.text`；直接 eval `postActivation.text` 与完整 `activationScripts.script.text` | **PASS**：验证对象均来自 candidate eval，不是手抄 source 片段。 |
| Bash syntax | 对 exact generated provision、finalizer、postActivation、完整 activation 分别运行 `bash -n` | **PASS 4/4**。 |
| ShellCheck | Nix-pinned ShellCheck 0.11.0；provision/finalizer/postActivation 使用默认 severity；完整 activation 使用 default diagnostics 的 base/candidate normalized differential comparison，并另跑 `--severity=error` | **PASS**：前三者 zero finding；完整 activation zero error，20 个 warning/info 与 clean HEAD 基线在 code/level/message 上完全相同，没有 candidate 新增 finding。 |
| Validator strictness | 对两份 exact generated `validate_user_server` 做 base/candidate function-block differential 与结构断言 | **PASS 2/2**：每份 candidate block 都严格等于 base block仅执行 `id -g` → `wheel_gid=0` 与 `$gid` → `$wheel_gid` 替换；三项 metadata comparison exact 为 `$uid:0:700/600/600`，type、symlink 与 mode gate 未放宽，也没有新增 chmod/chown。 |
| postActivation structure | 对 base/candidate evaluated postActivation 归一化 store hash后比较；断言 agenix wait → UID lookup → GUI-domain probe → job probe/bootstrap → kickstart 的顺序、exact plist path、嵌套范围与无 `else` | **PASS**：GUI domain absent 时自然跳过且成功；domain present 时按需 bootstrap并总是 kickstart，bootstrap/kickstart失败仍 fail closed。 |
| Composite revision | clean HEAD 通过 exact `git+file` revision eval，candidate 通过 dirty `path:` eval；从 generated service plist 读取 `RUSTDESK_NIX_REVISION` | **PASS**：old/new exact值见第3节；digest变化且 prefix不变。 |
| Remote store availability | `nix store ping --store ssh-ng://charlie-tunnel` | **PASS**：remote Nix `2.31.5` 可达。 |
| Full aarch64-darwin build | 本机 dirty-tree eval exact drv；`nix copy --to ssh-ng://charlie-tunnel <drv>`；`nix build --store ssh-ng://charlie-tunnel --no-link --print-out-paths <drv>^*` | **PASS**：22 个 candidate-changed derivation在 Charlie 构建，完整输出为 `/nix/store/3yl4galgkg4xzpkn7nlsl7v9awjnpq46-darwin-system-25.11.ebec37a`；remote output deriver exact匹配上述candidate drv。没有运行输出中的 activation。 |
| Closure / RustDesk artifact | Remote `nix path-info --recursive` 从该 exact system output定位唯一 `rustdesk-macos-1.4.9`；在 Charlie remote store构建一次只读验证 derivation，运行系统 `lipo`、`PlistBuddy`、`codesign` 与 `spctl` | **PASS**：store app与签名结果见第4节。 |

选择这些命令是因为 source grep不能证明 Nix 生成结果，宽泛 build也不会执行 embedded validator或说明签名身份。Exact generated-script lint、base/candidate structural differential、dirty-source完整remote build与目标系统signature execution共同覆盖了本次变更的直接 claims。

### 3. Exact revision and validator evidence

- Old v7 revision：`charlie-rustdesk-provision-v4:1dd4ea33c305d12d9b39f211b4aa2dfccdfd520e81e2d4939ad6efec28026ee0`
- Candidate v8 revision：`charlie-rustdesk-provision-v4:651ace645ed239c51d10e99c7fa60559bf67a4c9a1ab8495f4d2f7afb8e9be26`
- Result：64-hex digest不同；exact prefix `charlie-rustdesk-provision-v4:`不变。

两份 generated validator 都保持以下 exact合同：

```text
/tmp/RustDesk-<uid>  directory, non-symlink, <uid>:0, 0700
ipc                  socket,    non-symlink, <uid>:0, 0600
ipc.pid              regular,   non-symlink, <uid>:0, 0600
```

Candidate function block 相对各自 clean-HEAD block没有其他逻辑变化；后续 launchd PID、process UID/executable、socket ownership和stable identity检查仍保留。

### 4. Full build and signed store bundle

Full system output：

```text
/nix/store/3yl4galgkg4xzpkn7nlsl7v9awjnpq46-darwin-system-25.11.ebec37a
```

Closure 中唯一 RustDesk 1.4.9 app：

```text
/nix/store/ll7kiyvhxzqs0j9clqf66a08s262szq0-rustdesk-macos-1.4.9/Applications/RustDesk.app
```

Charlie target-system verifier输出：

```text
arch=arm64
version=1.4.9
bundle-id=com.carriez.rustdesk
team=HZF9JMC8YN
codesign=deep-strict-pass
gatekeeper=accepted
source=Notarized Developer ID
origin=Developer ID Application: zhou huabing (HZF9JMC8YN)
```

Verifier derivation output为`/nix/store/97i9z4l92v1z6a7pvnl4plmf5dpw6gyc-verify-rustdesk-store-bundle`。它只读取上述 immutable store app；没有检查或修改 `/Applications/RustDesk.app`、launchd runtime或RustDesk mutable config。

### 5. Runtime evidence boundary and command adjustments

Orchestrator提供、但本 verifier按禁止读取mutable state的约束没有重新采集的当前真机证据：

- `/tmp/RustDesk-501`、`ipc`、`ipc.pid` metadata为`501:0`。
- 手工 bootstrap后user job与IPC正常。
- 旧v7 provision因gid mismatch在reservation前readiness失败；没有attempt、ready或stamp。

这些运行时事实解释了变更目标，但本报告只把它们标记为**orchestrator-supplied evidence**，不冒充本轮独立观察。

Verification-only command adjustments：

1. Host PATH没有`ShellCheck`；改用candidate Nix graph中的ShellCheck 0.11.0后完成全部lint。
2. 直接用`--store ssh-ng://charlie-tunnel`重新eval dirty flake在240秒内超时；随后使用本机已eval的exact dirty-tree drv，先复制derivation closure再在Charlie remote store realize，完整build通过。没有复制或修改Charlie repo。
3. 直接`ssh`只读命令被当前agent权限策略拒绝且未执行；改用Charlie remote-store verification derivation在同一目标系统运行`lipo/codesign/spctl`，所需artifact gate全部通过。

### 6. 会话注意力摘要

- **Attention state**：OPEN；不阻塞本轮技术验证PASS，但阻塞把本报告解读为merge/deploy授权。
- **触发点**：现有RFC仍把上一轮Axiom-only hotfix列为唯一production边界，并写明Charlie config不变、Charlie rollout等待Axiom finalize；它尚未描述本次Charlie runtime fixed-forward。
- **本轮已关闭**：implementation scope、generated validator、postActivation ordering、fresh revision、完整aarch64-darwin build及RustDesk store signature/notarization claims。
- **仍需决定**：orchestrator必须在进入merge/deploy前显式处置design-source-of-truth滞后，并保持既有Axiom/Charlie rollout ordering或记录新的批准决定。
- **禁止动作**：本报告不授权switch、deploy、manual finalize、读取mutable config，或把orchestrator提供的runtime evidence冒充本轮独立采集。

按明确指令，本 verifier没有修改RFC。下一阶段可进入`review-change`评审实现与上述attention；若评审要求RFC先对齐，应返回相应设计阶段，而不是在verify阶段补写。

---

## Historical report — independent Round 9 Axiom fixed-forward verification

> 日期：2026-07-12
> Worktree：`/home/c1/dotfiles/.worktrees/rustdesk-self-hosted-remote-access`
> Branch：`legion/rustdesk-self-hosted-remote-access-runtime-hotfix`
> Baseline / HEAD：fresh-fetched `origin/master` = `0026eb9922c87e9624ed7352b09b58cddb1a45a3`
> Candidate：该 HEAD 上的当前未提交 hotfix/doc diff
> Verdict：**PASS — pre-merge static, generated-artifact, isolated-state and full-build verification only**
> Runtime：**NOT RUN**；未 deploy/switch/start RustDesk，未连接 production mutable state，未运行 production finalizer，未读取 secret plaintext

### 1. Independent verdict and scope

实际代码而非 engineer 报告已复核。`git diff origin/master` 共 7 个文件：6 个 task-local Legion 文档与唯一 production 文件 `hosts/axiom/default.nix`。Production change 只有 Axiom resolver、共享 exact runtime environment、home/UID assertions，以及 composite revision marker/resolver/environment inputs。

- `hosts/acorn/**`、`hosts/charlie/**`、`modules/**`、`packages/**`：zero diff。
- `*.age`：zero diff；完整 diff 人工审阅及结构断言未发现 secret plaintext。没有输出 RustDesk public key、ciphertext 内容或 secret-derived value。
- Root storage 保持 `HOME=/root`、`XDG_CONFIG_HOME=/root/.config`；`XDG_DATA_HOME` 未声明。Source diff、generated provision/finalizer/unit、fresh activation 均无 `/home/c1/.config/rustdesk`，也无 copy/move/delete/chown migration addition。
- Round 9 `review-rfc` 的 current design-only verdict 为 PASS；其后保留的 Round 8 FAIL 与更早记录均明确为 historical，不用于本次 PASS。

### 2. Commands and evidence

| Gate | Executed command / method | Independent result |
|---|---|---|
| Baseline and full diff | `git fetch origin`; `git status --short --branch`; `git rev-parse HEAD origin/master`; `git diff --name-status --stat origin/master`; per-file full diff inspection | **PASS**：HEAD/origin/master/merge-base 均为 `0026eb99`；唯一 production path 是 `hosts/axiom/default.nix`。 |
| Scope / secret ciphertext / whitespace | `git diff --check origin/master`; `git diff --quiet origin/master -- hosts/acorn hosts/charlie modules packages`; assert non-doc diff equals Axiom file; assert `git diff --name-only ... -- '*.age'` empty | **PASS**：无 Acorn/Charlie drift、无 `.age` change、无 whitespace error。 |
| Nix parse | `nix-instantiate --parse hosts/{acorn,axiom,charlie}/default.nix` | **PASS 3/3**。 |
| Exact resolver/env/user eval | `nix eval --raw --impure --expr '<candidate/base exact-equality assertions>'` | **PASS**：Axiom exact mapping存在；Acorn/Charlie对应lookup均为`[]`；option-level environment移除generated `PATH`后与下列11项exact相等；home=`/home/c1`、UID=`1000`。 |
| Canonical public config | Evaluate/realize exact `axiom-rustdesk-public-config`, then fixed-string positive checks for canonical host/relay and IP negative checks; only PASS/FAIL emitted | **PASS**：host与relay均仍为`rustdesk.0xc1.wang`，没有改成`8.159.128.125`；key value未输出。 |
| Revision | Base/candidate分别读取evaluated `rustdesk-provision.restartTriggers[1]`并断言known values、difference与prefix | **PASS**：exact pre/post见第4节，合法prefix未变。 |
| Revision serialization / storage boundary | Focused source/diff assertions over the `hashString` input and production additions | **PASS**：含runtime marker、resolver、serialized exact environment；secret相关输入仅为ciphertext path interpolation，无plaintext/readFile；无storage migration addition。 |
| Generated unit | Realize evaluated `systemd.units."rustdesk.service".unit`; parse `Environment=` without printing sensitive values | **PASS**：11项approved值全部exact；NixOS unit generator另加`PATH`、`LOCALE_ARCHIVE`、`TZDIR`。无`XDG_DATA_HOME`、`/run/current-system/sw`或c1 RustDesk storage path，`User=root`。 |
| Wrapper/plugin composition | `strings <rustdesk-1.4.9>/bin/rustdesk` plus evaluated unit PipeWire path; run pinned `gst-inspect-1.0` with only composed immutable plugin dirs | **PASS**：wrapper `--prefix`保留core/base，unit追加PipeWire；`pipewiresrc`、`videoconvert`、`appsink`均解析。 |
| Pinned source/order | Derivation inspection identifies exact 1.4.9 source and vendor-staging source input; inspect pinned `pipewire.rs` factory call positions | **PASS**：source `/nix/store/x4bsb2rq5whcjszidn0q6qv2wbv2zivf-source`；`pipewiresrc@270 < videoconvert@285 < appsink@287`。 |
| Generated scripts | Re-evaluate/realize candidate and baseline provision/finalizer; candidate `bash -n`; Nix-pinned ShellCheck 0.11.0; normalize only revision value/revision-file path then compare | **PASS 2/2 syntax + 2/2 ShellCheck + 2/2 normalized equality**；revision identity外无generated logic delta，finalizer仍zero-secret/zero-password。 |
| State ordering / attempt budget | Exact candidate scripts with only synthetic state directory substitution; `unshare --user --map-root-user`; runtime/public gates stubbed, secret gate instrumented; ephemeral repo-local state removed | **PASS**：old reservation/ready均被接受为legal stale；new reservation先发布，stale ready在secret gate前删除；第二次运行`attempt-used`且gate计数仍1；old-state finalizer以`reservation-not-current`拒绝。Production state/secret/finalizer未触碰。 |
| Fresh full build | `nix build --no-link --print-out-paths --rebuild '.#nixosConfigurations.axiom.config.system.build.toplevel'` | **PASS**：output见第6节。 |
| Fresh closure/hosts/unit/activation | `nix-store --query --requisites <toplevel>` plus focused immutable artifact assertions | **PASS**：closure含exact PipeWire output与`libgstpipewire.so`；generated hosts有且仅有目标tuple；unit含store plugin path；activation无c1 RustDesk storage path。 |

这些命令优先使用 option-level exact equality、actual generated artifacts、closure/factory execution、base/candidate differential comparison与隔离state transition；它们比只重跑一个宽泛build更直接证明本hotfix的claims。完整toplevel rebuild作为最终integration gate补充。

### 3. Exact approved effective environment

`config.systemd.services.rustdesk.environment` 移除由 `path` 生成的 `PATH` 后，exact为：

```text
HOME=/root
XDG_CONFIG_HOME=/root/.config
DISPLAY=:0
WAYLAND_DISPLAY=wayland-1
XDG_RUNTIME_DIR=/run/user/1000
DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
XDG_CURRENT_DESKTOP=Hyprland
XDG_SESSION_TYPE=wayland
GST_PLUGIN_SYSTEM_PATH_1_0=/nix/store/dflhqrvw0z5cmpwism5pz020554z44l6-pipewire-1.4.9/lib/gstreamer-1.0
PIPEWIRE_LATENCY=1024/48000
PULSE_LATENCY_MSEC=60
```

Candidate `PATH` 与 clean baseline逐字相同。Generated unit还继承NixOS全局`LOCALE_ARCHIVE`和`TZDIR`；它们不是`systemd.services.rustdesk.environment` hotfix delta。

### 4. Composite revision evidence

- Deployed pre-change：`axiom-rustdesk-provision-v4:bea8eb09c7c01576fe016cb5259969d87d85a87723624d3df9b0313e855a010a`
- Candidate post-change：`axiom-rustdesk-provision-v4:bf93f20590fc87872194f33a8788395aa6c5eb42fada741de87850af560e39b8`
- Result：digest不同；exact legal prefix `axiom-rustdesk-provision-v4:`保持不变。
- Serialized identity含`runtime-contract=axiom-rustdesk-runtime-v1`、`resolver=rustdesk.0xc1.wang:8.159.128.125`与11项environment JSON。Secret只以`.age` ciphertext store-path identity参与；未读取或序列化plaintext。

### 5. Wrapper and generated-script evidence

Effective plugin path由wrapper prefix与unit value组成：

```text
/nix/store/zvgn0q1ahbp13cgldwg98hp3r239yvqr-gstreamer-1.26.11/lib/gstreamer-1.0
:/nix/store/1dvjqj8amffkmp0a99ch7c93bfcf65hp-gst-plugins-base-1.26.11/lib/gstreamer-1.0
:/nix/store/dflhqrvw0z5cmpwism5pz020554z44l6-pipewire-1.4.9/lib/gstreamer-1.0
```

Candidate generated artifacts：

- Provision：`/nix/store/fshz7pfqy0i45r8hrpsgcfcm580j07zb-axiom-rustdesk-provision`
- Finalizer：`/nix/store/0d332bzgk9vbs45ci3gkw51amglcwima-rustdesk-provision-finalize/bin/rustdesk-provision-finalize`
- Unit：`/nix/store/2y4vghkl7dwcdv3lv7yj4zmfyrkxz0h3-unit-rustdesk.service/rustdesk.service`

Operational order in the exact generated provision is:

`publish current reservation -> remove stale ready + sync -> revalidate runtime -> resolve secret -> invoke --password`

Normalized base/candidate scripts are byte-equal beyond revision identity. Existing pre-secret readiness remains limited to RustDesk main PID, c1 server PID/socket, IPC and approved public config; no Wayland/session-bus/portal/PipeWire pre-reservation promise was added.

### 6. Fresh Axiom build

```text
/nix/store/wcz94ci1ladj6dhyw2sdvv46kwgqdv89-nixos-system-axiom-25.11.20260630.b6018f8
```

`--rebuild` completed successfully. No switch, activation, service start or production-state access occurred.

### 7. Verification command adjustments

No implementation failure was hidden. Verification-only corrections were:

1. Evaluated unit output is a directory; inspection was corrected from the directory path to its `rustdesk.service` member.
2. Generated unit contains expected NixOS global `LOCALE_ARCHIVE`/`TZDIR` in addition to service `PATH`; exact hotfix equality remains correctly asserted at the `systemd.services.rustdesk.environment` option layer.
3. Bare `file` was unavailable; wrapper prefix was verified directly with `strings` and factory execution.
4. Cargo vendor source linkage passes through the evaluated `vendor-staging` derivation; the corrected derivation-hop assertion confirms the exact package source input.

No required static/build check was skipped. Runtime checks were intentionally not run by contract.

### 8. Residual post-merge runtime gates — not PASS for this candidate

This PASS does **not** establish runtime authentication, capture or input control and does not authorize direct finalize/deployment. Remaining ordered gates are:

1. Merge/review/checks, then use a clean merged `origin/master`; Axiom must remain stopped beforehand.
2. Confirm old reservation/ready are stale/invalid; no resume, reset, old finalizer or generation rollback.
3. After switch, prove fresh current reservation + fresh ready, no stamp, one password attempt, and stable fresh process identities.
4. Compare only approved root/c1 storage metadata; root canonical state remains `root:root`, no migration/ownership drift.
5. Verify live root and c1 server whitelist environments, including composed core/base/PipeWire path and root HOME/XDG.
6. Verify direct canonical NSS resolution and UDP/TCP NAT path.
7. Post-ready only: actual Wayland socket, user bus, portal, PipeWire stream/node, capture and keyboard/pointer control.
8. Correct-password positive plus wrong/old/cross-host negative controls; then exact manual finalizer and fast-skip/no-second-attempt proof.
9. Any post-ready failure consumes this revision: stop RustDesk and fixed-forward again; do not finalize/reset/rollback. Charlie remains blocked until Axiom finalizes successfully.

---

## Historical pre-deployment evidence — RustDesk Client 1.4.9 configuration PR candidate

> **HISTORICAL ONLY**：以下证据对应已合并的配置PR候选及其当时边界，不覆盖本Round 9 hotfix，也不构成当前runtime PASS。

> 日期：2026-07-12
> Target：`origin/master` `0d61c714` + feature HEAD `3db55d1c`；Charlie隔离worktree为同一commit
> Verdict：**PASS — pre-merge implementation/build/signature evidence**
> Deployment：**NOT RUN**；feature已push但未install、deploy或switch，未读取任何RustDesk secret

### Candidate and build evidence

- Feature已无冲突rebase到live `origin/master`，ahead 5/behind 0；`git diff --check`：**PASS**。
- `nix-instantiate --parse hosts/{acorn,axiom,charlie}/default.nix`，并eval三台system derivation：**PASS**。
- Acorn完整NixOS toplevel build：**PASS**，output `/nix/store/lbhi1fgapnhqj3z9xsajbcqg1bp17l8s-nixos-system-acorn-25.11.20260630.b6018f8`。
- Axiom effective service为`/nix/store/...-rustdesk-1.4.9/bin/rustdesk --service`；完整NixOS toplevel build：**PASS**，output `/nix/store/vq8y7x0bi84cpx9hp3yfcg82d6niy8pf-nixos-system-axiom-25.11.20260630.b6018f8`。
- Charlie完整`aarch64-darwin` system build：**PASS**，drv `/nix/store/xnvfw9fzv1929cpwiw6armin79gvzwqj-darwin-system-25.11.ebec37a.drv`，output `/nix/store/9g2l5777jh51q9wzrr5yvywymgz6pmym-darwin-system-25.11.ebec37a`。
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
- Charlie隔离worktree已清除旧1.4.8 temporary patch，fetch feature v3并detached在exact `3db55d1c`；tracked tree clean，仅保留untracked `.cache/`，不得用于switch。

### Remaining gates

1. 创建并完成配置PR；merge后只从同一clean merged commit部署，不得从Charlie detached verification tree switch。
2. DNS、Aliyun SG、Acorn/Axiom/Charlie runtime、destination signature、launchd/systemd PID、Wayland/TCC及direct/relay仍需逐机验证。
3. 两端password ACK后先保持reservation+ready、无stamp；从fresh controller完成新密码成功与旧/错误/跨机密码认证拒绝后，才运行`rustdesk-provision-finalize --confirm-remote-auth`。
4. 任一reservation发布后的失败都禁止generation rollback；保持RustDesk停止并fixed-forward到全新revision。

最终`review-change`已PASS；本报告与评审共同授权创建配置PR，但不授权deployment。

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

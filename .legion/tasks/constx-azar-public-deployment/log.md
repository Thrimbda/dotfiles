# Const X Azar Public Deployment Log

## 2026-09-01

- 用户明确授权：部署当前 Const X 至 `azar`，使用 dotfiles 中 age 加密的 Cloudflare API token，把服务放到 `constx.0xc1.wang`。
- 已确认 `ssh azar` 实际到达 `aliyun-acorn`（NixOS 26.05，`c1` 用户）；Nginx、`auth-mini.service`、`auth-mini-gateway-auth-gateway.service` 与 `auth-mini-gateway-frps-acorn.service` 正在运行，`127.0.0.1:3210` 未被占用。
- 已确认现有 Acorn ingress 以 `hosts/acorn/secrets/cloudflare-dns.env.age` 提供 DNS-01 ACME；现有 Auth Mini gateway 按 hostname 使用 loopback backend 和 host-only cookie。
- 已确认最新 Const X source 为 `45c21f0a2f437cb11cb5e316c29d5ff08cbef471`；Azar 当前无 `constxd`、Node、Cargo 或 NPM。
- 已确认当前 SSH 权限不足以切换 NixOS：`c1` sudo 需要密码，root SSH 被拒绝；此为后续 runtime switch 的唯一已知操作权限门，不用未经授权的云控制面或临时公网服务绕过。
- dotfiles 主工作区已有用户的 tracked/untracked Legion 修改；任务已在 `.worktrees/constx-azar-public-deployment` 从 `origin/master` 隔离创建，未改动主工作区内容。
- 发现 `origin/master` 最新 commit `13fba91d` 仅为 Charlie 添加 `constx-charlie.0xc1.space` Cloudflare Tunnel ingress，不覆盖 Azar 或用户指定的 `constx.0xc1.wang`，因此本任务不复用为完成证据。
- 独立只读 RFC review 判定 FAIL：C1/C2/C3/C5 的 runtime rollout 需要用户明确的 Azar root 执行路径；另发现 contract 的 `current` symlink 回退承诺与 RFC 的固定-SHA `ExecStart` 冲突。记录为 `D-ROOT-001`，等待用户决定后回到 spec-rfc。
- `D-ROOT-001` 已由用户于 2026-09-01 决定：Axiom（SSH alias `axiom-tunnel`）只承担 build host，Azar（SSH alias `azar`）承担 target/activation；使用 owner-only 的本机非版本化 sudo password 文件通过 `--ask-sudo-password --sudo`。两台主机的密码均已作无副作用 `sudo true` 验证；值未读取到日志。恢复阶段：spec-rfc。
- 按独立 review 的非权限 blocker，release/rollback 统一为固定 SHA `ExecStart` + NixOS generation 为唯一回滚权威；首次失败停止/移除新 service，不使用或承诺 `current` symlink。
- 独立 re-review PASS（attention: skim）：D-ROOT-001 和 release/rollback 双重权威均已消除。下一阶段：engineer。
- engineer 已新增 `hosts/acorn/modules/constx.nix`、导入该模块，并为 `constx.0xc1.wang` 添加独立 Auth Mini gateway instance。service 固定指向 release SHA、只提供 Node 22 runtime、使用 private StateDirectory；Nginx vhost 保留 `auth_request` 并追加 22 MiB / SSE / long-response proxy directives。
- 工程级检查：Nix parse、constxd ExecStart / ACME host / gateway unit evaluation 和 scoped Nginx location evaluation 均成功；full attribute JSON 访问触发 Nix optional-field coercion（`startLimitBurst` / `sslCertificate`）并非 configuration failure，toplevel drvPath 可求值。
- Axiom source build completed: Acorn closure `/nix/store/8d1bfd46v3yzrlfyknwv5aprf36yr9cs-nixos-system-acorn-26.05.7813.0dd31db7e6db` built successfully; generated constxd/Nginx/gateway/ACME shape inspected. Exact Const X release built on Axiom, `doctor` passed with Pi 0.84.3, and the hash-verified binary is staged on Azar but not running. Evidence: `docs/evidence/`.

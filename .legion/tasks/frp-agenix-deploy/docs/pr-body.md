# Implementation Review

> 本 PR body 只是 PR 创建/更新输入，不代表 checks/review/merge、auto-merge、worktree cleanup 或主工作区 refresh 已完成。

## 交付摘要

- 新增声明式 `modules.services.frp`，支持 Linux host 启用 `frps` 或 `frpc`。
- `aliyun-acorn` 运行 `frps`，开放 TCP `7000` 和 `2225`。
- `axiom` 运行 `frpc`，连接 `8.159.128.125:7000`，将本机 SSH 转发到远端 `2225`。
- frp token 使用 host-local agenix secret 保存，运行时注入 TOML，避免明文进入 Nix store。

## 范围

**In scope**

- `modules/services/frp.nix`
- `hosts/aliyun-acorn/default.nix`
- `hosts/axiom/default.nix`
- `hosts/aliyun-acorn/secrets/*`
- `hosts/axiom/secrets/frp-token.age` 和 `hosts/axiom/secrets/secrets.nix`
- `.gitattributes` 的 `*.age binary` 规则
- `.legion/tasks/frp-agenix-deploy/**`

**Out of scope**

- 不替换现有 autossh reverse SSH。
- 不新增 frp dashboard、metrics、TLS、多 proxy 或 Cloudflare/Gatus 集成。
- 不整理主工作区已有 unrelated dirty 改动。

## 主要改动

- 新 module 生成带 `@FRP_TOKEN@` 的 TOML 模板。
- systemd `ExecStartPre` 从 `/run/agenix/frp-token` 读取 token，写入 `/run/frpc/frpc.toml` 或 `/run/frps/frps.toml`。
- host-local age secret 两份密文保存同一个 96 位 hex token，并包含 `aliyun-acorn` 与 `axiom` recipient。
- review 后移除了无效的 `age-secrets-frp-token.service` 依赖，并完成二次验证。
- `.gitattributes` 标记 `*.age` 为 binary，避免 Git whitespace checker 解析密文内容。

## 验证与审查

- 设计: `.legion/tasks/frp-agenix-deploy/docs/rfc.md`
- 设计审查: `.legion/tasks/frp-agenix-deploy/docs/review-rfc.md`
- 验证: `.legion/tasks/frp-agenix-deploy/docs/test-report.md`
- 变更审查: `.legion/tasks/frp-agenix-deploy/docs/review-change.md`
- Walkthrough: `.legion/tasks/frp-agenix-deploy/docs/report-walkthrough.md`
- HTML walkthrough: `.legion/tasks/frp-agenix-deploy/docs/report-walkthrough.html`

## 风险与限制

- TCP `7000` 与 `2225` 是公网入口，主要安全边界是强 token、secret 保密和 SSH key-only auth。
- 本地验证无法证明部署后的网络可达性和 systemd runtime health。
- 当前用户无法读取 axiom host 私钥，因此只验证 recipient 写入和两份密文在可用 identity 下内容一致。

## 评审重点

- [ ] 变更是否符合 task contract 与 scope？
- [ ] token 是否确实没有进入 Nix store 模板或脚本？
- [ ] 公网端口 `7000` / `2225` 是否符合预期？
- [ ] 验证证据是否足以支撑交付结论？

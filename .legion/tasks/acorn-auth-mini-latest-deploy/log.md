# 日志

- 2026-09-02：从 Axiom 读取既有部署约定、Acorn `auth-mini.service` 状态和官方 GitHub release metadata；未读取任何凭据文件。
- 2026-09-02：当前生产二进制来自 `auth-mini-latest-2026-07-24`；计划更新到官方 latest Linux x86_64 asset（更新时间 2026-08-23）。
- 2026-09-02：通过已认证的 GitHub CLI 下载官方 asset `525860183` 至临时文件并校验 SHA-256；只将公开发布资产以内容寻址形式注册到 Axiom 本地 Nix store。匿名 GitHub API 已耗尽共享 IP rate limit，故直接 `fetchurl` 首次构建会 403；本次构建使用完全相同、已验证的 fixed-output store path，不改变生产 pin 的 asset-ID API 语义。
- 2026-09-02：Axiom 已成功构建 `auth-mini-latest-2026-08-23` 和 Acorn consuming toplevel；评估后的 ExecStart 只将二进制路径从 `latest-2026-07-24` 更新到 `latest-2026-08-23`，host/port/db/service hardening 参数不变。
- 2026-09-02：部署前 Acorn `auth-mini.service` active；loopback `/web/` 为 HTTP 200；公开 HTTPS root 为预期 `302` 到 `/web/`。未执行 deployment 或重启。
- 2026-09-02：deployment preflight 确认 Cybion executor 不具备 noninteractive sudo。`--ask-sudo-password` 需要可信交互 TTY；依照安全约束没有尝试读取或使用任何 password 文件。部署暂停，等待操作员在 Axiom 交互终端自行完成授权。

# RFC：Acorn Auth Mini 发布资产刷新

## 方案

保持现有二进制发布资产模式：`fetchurl` 下载官方 GitHub release asset ID，使用 GitHub 的官方 SHA-256 digest 转成 Nix SRI，并以日期化 `latest-YYYY-MM-DD` 版本标识记录资产更新时间。仅更新三项 pin 值。

不改服务拓扑或运行时状态：Acorn 继续由 `auth-mini.service` 在 `127.0.0.1:7777` 运行，SQLite 继续位于 `/var/lib/auth-mini/auth-mini.sqlite`。

## 选择理由

- 现有仓库决策要求不得直接依赖可变 `/releases/download/latest/` URL；必须 pin asset ID 与 fixed-output hash。
- 当前官方 latest asset 的 digest 可独立校验，且 build 将在 hash 不一致时失败。
- server-side 转换、从源码编译、数据库迁移或配置重写均不必要且超出需求。

## 部署与回滚

部署必须从 Axiom 使用仓库固定的 `nixos-rebuild switch --build-host localhost --target-host ... --sudo --ask-sudo-password` 路径。若交互 sudo 授权不可用，停在已验证构建阶段，不读取任何本地密码文件。

回滚优先恢复上一 declarative pin 并走同一路径；紧急情况下使用 Acorn 上一 NixOS generation。数据库不回滚、不删除。

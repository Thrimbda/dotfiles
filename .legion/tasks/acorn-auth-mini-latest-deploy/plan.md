# Acorn Auth Mini 最新发布部署

- **task-id**: `acorn-auth-mini-latest-deploy`
- **风险**: high / Strict
- **目标**: 将 Acorn 的 `auth-mini` 从当前固定发布资产升级到上游 `zccz14/auth-mini` 当前 `latest` Linux x86_64 资产，并仅通过 Axiom 本机构建、Acorn 远程激活的既有 NixOS 流程部署。

## 验收

1. 只修改 `packages/auth-mini/default.nix` 中的发布版本元数据、GitHub release asset ID 与固定输出 SRI hash。
2. 当前上游 `latest` Linux x86_64 资产的 GitHub asset digest 与 Nix fixed-output hash 一致。
3. 从 Axiom 对 `.#acorn` 成功完成相关 package 与 toplevel 构建/评估；不在 Acorn 构建。
4. 仅在可获得合法交互式 sudo 授权时，使用以下受支持命令部署：
   ```sh
   nixos-rebuild switch --flake .#acorn \
     --target-host c1@8.159.128.125 \
     --build-host localhost \
     --sudo --ask-sudo-password --use-substitutes -L
   ```
5. 部署后验证 Acorn `auth-mini.service`、loopback `/web/`、以及公开入口的预期重定向/界面；不暴露秘密或认证内容。

## 已知状态与版本转换

- 当前 Acorn 服务使用 Nix store 中的 `auth-mini-latest-2026-07-24`。
- 当前受控 package pin 指向 GitHub release asset `488807338`，版本标识为 `latest-2026-07-24`。
- 2026-09-02 读取官方 GitHub release API：当前 `latest` 的 Linux x86_64 资产 ID 为 `525860183`，资产更新时间为 `2026-08-23T05:19:25Z`，官方 SHA-256 为 `12abb29b97abd5579760dfcd3761235d5beeb53de806403124a79db470562b36`。
- 目标版本标识：`latest-2026-08-23`。

## 范围与边界

- 只改变 Auth Mini release pin；不改 systemd service 参数、SQLite 数据库、SMTP、Resend secret、Auth Mini Gateway、Nginx、Cloudflare、DNS、Access、用户或密钥。
- Axiom 仅为 build host；Acorn 仅为 target host。
- 不读取、复制、打印、注入或使用任何密码文件、token、密钥、cookie、SSH 私钥或其他凭据。
- 不使用 Acorn 本机构建作为 fallback。

## 回滚

- 配置回滚：恢复 `packages/auth-mini/default.nix` 的前一 asset ID、版本和 hash，再使用同一 Axiom build/Acorn target 命令重新部署。
- generation 回滚：在可获得合法 Acorn 管理授权时，执行目标主机的 NixOS generation rollback；不得以清理 `/var/lib/auth-mini` 或修改数据库作为版本回滚手段。

## 风险

- 认证服务切换会短暂重启 `auth-mini.service`，影响登录/令牌签发。
- GitHub `latest` 是可变发布入口；固定 asset ID、官方 digest 与 Nix SRI 共同构成 fail-closed pin。
- 实际远程 activation 需要目标主机 sudo 授权；Cybion executor 不得读取或代用任何密码文件。

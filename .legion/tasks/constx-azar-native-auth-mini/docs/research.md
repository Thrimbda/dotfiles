# Azar 原生 Auth Mini 部署现状证据

## 当前线上

- `constxd`、Nginx、`auth-mini-gateway-constx` 都 active。
- `constxd /api/auth/config` 返回 `{"enabled":false}`。
- constxd 仅监听 `127.0.0.1:3210`；gateway 在 `127.0.0.1:7782`；Nginx 对通常入口执行 `auth_request`。
- Nginx 对 `pair/connect/heartbeats/tool-results` 用精确 location 绕过 gateway，避免机器客户端进入网页登录重定向。

## Azar Auth Mini

`/jwks` 与 `/web/` 返回 200；OpenAPI 确认 HTTPS `redirect_uri` 的 hostname 形成 token audience。它能支撑 Const X 的 native auth，不需要服务端升级。

## 代码/部署依赖

当前 release SHA 是 `45c21f0a2f437cb11cb5e316c29d5ff08cbef471`，它带有旧 IIFE browser loader 和无 audience verifier。必须先合入并构建 `constxd-auth-mini-native-sdk` 的 release，才能安全启用 `[auth]`。

## 配置状态

`constxd serve` 管理 `/var/lib/constx/config/constx/constxd.toml`，并在每次启动时更新 portable Pi 字段。该文件是私有运行时状态，不能以 Nix 固定完整文件覆盖，也不应由 awk/sed 解析。目标 release 需要提供基于其现有 Config/TOML 原子 writer 的 `configure-auth enable|disable|check` 命令；Nix 只调用该命令。

2026-09-02 在 Axiom 的 `nixos-rebuild --help` 确认 `--specialisation` 能从 base 切入、切换 specialisation，且无该 flag 的 `switch` 回到 base system；因此 G1 staging 与 G2 base 可以在同一 closure 中构建和激活。

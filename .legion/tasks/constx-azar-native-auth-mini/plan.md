# Azar Const X 原生 Auth Mini 部署

- **name**: Azar Const X 原生 Auth Mini 部署
- **taskId**: `constx-azar-native-auth-mini`
- **goal**: 将 `constx.0xc1.wang` 从 `auth-mini-gateway` 前置认证切换到 Const X 自身的 Auth Mini JWT 验证，Nginx 只负责 TLS 和透明反代。
- **profile**: Strict

## 问题

当前 Azar 让 `auth-mini-gateway-constx` 负责网页登录，再对 Run Environment 的少数路径作 Nginx bypass。该拓扑重复了 Const X 已有的认证边界，并与原生 Auth Mini Browser SDK 集成不一致。

## 验收

- [ ] `constx.0xc1.wang` 的 Nginx vhost 透明代理 `constxd:3210`，不含 `auth_request` 或登录重定向。
- [ ] 目标 constxd release 的 `configure-auth` 子命令稳定启用/check/disable `[auth]` issuer/audience，且不覆盖已有运行时配置或秘密。
- [ ] `auth-mini-gateway-constx` 不再由 Nix 配置生成；其他 gateway 实例及 Auth Mini issuer 不受影响。
- [ ] 未认证用户 API 被 constxd 拒绝；实际 Auth Mini 登录可恢复 UI/API；Run Environment 的 pair/connect/heartbeat/tool-result 仍以机器 token 可用。
- [ ] 部署在 Axiom 构建、Azar 安装/activate；G0/G1/G2 staging 和回滚到 gateway 的每一个状态均有可执行 gate。
- [ ] 在已运行 G2 的同一认证拓扑上，将 merged source PR #83 的 `059eab4d6a8eac156333f9357838d8ab9acc203c` 作为 release uplift 安装；只换 target binary/release pin，不改变 ingress 或 Auth Mini runtime config。

## 约束

- 使用已存在的 Cloudflare DNS/ACME 与 Auth Mini issuer，不改变 DNS、证书、Auth Mini 数据库或秘密。
- 不在 Azar 构建 Nix system；需要 NixOS switch 时在 Axiom 构建后安装到 Azar。
- 不将 token、密码、age 解密内容或现有 config value 记录到仓库或证据。

## 风险

- 在原生 SDK release 未就绪时切换会锁住 UI；部署必须依赖已合并的 Const X release。
- managed config 属于运行时状态；错误的声明式写入可能抹掉用户配置，必须只调用目标 release 的原子 config 子命令。
- 浏览器登录是生产验收门；网关进程 active 不能替代该验证。

## 范围

- `hosts/acorn/modules/auth-mini.nix`：移除仅 Const X 的 gateway/vhost 责任。
- `hosts/acorn/modules/constx.nix`：添加透明 vhost 与安全、幂等的 auth config 保证。
- 任务证据、回滚说明与 Nix eval/build/deploy 验证。

## 非目标

- 不改 Auth Mini 服务端版本、用户、SMTP、Passkey、JWKS 或 Cloudflare。
- 不改变其他域名的 auth-mini-gateway 拓扑。
- 不改 Const X 源代码、Run Environment 协议或 Axiom 网络路由；源代码修复属于 `constxd-auth-mini-native-sdk`。

## 设计摘要

1. 先交付包含原生 Auth Mini SDK 和 audience verifier 的 Const X release。
2. 由目标 Const X release 的 `configure-auth` 管理 `[auth]` section，Nix 只调用 check，不解析 TOML。
3. 以 gateway staging specialisation 先激活目标 binary/auth，再切换默认的透明 Nginx vhost。
4. 使用 Axiom build / Azar install+switch；验证应用认证与完整机器协议两条路径。

## 关键主张

| Claim | 验证 |
| --- | --- |
| D1 | constx vhost 不再调用 auth-mini-gateway，但未认证用户 API 仍为 401。 |
| D2 | `auth-mini-gateway-constx` 已移除，其他 gateway instances 与 issuer 仍 healthy。 |
| D3 | 本机与 Axiom 的已配对 Run Environment 在切换后可连接并持续心跳。 |

## 阶段

1. spec-rfc
2. review-rfc
3. engineer
4. verify-change
5. review-change
6. delivery and production rollout

## Release uplift：PR #88 顶栏登出修复

- **goal**: 将已运行 G2 原生 Auth Mini 拓扑的 Const X release 从 `059eab4d6a8eac156333f9357838d8ab9acc203c` 提升为 PR #88 merge commit `a3cb397751e0101d957494be43c6a94bed1e611b`，使顶栏登出不再覆盖搜索。
- **acceptance**: Axiom 从该精确 source commit 的干净 worktree 构建 release；Azar 的 release manifest、systemd `ExecStart`、运行中 `/proc/<MainPID>/exe` 与 SHA-256 都绑定同一 binary；`constxd` health 与已启用的 Auth Mini config check 通过。
- **scope**: 仅更新 `hosts/acorn/modules/constx.nix` 的 `releaseSha`、本 task 的 release evidence，以及 Axiom build / Azar switch。
- **non-goals**: 不改变 native ingress、Nginx、Auth Mini issuer/JWT、managed runtime config、Run Environment 协议或 D3/D4 的既有 deferred 归属。
- **design summary**: 复用已审查的 G2 direct ingress 和既有 rollback release；这是同一拓扑下的 target-binary uplift，不引入新的设计分叉。
- **claims**: R1（objective / now / routine / high / block-stage）：Azar 的活跃 `constxd` 进程可重算地绑定 PR #88 release binary；R2（objective / deferred / routine / critical / defer-by-contract）：真实用户 Auth Mini 登录与 Run Environment E2E 继续由既有 D3/D4 owner 验证，不在本次 patch deployment 冒充通过。

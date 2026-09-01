# Research: Const X Azar Public Deployment

## 已验证现状

- `ssh azar` 到达 `aliyun-acorn`：NixOS 26.05、40 GiB root volume（约 28 GiB 可用）、1.8 GiB RAM、Nginx active；`auth-mini.service`、`auth-mini-gateway-auth-gateway.service`、`auth-mini-gateway-frps-acorn.service` 均 active。
- `127.0.0.1:3210` 与 `127.0.0.1:7782` 当前未监听；现有 Auth Mini / gateway 只监听 `127.0.0.1:7777`、`7778`、`7781`。
- Azar 运行时未安装 `constxd`、Node、Cargo 或 NPM。目标 NixOS 配置可求值，`pkgs.nodejs_22.version = 22.23.2`，满足 Const X 的 `>=22.19.0` 前置条件。
- 当前 `hosts/acorn` 已启用 Nginx，使用 `hosts/acorn/secrets/cloudflare-dns.env.age` 作为 DNS-01 ACME 环境文件；当前的受管证书 vhost 包括 `auth.0xc1.wang`、`auth-gateway.0xc1.wang`、`frps-acorn.0xc1.wang` 等。
- `hosts/acorn/modules/auth-mini.nix` 是既有 browser gateway 真源：每 hostname 创建独立 loopback gateway service、host-only session store、Nginx internal `/_auth` subrequest 和受保护的 upstream location。
- Const X current merged source 为 `45c21f0a2f437cb11cb5e316c29d5ff08cbef471`。其 `constxd` 启动时会将内嵌 Pi runtime 解包到自身 data root，但运行期要求 Node 在 `PATH`；server 配置仅允许 loopback listen。
- `crates/constxd/build.rs` 会从锁定的两个 `package-lock.json` 运行 root 和 Pi runtime 的 `npm ci`，编译时将 Web workbench 与 Pi runtime 打入单一 binary。远端 release build 必须以单 job 进行，避免 1.8 GiB RAM 超载。
- dotfiles 中 `hosts/charlie/secrets/cloudflare-api-token.age` 可由本机身份解密为 `CF_DNS_API_TOKEN`，Cloudflare token verify 与 `0xc1.wang` zone query 均成功；`constx.0xc1.wang` 当前无 A record。token 内容未输出或保存。

## 相关先例

- `acorn-cybion-ingress` 已验证 Acorn 的正确组合：DNS-only A record 到 `8.159.128.125`、DNS-01 ACME、`onlySSL` Nginx vhost、loopback upstream，以及禁用 proxy buffering / 24h timeout 的 SSE proxy 配置。
- `auth-mini-acorn-gateway` 的当前决策要求每一个受保护 hostname 独立 gateway instance；不能把 gateway cookie 跨域复用，也不能把 Auth Mini 或 gateway backend 公开监听。
- 最新 dotfiles commit `13fba91d` 仅给 Charlie 的现有 loopback Const X 添加 `constx-charlie.0xc1.space` Cloudflare Tunnel ingress；它不在 Azar 运行、不覆盖 `constx.0xc1.wang`，也没有证明当前请求已经完成。

## 候选方案

### A. Azar Nginx + 现有 Auth Mini gateway + DNS-only A（推荐）

新增受控 `constxd` systemd service、一个 `constx` gateway instance 和一个 Nginx vhost。Nginx 是唯一公网 listener，gateway 是唯一认证门；Cloudflare token 只管理 DNS record，ACME 继续由 Acorn 已有 age secret 完成。

优点：与 Acorn 当前 Auth Mini、TLS、DNS 及服务形态一致；不新增 Cloudflare Access policy；可静态检验生成的 Nginx/systemd 配置；既有 Auth Mini allowlist 不变。

代价：需要对 Auth Mini vhost helper 增加最小的 per-instance upstream/vhost proxy directives，并需要 root 执行 NixOS switch。

### B. Const X 内置 Auth Mini + 直接 Nginx vhost

为 constxd 预写完整 TOML `[auth]` 配置并在 Auth Mini DB 注册新的 page origin，Nginx 仅反代。

优点：使用 Const X 自身的 JWT/cookie 代码。

缺点：新增 Auth Mini DB origin 的可变状态、服务 bootstrap 配置、内外两层 token/session 对齐验证；比直接复用已运行的 gateway 多出一个高风险状态面。

### C. 新建 Cloudflare Tunnel / Access 入口

在 Azar 新建 connector、Tunnel hostname 和 Cloudflare Access application/policy。

优点：无需 DNS-only origin 暴露。

缺点：Azar 当前未运行 cloudflared；需要新的 Tunnel credential、Access policy 与外部控制面变更，且用户指定的是现有 `0xc1.wang`/Azar Nginx 形态。超出本次最小部署范围。

## 未验证项

- 修订前曾缺少 root 执行路径；`D-ROOT-001` 已由用户决定为 `axiom-tunnel` build host、`azar` target host，并以本机 owner-only password 文件配合 `--ask-sudo-password --sudo` 执行。两台主机的 password authentication 均已用无副作用 `sudo true` 验证。
- release binary 尚未构建，因而还没有可核对 SHA-256、portable Pi `doctor` 结果或真实 memory use。
- Nginx/ACME/gateway 的新 closure 尚未生成，故未验证生成配置、TLS、unauth redirect 或已认证 Browser path。
- 实际用户登录和首次 OpenAI Settings 配置必须由已有 Auth Mini 用户完成；它们不能由未认证 curl 代替。

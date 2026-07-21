# NAT 穿透全栈 Ubuntu 部署指南

本文面向负责部署和维护这套入口的运维人员。目标是在一台有公网 IP 的 Ubuntu 服务器上统一终止 HTTPS 和认证，再通过 FRP 访问 NAT 后 Ubuntu 主机上的 OpenCode 等应用；Cloudflare Tunnel + Access 作为独立的备用入口。

本文只写 Ubuntu，不包含 NixOS 配置。命令以 Ubuntu 22.04/24.04 x86_64 为基线；其他架构需要替换对应 release binary 和摘要。

## 1. 架构结论

### 1.1 主链路：FRP + Nginx + Auth Mini

```text
Browser
  |
  v
Acorn 公网 Ubuntu:443
  Nginx TLS 终止
  |
  +--> Acorn 本机 FRP remotePort
            |
            v
        frps:7000 <--- Axiom frpc 主动连出
                            |
                            v
                 Axiom auth-mini-gateway 实例
                     |        |
                     |        +--> auth-mini: https://auth.0xc1.wang
                     v
               Axiom 上的 loopback 应用
```

以 OpenCode 为例：

```text
https://opencode-axiom.0xc1.wang
  -> Acorn Nginx（TLS 终止，透明反代）
  -> FRP remotePort 127.0.0.1:18081
  -> Axiom frpc
  -> Axiom auth-mini-gateway 127.0.0.1:7780（认证 + 授权 + 反代）
  -> OpenCode 127.0.0.1:4096
```

当前部署中，保护 NAT 后应用的 gateway 运行在应用所在节点上（Axiom），以 `UPSTREAM_URL` 反向代理模式工作：gateway 自己完成认证和授权，再把请求转发给本机应用。Acorn Nginx 对这些域名只做 TLS 终止和转发，不做 `auth_request`。

Acorn 本机保护的服务（frps dashboard）仍使用第二种模式：gateway 在 Acorn 上运行，Nginx 通过 `auth_request` 调用 gateway 的 `/auth/check`，认证通过后由 Nginx 转发到本机 upstream。两种模式共用同一个 auth-mini issuer。

### 1.2 备用链路：Cloudflare Tunnel + Access

```text
Browser
  -> Cloudflare Access
  -> Cloudflare edge
  -> Axiom cloudflared 主动连出
  -> OpenCode 127.0.0.1:4096
```

当前备用入口使用独立域名，例如 `opencode-axiom.0xc1.space`。它是并行的人工切换入口，不是 FRP 故障后自动接管流量。若需要同一域名自动故障转移，还要单独设计健康检查、DNS 或负载均衡策略。

### 1.3 安全边界

这套架构必须同时满足以下条件：

- OpenCode、Gatus、auth-mini、auth-mini-gateway 和 frps dashboard 只监听 loopback，或由主机防火墙阻止公网访问。
- Acorn 公网只开放 `443`、FRP 控制端口 `7000`，以及确实需要的 SSH 入口。
- FRP 的 HTTP remotePort `18080`、`18081` 不得出现在 UFW 或云安全组的公网放行规则中。
- Axiom 上 frpc 的 HTTP proxy 必须指向本机 gateway 端口（`7779`/`7780`），不能直接指向应用端口（`8080`/`4096`），否则 remotePort 会变成无认证入口。
- 每个受保护域名运行一个独立的 auth-mini-gateway 实例和 SQLite 文件。
- Cloudflare Tunnel 只提供传输；Cloudflare Access 才是备用入口的用户认证边界。
- OpenCode 等远程执行类应用等价于远程 shell，不能只依赖“端口难猜”或未代理的公网地址。

## 2. 当前端口和域名

本文沿用当前部署名称。迁移到其他域名时，必须同时修改 DNS、证书、auth-mini issuer/RP ID、gateway public base URL 和 Nginx `server_name`。

| 组件 | 主机 | 监听地址 | 用途 |
| --- | --- | --- | --- |
| frps | Acorn | `0.0.0.0:7000` | frpc 控制连接 |
| frps dashboard | Acorn | `127.0.0.1:7500` | 经 Nginx 和 gateway 发布 |
| auth-mini | Acorn | `127.0.0.1:7777` | 认证 issuer 和登录 UI |
| auth-gateway | Acorn | `127.0.0.1:7778` | 独立健康/登录入口，可选保留 |
| frps gateway | Acorn | `127.0.0.1:7781` | 保护 frps dashboard |
| status gateway | Axiom | `127.0.0.1:7779` | 保护 Gatus |
| OpenCode gateway | Axiom | `127.0.0.1:7780` | 保护 OpenCode |
| Axiom SSH remotePort | Acorn | `0.0.0.0:2225` | FRP SSH 入口 |
| Gatus remotePort | Acorn | `0.0.0.0:18080` | 仅供 Acorn Nginx 本机访问 |
| OpenCode remotePort | Acorn | `0.0.0.0:18081` | 仅供 Acorn Nginx 本机访问 |
| SSH | Axiom | 通常为 `0.0.0.0/[::]:22` | UFW 限制 LAN 来源；frpc 通过 `127.0.0.1:22` 访问 |
| Gatus | Axiom | `127.0.0.1:8080` | gateway 本地 upstream |
| OpenCode | Axiom | `127.0.0.1:4096` | gateway/cloudflared 本地目标 |
| cloudflared metrics | Axiom | `127.0.0.1:20241` | `/ready` 和 connector 指标 |

公网域名：

| 域名 | 主链路用途 |
| --- | --- |
| `auth.0xc1.wang` | auth-mini UI 和 issuer |
| `auth-gateway.0xc1.wang` | gateway 独立入口 |
| `status-axiom.0xc1.wang` | Gatus，经 FRP + gateway |
| `opencode-axiom.0xc1.wang` | OpenCode，经 FRP + gateway |
| `frps-acorn.0xc1.wang` | frps dashboard，经 gateway |

备用域名：

| 域名 | 备用链路用途 |
| --- | --- |
| `opencode-axiom.0xc1.space` | Cloudflare Tunnel + Access -> OpenCode |
| `status-axiom.0xc1.space` | Cloudflare Tunnel + Access -> Gatus |

## 3. 部署前准备

### 3.1 主机角色

Acorn 是公网 Ubuntu 服务器，需要：

- 固定公网 IP，当前为 `8.159.128.125`。
- 公网 DNS 管理权限。
- frps、Nginx、auth-mini、auth-mini-gateway、Certbot。
- 云安全组和本机 UFW 的修改权限。

Axiom 是 NAT 后 Ubuntu 主机，需要：

- 能主动访问 Acorn TCP `7000`。
- OpenCode 等应用先在 loopback 正常运行。
- frpc。
- auth-mini-gateway（保护本机应用的 gateway 实例运行在 Axiom）。
- 能主动访问 `https://auth.0xc1.wang`（gateway 需要验证 issuer/JWKS）。
- 可选 cloudflared，并能主动访问 Cloudflare 网络。

### 3.2 Secret 分类

不要混用以下凭证：

| Secret | 用途 | 建议路径 |
| --- | --- | --- |
| FRP token | frpc 对 frps 认证 | 两端 `/etc/frp/frp-token` |
| FRP TLS server key | frpc 校验 frps 身份 | Acorn `/etc/frp/tls/frps-acorn.key` |
| FRP private CA key | 签发/轮换 FRP 证书 | 只在离线或受控运维环境保存 |
| gateway cookie secret | 签名浏览器 gateway cookie | 两端各自 `/etc/auth-mini-gateway/secret.env` |
| gateway allowlist | 精确邮箱或用户 ID 授权 | 两端各自 `/etc/auth-mini-gateway/secret.env` |
| Cloudflare DNS API token | Certbot DNS-01 | Acorn `/etc/letsencrypt/cloudflare.ini` |
| Tunnel credentials JSON | 运行一个指定 tunnel | Axiom `/etc/cloudflared/<UUID>.json` |
| Cloudflare 管理 API token | 自动化 DNS/Access 控制面 | 不交给 cloudflared runtime |
| SMTP API key | auth-mini 邮件 OTP | 写入 auth-mini SQLite 配置 |
| OpenCode provider credentials | 调用模型提供商 | OpenCode 服务用户的 HOME |

所有 secret 文件应满足：

- 不提交 Git。
- 不放在 world-readable 文件中。
- 不作为命令行参数传入进程。
- 不输出到 shell history 或 systemd journal。
- 备份时按凭证材料加密处理。

### 3.3 Ubuntu 基础包

两台主机都执行：

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl git iproute2 openssl ufw
sudo timedatectl set-ntp true
```

Acorn 额外安装：

```bash
sudo apt-get install -y nginx certbot python3-certbot-dns-cloudflare
nginx -V 2>&1 | tr ' ' '\n' | grep -- --with-http_auth_request_module
```

最后一条命令必须看到 `--with-http_auth_request_module`。Ubuntu 官方 Nginx 包通常已经包含该模块。

### 3.4 推荐执行顺序

1. 按第 3.5 节先配置 UFW 和云安全组，再启动任何 FRP proxy。
2. 在 Axiom 启动并验证 OpenCode/Gatus loopback 服务。
3. 在 Acorn 部署 auth-mini，在 Axiom 部署 gateway 实例，在 Acorn 部署 frps dashboard 的 gateway 实例。
4. 在 Acorn/Axiom 部署 frps/frpc，并验证 Acorn 本机 remotePort。
5. 通过 SSH loopback 转发初始化 auth-mini 管理员，不能先公开未初始化的 setup API。
6. 申请 DNS-01 证书并启用 Nginx。
7. 通过公网 HTTPS 配置 auth-mini issuer、RP ID、SMTP 和用户凭证。
8. 完成允许身份、拒绝身份、logout、长连接和公网端口检查。
9. 最后按需部署 Cloudflare Tunnel + Access 备用入口。

### 3.5 启动前防火墙门禁

必须在启动 frps/frpc 前完成本节。frpc 注册 TCP proxy 后，FRP remotePort 会在 Acorn 的 `0.0.0.0` 上监听；若 UFW 和云安全组尚未收紧，`18080/18081` 会绕过 Nginx 和认证直接暴露应用。

Acorn 先设置实际来源变量。不要把示例尖括号直接粘贴进 shell：

```bash
(
  set -euo pipefail
  : "${OPERATOR_CIDR:?先 export OPERATOR_CIDR，例如你的公网 IP/32}"
  : "${AXIOM_EGRESS_CIDR:?先 export AXIOM_EGRESS_CIDR，例如 Axiom 出口 IP/32}"

  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw allow in on lo
  sudo ufw allow proto tcp from "${OPERATOR_CIDR}" to any port 22
  sudo ufw allow 443/tcp
  sudo ufw allow proto tcp from "${AXIOM_EGRESS_CIDR}" to any port 7000
  sudo ufw allow proto tcp from "${OPERATOR_CIDR}" to any port 2225
  sudo ufw status numbered
  sudo ufw enable
)
sudo ufw status numbered
```

在关闭当前 SSH 会话前，从第二个终端确认仍能登录 Acorn。Axiom 出口不固定时可以把 `AXIOM_EGRESS_CIDR` 明确设为 `0.0.0.0/0`，但必须依赖强随机 token、FRP TLS 和持续升级。

Axiom：

```bash
(
  set -euo pipefail
  : "${HOME_LAN_CIDR:?先 export HOME_LAN_CIDR，例如家庭 LAN CIDR}"

  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw allow in on lo
  sudo ufw allow proto tcp from "${HOME_LAN_CIDR}" to any port 22
  sudo ufw status numbered
  sudo ufw enable
)
sudo ufw status numbered
```

同时在云安全组只允许 `22`、`443`、受限来源的 `7000/2225`。确认安全组没有 `7500`、`7777-7781`、`18080-18081` 放行规则后，才允许继续启动 FRP。

## 4. 部署 OpenCode 等本地应用

先让应用在 Axiom 本机 loopback 正常运行，再接 FRP 或 cloudflared。不要先暴露应用，再补认证。

### 4.1 安装 OpenCode

当前部署使用用户 `c1`，二进制位于 `/home/c1/.opencode/bin/opencode`。若使用其他用户，请同步替换下面的用户、HOME、工作目录和二进制路径。

生产环境固定 release binary。当前验证版本为 `1.17.20`：

```bash
(
  set -euo pipefail
  OPENCODE_VERSION=1.17.20
  OPENCODE_SHA256=b7100c0ad0980fba25d595123b4219a6fdc1fbd456dcb64859236741e199c564
  ARCHIVE="opencode-linux-x64.tar.gz"
  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "${TMP_DIR}"' EXIT

  curl -fL "https://github.com/anomalyco/opencode/releases/download/v${OPENCODE_VERSION}/${ARCHIVE}" -o "${TMP_DIR}/${ARCHIVE}"
  printf '%s  %s\n' "${OPENCODE_SHA256}" "${TMP_DIR}/${ARCHIVE}" | sha256sum -c -
  tar -xzf "${TMP_DIR}/${ARCHIVE}" -C "${TMP_DIR}"
  sudo install -d -o c1 -g c1 -m 0750 /home/c1/.opencode/bin
  sudo install -o c1 -g c1 -m 0755 "${TMP_DIR}/opencode" /home/c1/.opencode/bin/opencode
)
sudo -iu c1 /home/c1/.opencode/bin/opencode --version
```

升级时从 GitHub immutable release 重新取得 asset digest 并更新固定值。不要让常驻服务在重启时调用可变安装脚本。升级后要重新验证 HTTP、SSE/WebSocket、模型认证和工作目录权限。

在启动常驻服务前，以同一个用户完成模型提供商认证和必要配置：

```bash
sudo -iu c1 /home/c1/.opencode/bin/opencode
```

OpenCode 的 provider 凭证和配置属于服务用户 HOME。不要用 root 完成认证后再让 `c1` 启动服务。

### 4.2 OpenCode systemd 服务

创建 `/etc/systemd/system/opencode-server.service`：

```ini
[Unit]
Description=OpenCode server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=c1
Group=c1
WorkingDirectory=/home/c1
Environment=HOME=/home/c1
Environment=OPENCODE_ENABLE_EXA=1
Environment=OPENCODE_EXPERIMENTAL=true
ExecStart=/home/c1/.opencode/bin/opencode serve --hostname 127.0.0.1 --port 4096
Restart=on-failure
RestartSec=10
NoNewPrivileges=true
PrivateTmp=true
UMask=0077

[Install]
WantedBy=multi-user.target
```

启动并验证：

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now opencode-server.service
sudo systemctl status opencode-server.service
curl -fsS http://127.0.0.1:4096/global/health
```

OpenCode 官方还支持 `OPENCODE_SERVER_PASSWORD` 和 `OPENCODE_SERVER_USERNAME` 的 HTTP Basic Auth。当前栈由 auth-mini-gateway 或 Cloudflare Access 负责入口认证，因此没有再增加一层 Basic Auth。若启用 OpenCode 自带密码，浏览器和客户端会面对第二层认证，必须单独验证兼容性。

### 4.3 其他应用的接入规则

Gatus 或其他 Web 服务按同一模式部署：

1. 使用独立 systemd 用户。
2. 只监听 `127.0.0.1:<port>`。
3. 先完成本机健康检查。
4. 在 Axiom 增加一个 gateway 实例（`UPSTREAM_URL` 指向本机应用）和独立 SQLite。
5. 在 frpc 增加一个唯一 remotePort，`localPort` 指向 gateway 端口而不是应用端口。
6. 在 Acorn Nginx 增加一个透明反代 vhost 指向该 remotePort。
7. 如需兜底，再给 cloudflared 增加独立 hostname ingress。

### 4.4 Gatus 是可选示例

本文用现有的 `127.0.0.1:8080` Gatus 服务展示第二个应用入口，但不包含 Gatus 本身的安装。如果不部署 Gatus，必须同步删除以下全部配置，而不是只删除 frpc proxy：

- frps `allowPorts` 中的 `18080`。
- frpc 的 `axiom-gatus-http` proxy。
- Axiom 上 `/etc/auth-mini-gateway/status-axiom.env` 和对应 systemd 实例。
- `status-axiom.0xc1.wang` DNS、Certbot SAN 和 Nginx vhost。
- cloudflared 中 `status-axiom.0xc1.space` ingress，以及该 hostname 的 Access app 和 DNS route。
- 所有 `8080`、`7779`、`18080`、status hostname 健康检查。

## 5. 部署 FRP

### 5.1 安装固定版本

当前仓库使用 FRP `0.65.0`。两端应安装同一兼容版本。以下示例为 Ubuntu x86_64/amd64：

```bash
(
  set -euo pipefail
  FRP_VERSION=0.65.0
  FRP_ARCHIVE="frp_${FRP_VERSION}_linux_amd64.tar.gz"
  FRP_SHA256="52ced8c5fdf772f48a9909da4c10c7568c061861946ac9af7a86eeaf14b7e6d5"
  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "${TMP_DIR}"' EXIT

  curl -fL "https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/${FRP_ARCHIVE}" -o "${TMP_DIR}/${FRP_ARCHIVE}"
  printf '%s  %s\n' "${FRP_SHA256}" "${TMP_DIR}/${FRP_ARCHIVE}" | sha256sum -c -
  tar -xzf "${TMP_DIR}/${FRP_ARCHIVE}" -C "${TMP_DIR}"
  sudo install -m 0755 "${TMP_DIR}/frp_${FRP_VERSION}_linux_amd64/frps" /usr/local/bin/frps
  sudo install -m 0755 "${TMP_DIR}/frp_${FRP_VERSION}_linux_amd64/frpc" /usr/local/bin/frpc
)
frps --version
frpc --version
```

升级时重新核对官方 release 和 SHA-256，不要只替换版本字符串。

### 5.2 创建服务用户、token 和 FRP TLS 身份

两台主机都执行：

```bash
sudo useradd --system --user-group --no-create-home --shell /usr/sbin/nologin frp
sudo install -d -o root -g frp -m 0750 /etc/frp
sudo install -d -o root -g root -m 0755 /usr/local/libexec
```

在可信机器生成一个稳定的高熵十六进制 token：

```bash
openssl rand -hex 48
```

将同一个 token 安全地写入 Acorn 和 Axiom 的 `/etc/frp/frp-token`，然后设置：

```bash
sudo chown root:root /etc/frp/frp-token
sudo chmod 0600 /etc/frp/frp-token
```

下面使用 systemd `LoadCredential`，在服务启动时把 token 注入 `/run` 中的最终 TOML，避免 token 出现在模板、unit 和进程参数里。

`transport.tls.force=true` 只能强制加密，不能单独证明服务端身份。生产环境还必须让 frpc 信任一个受控 CA，并校验 frps 证书名称，避免主动中间人终止 TLS 后窃取 FRP token。

在离线或受控运维机器生成 CA 和 frps 证书：

```bash
(
  set -euo pipefail
  umask 077
  mkdir frp-pki
  cd frp-pki

  openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:3072 -out ca.key
  openssl req -x509 -new -sha256 -days 3650 \
    -key ca.key \
    -subj '/CN=FRP Private CA' \
    -out ca.crt

  openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:3072 -out frps-acorn.key
  openssl req -new -sha256 \
    -key frps-acorn.key \
    -subj '/CN=frps-acorn.0xc1.wang' \
    -out frps-acorn.csr
  printf '%s\n' 'subjectAltName=DNS:frps-acorn.0xc1.wang' > frps-acorn.ext
  openssl x509 -req -sha256 -days 825 \
    -in frps-acorn.csr \
    -CA ca.crt \
    -CAkey ca.key \
    -CAcreateserial \
    -extfile frps-acorn.ext \
    -out frps-acorn.crt

  openssl verify -CAfile ca.crt frps-acorn.crt
)
```

`ca.key` 只保留在离线/受控环境，不部署到 Acorn 或 Axiom。

安全传输后，在 Acorn 安装服务端证书和私钥：

```bash
sudo install -d -o root -g frp -m 0750 /etc/frp/tls
sudo install -o root -g frp -m 0644 frps-acorn.crt /etc/frp/tls/frps-acorn.crt
sudo install -o root -g frp -m 0640 frps-acorn.key /etc/frp/tls/frps-acorn.key
```

在 Axiom 只安装 CA 公钥证书：

```bash
sudo install -d -o root -g frp -m 0750 /etc/frp/tls
sudo install -o root -g frp -m 0644 ca.crt /etc/frp/tls/ca.crt
```

### 5.3 安装运行时配置渲染器

两台主机创建 `/usr/local/libexec/render-frp-config`：

```bash
#!/usr/bin/env bash
set -euo pipefail

template="${1:?template path is required}"
output="${2:?output path is required}"
token_file="${CREDENTIALS_DIRECTORY:?systemd credential directory is missing}/frp-token"
token="$(tr -d '\r\n' < "${token_file}")"

if [[ ! "${token}" =~ ^[0-9A-Fa-f]{64,}$ ]]; then
  echo "FRP token must be a non-empty high-entropy hex string" >&2
  exit 1
fi

umask 077
tmp="${output}.tmp"
while IFS= read -r line || [[ -n "${line}" ]]; do
  printf '%s\n' "${line//@FRP_TOKEN@/${token}}"
done < "${template}" > "${tmp}"
mv "${tmp}" "${output}"
```

设置权限：

```bash
sudo chown root:root /usr/local/libexec/render-frp-config
sudo chmod 0755 /usr/local/libexec/render-frp-config
```

### 5.4 Acorn frps 配置

创建 `/etc/frp/frps.toml.in`：

```toml
bindAddr = "0.0.0.0"
bindPort = 7000

auth.method = "token"
auth.token = "@FRP_TOKEN@"

transport.tls.force = true
transport.tls.certFile = "/etc/frp/tls/frps-acorn.crt"
transport.tls.keyFile = "/etc/frp/tls/frps-acorn.key"

webServer.addr = "127.0.0.1"
webServer.port = 7500

allowPorts = [
  { single = 2225 },
  { single = 18080 },
  { single = 18081 }
]
```

`allowPorts` 限制 frpc 只能注册当前批准的 remotePort。增加新应用时必须显式更新该列表。

FRP 0.65 客户端默认启用 TLS；这里仍在 frps 上显式 `force`，并使用第 5.2 节的私有 CA 身份。

创建 `/etc/systemd/system/frps.service`：

```ini
[Unit]
Description=FRP server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=frp
Group=frp
LoadCredential=frp-token:/etc/frp/frp-token
RuntimeDirectory=frps
RuntimeDirectoryMode=0700
WorkingDirectory=/run/frps
ExecStartPre=/usr/local/libexec/render-frp-config /etc/frp/frps.toml.in /run/frps/frps.toml
ExecStart=/usr/local/bin/frps -c /run/frps/frps.toml
Restart=always
RestartSec=5
NoNewPrivileges=true
PrivateTmp=true
ProtectHome=true
ProtectSystem=strict
ProtectControlGroups=true
ProtectKernelModules=true
ProtectKernelTunables=true
ReadOnlyPaths=/etc/frp
ReadWritePaths=/run/frps
UMask=0077

[Install]
WantedBy=multi-user.target
```

启动并验证：

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now frps.service
sudo /usr/local/bin/frps verify -c /run/frps/frps.toml
sudo systemctl status frps.service
sudo ss -ltnp | grep -E ':(7000|7500)\b'
```

预期 `7000` 对外监听，`7500` 只监听 `127.0.0.1`。

### 5.5 Axiom frpc 配置

创建 `/etc/frp/frpc.toml.in`：

```toml
serverAddr = "8.159.128.125"
serverPort = 7000
loginFailExit = false

auth.method = "token"
auth.token = "@FRP_TOKEN@"

transport.tls.enable = true
transport.tls.trustedCaFile = "/etc/frp/tls/ca.crt"
transport.tls.serverName = "frps-acorn.0xc1.wang"

[[proxies]]
name = "axiom-ssh"
type = "tcp"
localIP = "127.0.0.1"
localPort = 22
remotePort = 2225

[[proxies]]
name = "axiom-gatus-http"
type = "tcp"
localIP = "127.0.0.1"
localPort = 7779
remotePort = 18080

[[proxies]]
name = "axiom-opencode-http"
type = "tcp"
localIP = "127.0.0.1"
localPort = 7780
remotePort = 18081
```

`localPort` 指向 Axiom 本机 gateway 端口，不是应用端口。流量经 FRP 到达 Axiom 后先过 gateway 认证，再由 gateway 转发到 `8080`/`4096`。

没有部署 Gatus 时，按第 4.4 节删除整条 status 链路。

创建 `/etc/systemd/system/frpc.service`：

```ini
[Unit]
Description=FRP client
After=network-online.target auth-mini-gateway@status-axiom.service auth-mini-gateway@opencode-axiom.service
Wants=network-online.target auth-mini-gateway@status-axiom.service auth-mini-gateway@opencode-axiom.service

[Service]
Type=simple
User=frp
Group=frp
LoadCredential=frp-token:/etc/frp/frp-token
RuntimeDirectory=frpc
RuntimeDirectoryMode=0700
WorkingDirectory=/run/frpc
ExecStartPre=/usr/local/libexec/render-frp-config /etc/frp/frpc.toml.in /run/frpc/frpc.toml
ExecStart=/usr/local/bin/frpc -c /run/frpc/frpc.toml
Restart=always
RestartSec=5
NoNewPrivileges=true
PrivateTmp=true
ProtectHome=true
ProtectSystem=strict
ProtectControlGroups=true
ProtectKernelModules=true
ProtectKernelTunables=true
ReadOnlyPaths=/etc/frp
ReadWritePaths=/run/frpc
UMask=0077

[Install]
WantedBy=multi-user.target
```

启动并验证：

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now frpc.service
sudo /usr/local/bin/frpc verify -c /run/frpc/frpc.toml
sudo systemctl status frpc.service
sudo journalctl -u frpc.service -n 100 --no-pager
```

回到 Acorn 验证 FRP 后端。此时 remotePort 后面是 Axiom 上的 gateway，未认证请求应被 gateway 重定向到登录页，而不是直接命中应用：

```bash
curl -i http://127.0.0.1:18081/
curl -i http://127.0.0.1:18080/
ssh -p 2225 c1@127.0.0.1
```

预期 `18080`/`18081` 返回 `302` 指向 `https://auth.0xc1.wang` 登录流程。若返回应用本身的响应（如 OpenCode health JSON），说明 frpc 错配到了应用端口，必须立即修正。

同时在 Axiom 验证 gateway 本机健康：

```bash
curl -i http://127.0.0.1:7779/healthz
curl -i http://127.0.0.1:7780/healthz
```

只运行已部署的检查。没有 Gatus 时不要测试 `18080` 和 `7779`。

### 5.6 Clash/Mihomo TUN 绕行，可选

若 Axiom 使用 Clash/Mihomo TUN，frpc 到 Acorn 的流量可能被代理规则截走。当前部署在 frpc 启动前增加优先级 `8500` 的策略路由。

创建 `/etc/systemd/system/frpc-acorn-direct-route.service`：

```ini
[Unit]
Description=Route Axiom frpc traffic to Acorn outside Clash/Mihomo
After=network-online.target clash-verge.service
Wants=network-online.target
Before=frpc.service

[Service]
Type=oneshot
ExecStartPre=-/usr/sbin/ip -4 rule del priority 8500
ExecStart=/usr/sbin/ip -4 rule add priority 8500 to 8.159.128.125/32 lookup main
ExecStart=-/usr/sbin/ip -4 route flush cache
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

然后给 `frpc.service` 的 `[Unit]` 增加：

```ini
After=frpc-acorn-direct-route.service
Wants=frpc-acorn-direct-route.service
Requires=frpc-acorn-direct-route.service
```

启用并检查：

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now frpc-acorn-direct-route.service
ip -4 rule show | grep 8500
ip -4 route get 8.159.128.125
sudo systemctl restart frpc.service
```

没有 TUN 路由问题时不要增加这条主机特例。若 Ubuntu 上的 Clash/Mihomo unit 不是 `clash-verge.service`，把 `After=` 中的名称替换为实际安装策略路由的 unit。

## 6. 部署 auth-mini

### 6.1 安装 release binary

auth-mini 当前发布 Linux x86_64 二进制。上游只有可变 `latest` URL，因此下面固定当前 `2026-07-12` artifact 的独立 SHA-256；上游更新后命令应失败，不能自动接受新摘要。

```bash
(
  set -euo pipefail
  AUTH_MINI_SHA256=3852e456f2a456b6a2f8cbf6d918659aad9256ff86c3a3f2eac2a1a27099b159
  ARCHIVE=auth-mini-linux-x86_64.tar.gz
  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "${TMP_DIR}"' EXIT

  curl -fL "https://github.com/zccz14/auth-mini/releases/download/latest/${ARCHIVE}" -o "${TMP_DIR}/${ARCHIVE}"
  printf '%s  %s\n' "${AUTH_MINI_SHA256}" "${TMP_DIR}/${ARCHIVE}" | sha256sum -c -
  tar -xzf "${TMP_DIR}/${ARCHIVE}" -C "${TMP_DIR}"
  sudo install -m 0755 "${TMP_DIR}/auth-mini" /usr/local/bin/auth-mini
)
test -x /usr/local/bin/auth-mini
```

### 6.2 用户和 systemd 服务

```bash
sudo useradd --system --user-group --home-dir /var/lib/auth-mini --create-home --shell /usr/sbin/nologin auth-mini
sudo chmod 0750 /var/lib/auth-mini
```

创建 `/etc/systemd/system/auth-mini.service`：

```ini
[Unit]
Description=Auth Mini authentication server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=auth-mini
Group=auth-mini
WorkingDirectory=/var/lib/auth-mini
ExecStart=/usr/local/bin/auth-mini --host 127.0.0.1 --port 7777 --db /var/lib/auth-mini/auth-mini.sqlite
Restart=on-failure
RestartSec=5
StateDirectory=auth-mini
StateDirectoryMode=0750
NoNewPrivileges=true
PrivateTmp=true
ProtectHome=true
ProtectSystem=strict
ReadWritePaths=/var/lib/auth-mini
UMask=0077

[Install]
WantedBy=multi-user.target
```

启动：

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now auth-mini.service
sudo systemctl status auth-mini.service
curl -I http://127.0.0.1:7777/web/
```

首次启动会自动创建 SQLite schema、`app_meta` 和 JWKS。

### 6.3 初始化管理员和应用元数据

必须在公开 Nginx vhost 前，从 Acorn loopback 完成管理员 bootstrap。可以从运维机器建立 SSH 转发：

```bash
ssh -N -L 17777:127.0.0.1:7777 c1@8.159.128.125
```

然后只在运维机器浏览器打开 `http://127.0.0.1:17777/web/` 完成 setup。管理员私钥只保存在受控运维设备。完成后关闭 SSH 转发，并确认 setup 页面/API 不再接受第二个管理员初始化请求。

若使用 API，形状如下：

```bash
curl -X PUT http://127.0.0.1:7777/admin/setup \
  -H 'content-type: application/json' \
  -d '{"admin_ed25519":{"name":"ops laptop","public_key":"<base64url-ed25519-public-key>"}}'
```

私钥不得上传到 Acorn、写入文档或进入 shell history。

管理员 bootstrap 完成后，再继续第 8、9 节发布公网 HTTPS。随后从 `https://auth.0xc1.wang/web/` 登录管理员并配置：

| 字段 | 当前值 |
| --- | --- |
| issuer | `https://auth.0xc1.wang` |
| Passkey RP ID | `auth.0xc1.wang` |
| WebAuthn origin | 从 issuer 得到 `https://auth.0xc1.wang` |

issuer 必须与 gateway 的 `AUTH_MINI_ISSUER`、JWT `iss` 和公网 HTTPS 地址完全一致。RP ID 只写 hostname，不带 scheme 或路径。

### 6.4 SMTP / Resend

当前邮件 OTP 使用：

| 字段 | 值 |
| --- | --- |
| host | `smtp.resend.com` |
| port | `465` |
| username | `resend` |
| secure | `true`，implicit TLS |
| from | `auth-mini <auth@0xc1.space>` |
| password | Resend API key，不写入本文 |

SMTP 配置由 auth-mini 保存到 `/var/lib/auth-mini/auth-mini.sqlite`。单独保存 API key 不等于 auth-mini 已配置 SMTP；数据库恢复、重建或 key 轮换后，必须通过管理员 UI 或经过认证的 `/admin/config` 再次写入并实际发送 OTP 验证。

## 7. 部署 auth-mini-gateway

### 7.1 固定源码版本并构建

当前使用 commit：

```text
f0519d1fcfbf49be43602f7a25ad2373434366fe
```

安装构建依赖：

```bash
sudo apt-get install -y build-essential git pkg-config libssl-dev libsqlite3-dev
```

使用与当前仓库构建环境一致的 Rust `1.91.1`，并构建固定 commit：

```bash
(
  set -euo pipefail
  RUST_TOOLCHAIN=1.91.1
  GATEWAY_REV=f0519d1fcfbf49be43602f7a25ad2373434366fe
  BUILD_DIR="$(mktemp -d)"
  trap 'rm -rf "${BUILD_DIR}"' EXIT

  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
  . "${HOME}/.cargo/env"
  rustup toolchain install "${RUST_TOOLCHAIN}" --profile minimal

  git clone https://github.com/Thrimbda/auth-mini-gateway.git "${BUILD_DIR}/auth-mini-gateway"
  git -C "${BUILD_DIR}/auth-mini-gateway" checkout --detach "${GATEWAY_REV}"
  test "$(git -C "${BUILD_DIR}/auth-mini-gateway" rev-parse HEAD)" = "${GATEWAY_REV}"
  cargo "+${RUST_TOOLCHAIN}" build \
    --locked \
    --release \
    --bin auth-mini-gateway \
    --manifest-path "${BUILD_DIR}/auth-mini-gateway/Cargo.toml"
  sudo install -m 0755 \
    "${BUILD_DIR}/auth-mini-gateway/target/release/auth-mini-gateway" \
    /usr/local/bin/auth-mini-gateway
)
```

可以在独立构建机完成构建，再把经过摘要校验的 release binary 部署到目标主机。不要在每次服务重启时从 GitHub 动态构建。Acorn 和 Axiom 都需要安装 `/usr/local/bin/auth-mini-gateway`：Acorn 运行 auth-gateway 和 frps dashboard 实例，Axiom 运行 status 和 OpenCode 实例。

### 7.2 用户、目录和公共环境

Acorn 和 Axiom 都执行：

```bash
sudo useradd --system --user-group --home-dir /var/lib/auth-mini-gateway --create-home --shell /usr/sbin/nologin auth-mini-gateway
sudo install -d -o auth-mini-gateway -g auth-mini-gateway -m 0750 /var/lib/auth-mini-gateway
sudo install -d -o root -g auth-mini-gateway -m 0750 /etc/auth-mini-gateway
```

两端创建 `/etc/auth-mini-gateway/base.env`：

```env
HOST=127.0.0.1
AUTH_MINI_ISSUER=https://auth.0xc1.wang
AUTH_MINI_PUBLIC_BASE_URL=https://auth.0xc1.wang
COOKIE_SECURE=true
COOKIE_SAME_SITE=lax
SESSION_TTL_SECONDS=28800
LOGIN_STATE_TTL_SECONDS=300
REFRESH_SKEW_SECONDS=60
LOGOUT_REDIRECT=/
```

Axiom 的 `base.env` 额外追加节点模式参数：

```env
SESSION_ABSOLUTE_TTL_SECONDS=2592000
SESSION_TOUCH_INTERVAL_SECONDS=3600
TRUSTED_PROXY_CIDRS=
GATEWAY_MAX_DOWNSTREAM_CONNECTIONS=256
GATEWAY_MAX_ACTIVE_UPSTREAMS=128
GATEWAY_MAX_BLOCKING_RESOLVERS=8
```

`TRUSTED_PROXY_CIDRS` 保持为空：请求经 FRP 从 loopback 进入，不信任任何代理来源头。

两端各自创建 `/etc/auth-mini-gateway/secret.env`，使用各自独立的 cookie secret：

```env
GATEWAY_COOKIE_SECRET=<openssl rand -base64 48 生成并稳定保存的值>
ALLOW_EMAILS=<逗号分隔的精确邮箱>
ALLOW_USER_IDS=<可选，逗号分隔的 auth-mini user id>
```

不要添加 `REQUIRE_PASSKEY`。认证方法由 auth-mini 决定；gateway 只验证 session/JWT 并执行精确身份 allowlist。历史上由 gateway 强制 Passkey 会把有效的 Email OTP 用户错误拒绝为 `403`。

两端设置权限：

```bash
sudo chown root:auth-mini-gateway /etc/auth-mini-gateway/base.env /etc/auth-mini-gateway/secret.env
sudo chmod 0640 /etc/auth-mini-gateway/base.env /etc/auth-mini-gateway/secret.env
```

### 7.3 每个域名一个实例

Acorn 上创建两个实例。`/etc/auth-mini-gateway/auth-gateway.env`：

```env
PORT=7778
GATEWAY_PUBLIC_BASE_URL=https://auth-gateway.0xc1.wang
GATEWAY_DB=/var/lib/auth-mini-gateway/auth-gateway.sqlite
```

`/etc/auth-mini-gateway/frps-acorn.env`：

```env
PORT=7781
GATEWAY_PUBLIC_BASE_URL=https://frps-acorn.0xc1.wang
GATEWAY_DB=/var/lib/auth-mini-gateway/frps-acorn.sqlite
```

这两个实例不设置 `UPSTREAM_URL`：它们只提供 `/healthz`、`/login`、`/logout`、`/auth/callback`、`/auth/check` 等端点，业务转发由 Acorn Nginx 的 `auth_request` 模式完成（见第 9 节）。

Axiom 上创建两个实例，使用 `UPSTREAM_URL` 反向代理模式。`/etc/auth-mini-gateway/status-axiom.env`：

```env
PORT=7779
UPSTREAM_URL=http://127.0.0.1:8080
GATEWAY_PUBLIC_BASE_URL=https://status-axiom.0xc1.wang
GATEWAY_DB=/var/lib/auth-mini-gateway/status-axiom.sqlite
```

`/etc/auth-mini-gateway/opencode-axiom.env`：

```env
PORT=7780
UPSTREAM_URL=http://127.0.0.1:4096
GATEWAY_PUBLIC_BASE_URL=https://opencode-axiom.0xc1.wang
GATEWAY_DB=/var/lib/auth-mini-gateway/opencode-axiom.sqlite
```

两端分别设置权限：

```bash
sudo chown root:auth-mini-gateway /etc/auth-mini-gateway/*.env
sudo chmod 0640 /etc/auth-mini-gateway/*.env
```

不能让多个实例共享一个 SQLite。gateway 使用 host-only cookie，并校验单一 `GATEWAY_PUBLIC_BASE_URL`，所以中央 `auth-gateway.0xc1.wang` 不能替其他 hostname 完成 callback。

### 7.4 systemd 模板服务

两端创建 `/etc/systemd/system/auth-mini-gateway@.service`。Acorn 的 unit 依赖本机 auth-mini；Axiom 的 unit 依赖被保护的应用：

Acorn：

```ini
[Unit]
Description=Auth Mini gateway for %i
After=network-online.target auth-mini.service
Wants=network-online.target auth-mini.service

[Service]
Type=simple
User=auth-mini-gateway
Group=auth-mini-gateway
WorkingDirectory=/var/lib/auth-mini-gateway
EnvironmentFile=/etc/auth-mini-gateway/base.env
EnvironmentFile=/etc/auth-mini-gateway/secret.env
EnvironmentFile=/etc/auth-mini-gateway/%i.env
ExecStart=/usr/local/bin/auth-mini-gateway
Restart=on-failure
RestartSec=5
StateDirectory=auth-mini-gateway
StateDirectoryMode=0750
NoNewPrivileges=true
PrivateTmp=true
ProtectHome=true
ProtectSystem=strict
ReadOnlyPaths=/etc/auth-mini-gateway
ReadWritePaths=/var/lib/auth-mini-gateway
UMask=0077

[Install]
WantedBy=multi-user.target
```

Axiom（`After`/`Wants` 指向本机应用 unit）：

```ini
[Unit]
Description=Auth Mini gateway for %i
After=network-online.target opencode-server.service
Wants=network-online.target opencode-server.service

[Service]
Type=simple
User=auth-mini-gateway
Group=auth-mini-gateway
WorkingDirectory=/var/lib/auth-mini-gateway
EnvironmentFile=/etc/auth-mini-gateway/base.env
EnvironmentFile=/etc/auth-mini-gateway/secret.env
EnvironmentFile=/etc/auth-mini-gateway/%i.env
ExecStart=/usr/local/bin/auth-mini-gateway
Restart=on-failure
RestartSec=5
StateDirectory=auth-mini-gateway
StateDirectoryMode=0750
NoNewPrivileges=true
PrivateTmp=true
ProtectHome=true
ProtectSystem=strict
ReadOnlyPaths=/etc/auth-mini-gateway
ReadWritePaths=/var/lib/auth-mini-gateway
UMask=0077

[Install]
WantedBy=multi-user.target
```

Acorn 启动两个实例：

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now auth-mini-gateway@auth-gateway.service
sudo systemctl enable --now auth-mini-gateway@frps-acorn.service
```

Axiom 启动两个实例：

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now auth-mini-gateway@status-axiom.service
sudo systemctl enable --now auth-mini-gateway@opencode-axiom.service
```

本机健康检查，Acorn：

```bash
curl -i http://127.0.0.1:7778/healthz
curl -i http://127.0.0.1:7781/healthz
```

Axiom：

```bash
curl -i http://127.0.0.1:7779/healthz
curl -i http://127.0.0.1:7780/healthz
```

预期返回 `204 No Content`。

## 8. DNS 和 TLS

### 8.1 DNS

主链路至少创建以下记录：

```text
auth.0xc1.wang             A  8.159.128.125  DNS-only
auth-gateway.0xc1.wang     A  8.159.128.125  DNS-only
status-axiom.0xc1.wang     A  8.159.128.125  DNS-only
opencode-axiom.0xc1.wang   A  8.159.128.125  DNS-only 或按需 proxied
frps-acorn.0xc1.wang       A  8.159.128.125  DNS-only
```

Cloudflare proxied 只保护经过 Cloudflare edge 的请求，不能替代 Acorn 源站上的 auth-mini-gateway。攻击者仍可能通过公网 IP + 正确 SNI/Host 访问源站，因此 Nginx 源站认证必须保留。

### 8.2 Cloudflare DNS-01 token

创建只允许指定 zone 执行 `Zone:DNS:Edit` 的 Cloudflare API token。不要使用 Tunnel credentials JSON，也不要使用 Global API Key。

创建 `/etc/letsencrypt/cloudflare.ini`：

```ini
dns_cloudflare_api_token = <Cloudflare DNS API token>
```

设置权限：

```bash
sudo chown root:root /etc/letsencrypt/cloudflare.ini
sudo chmod 0600 /etc/letsencrypt/cloudflare.ini
```

### 8.3 申请 SAN 证书

```bash
sudo certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
  --dns-cloudflare-propagation-seconds 30 \
  --cert-name acorn-ingress \
  -d auth.0xc1.wang \
  -d auth-gateway.0xc1.wang \
  -d status-axiom.0xc1.wang \
  -d opencode-axiom.0xc1.wang \
  -d frps-acorn.0xc1.wang
```

DNS-01 不依赖公网 `80`。安装 deploy hook，让续签成功后 reload Nginx：

```bash
sudo install -d -m 0755 /etc/letsencrypt/renewal-hooks/deploy
sudo tee /etc/letsencrypt/renewal-hooks/deploy/reload-nginx >/dev/null <<'EOF'
#!/bin/sh
set -eu
/usr/sbin/nginx -t
/bin/systemctl reload nginx.service
EOF
sudo chmod 0755 /etc/letsencrypt/renewal-hooks/deploy/reload-nginx
sudo certbot renew --dry-run
```

## 9. 配置 Nginx

### 9.1 TLS snippet

创建 `/etc/nginx/snippets/acorn-ingress-tls.conf`：

```nginx
ssl_certificate /etc/letsencrypt/live/acorn-ingress/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/acorn-ingress/privkey.pem;
ssl_protocols TLSv1.2 TLSv1.3;
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 1d;
ssl_session_tickets off;
```

### 9.2 完整站点配置

创建 `/etc/nginx/sites-available/nat-stack.conf`：

```nginx
map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}

upstream auth_mini_backend {
    server 127.0.0.1:7777;
}

upstream auth_gateway_backend {
    server 127.0.0.1:7778;
}

upstream frps_gateway_backend {
    server 127.0.0.1:7781;
}

upstream gatus_frp_backend {
    server 127.0.0.1:18080;
}

upstream opencode_frp_backend {
    server 127.0.0.1:18081;
}

upstream frps_dashboard_backend {
    server 127.0.0.1:7500;
}

server {
    listen 443 ssl http2;
    server_name auth.0xc1.wang;
    include /etc/nginx/snippets/acorn-ingress-tls.conf;

    location = /admin/setup {
        allow 127.0.0.1;
        allow ::1;
        deny all;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_pass http://auth_mini_backend;
    }

    location = / {
        return 302 /web/;
    }

    location / {
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_pass http://auth_mini_backend;
    }
}

server {
    listen 443 ssl http2;
    server_name auth-gateway.0xc1.wang;
    include /etc/nginx/snippets/acorn-ingress-tls.conf;

    location ~ ^/(?:healthz|login|logout|auth/callback(?:/session)?)$ {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_pass http://auth_gateway_backend;
    }

    location / {
        return 404 "Not found\n";
    }
}

server {
    listen 443 ssl http2;
    server_name status-axiom.0xc1.wang;
    include /etc/nginx/snippets/acorn-ingress-tls.conf;

    underscores_in_headers on;
    client_max_body_size 0;

    location / {
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header Cookie $http_cookie;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_request_buffering off;
        proxy_buffering off;
        proxy_cache off;
        proxy_connect_timeout 10s;
        proxy_send_timeout 24h;
        proxy_read_timeout 24h;
        proxy_intercept_errors off;
        proxy_next_upstream off;
        proxy_redirect off;
        proxy_pass http://gatus_frp_backend;
    }
}

server {
    listen 443 ssl http2;
    server_name opencode-axiom.0xc1.wang;
    include /etc/nginx/snippets/acorn-ingress-tls.conf;

    underscores_in_headers on;
    client_max_body_size 0;

    location / {
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header Cookie $http_cookie;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_request_buffering off;
        proxy_buffering off;
        proxy_cache off;
        gzip off;
        proxy_connect_timeout 10s;
        proxy_send_timeout 24h;
        proxy_read_timeout 24h;
        proxy_intercept_errors off;
        proxy_next_upstream off;
        proxy_redirect off;
        proxy_pass http://opencode_frp_backend;
    }
}

server {
    listen 443 ssl http2;
    server_name frps-acorn.0xc1.wang;
    include /etc/nginx/snippets/acorn-ingress-tls.conf;

    location ~ ^/(?:healthz|login|logout|auth/callback(?:/session)?)$ {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_pass http://frps_gateway_backend;
    }

    location = /_auth {
        internal;
        proxy_pass http://frps_gateway_backend/auth/check;
        proxy_pass_request_body off;
        proxy_set_header Content-Length "";
        proxy_set_header X-Original-URI $request_uri;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header Cookie $http_cookie;
    }

    location = /__auth_mini_login_redirect {
        internal;
        proxy_pass http://frps_gateway_backend/login;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Original-URI $request_uri;
    }

    location @auth_mini_forbidden {
        return 403 "Forbidden\n";
    }

    location / {
        auth_request /_auth;
        auth_request_set $auth_user_id $upstream_http_x_auth_mini_user_id;
        auth_request_set $auth_email $upstream_http_x_auth_mini_email;
        error_page 401 = /__auth_mini_login_redirect;
        error_page 403 = @auth_mini_forbidden;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Cookie "";
        proxy_set_header X-Auth-Mini-User-Id $auth_user_id;
        proxy_set_header X-Auth-Mini-Email $auth_email;
        proxy_pass http://frps_dashboard_backend;
    }
}
```

启用配置：

```bash
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/nat-stack.conf /etc/nginx/sites-enabled/nat-stack.conf
sudo nginx -t
sudo systemctl enable --now nginx.service
sudo systemctl reload nginx.service
```

若 gateway 访问 `https://auth.0xc1.wang` 时无法通过公网地址回到本机，可在 Acorn `/etc/hosts` 增加：

```text
127.0.0.1 auth.0xc1.wang
```

这样仍经过本机 Nginx 和有效 TLS 证书，但不依赖云网络 hairpin。

从外部验证 setup API 被 Nginx 拒绝：

```bash
curl -i --resolve auth.0xc1.wang:443:8.159.128.125 \
  -X PUT https://auth.0xc1.wang/admin/setup \
  -H 'content-type: application/json' \
  -d '{}'
```

预期为 Nginx `403`，请求不能到达 auth-mini。

### 9.3 认证流程

status/opencode 域名使用节点模式，Acorn Nginx 不参与认证：

1. 请求经 Acorn Nginx 透明转发，通过 FRP 到达 Axiom gateway。
2. 未认证请求被 gateway `302` 到 `https://auth.0xc1.wang/web/#/login`。
3. auth-mini 完成 Email OTP 或 Passkey。
4. 浏览器回到原受保护 hostname 的 `/auth/callback` 和 `/auth/callback/session`（同样经 Acorn Nginx 和 FRP 到达 Axiom gateway）。
5. gateway 验证 token，按 `ALLOW_EMAILS` 或 `ALLOW_USER_IDS` 授权，然后把请求反代到本机应用。
6. 不在 allowlist 的已认证用户得到 gateway 返回的 `403`。

frps dashboard 使用 Acorn 本机 `auth_request` 模式：

1. 未认证请求进入受保护 vhost。
2. Nginx 内部请求 `/_auth`，转到该 hostname 对应 gateway 的 `/auth/check`。
3. gateway 返回 `401` 时，Nginx 内部转到同一 gateway 的 `/login`。
4. 浏览器被送到 `https://auth.0xc1.wang/web/#/login` 完成认证并回到 `/auth/callback`。
5. gateway 验证 token 并按 allowlist 授权。
6. Nginx 清除浏览器 Cookie 后再把请求交给业务上游，并注入已验证的身份头。

`403` 表示身份已认证但不在 allowlist，不应再次跳登录页。

## 10. 防火墙和云安全组

### 10.1 Acorn UFW

以下示例把 SSH 和 FRP SSH 限制到运维来源，把 FRP 控制端口优先限制到 Axiom 出口 IP：

```bash
(
  set -euo pipefail
  : "${OPERATOR_CIDR:?先 export OPERATOR_CIDR}"
  : "${AXIOM_EGRESS_CIDR:?先 export AXIOM_EGRESS_CIDR}"

  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw allow in on lo
  sudo ufw allow proto tcp from "${OPERATOR_CIDR}" to any port 22
  sudo ufw allow 443/tcp
  sudo ufw allow proto tcp from "${AXIOM_EGRESS_CIDR}" to any port 7000
  sudo ufw allow proto tcp from "${OPERATOR_CIDR}" to any port 2225
  sudo ufw status numbered
  sudo ufw enable
)
sudo ufw status numbered
```

若 Axiom 出口 IP 不固定，只能放宽 `7000` 来源时，必须保持强随机 FRP token，并持续更新 FRP。不要因此开放 remotePort。

Acorn 不应公网开放：

```text
80
7500
7777-7781
18080
18081
```

当前环境的 `2222`、`2223`、`2224` 已被其他 autossh 反向通道预留；不要把新的 FRP proxy 放到这些端口。

### 10.2 阿里云或其他云安全组

云安全组应与 UFW 同时收紧。只配置 UFW 而把安全组全部放开，或只配置安全组而让主机全部放开，都不算完整边界。

推荐公网入站：

| 端口 | 来源 | 用途 |
| --- | --- | --- |
| `22/tcp` | 运维 CIDR | Acorn SSH |
| `443/tcp` | Internet | HTTPS 入口 |
| `7000/tcp` | Axiom 出口 IP，无法固定时再放宽 | frpc -> frps |
| `2225/tcp` | 运维 CIDR | 经 FRP 访问 Axiom SSH |

### 10.3 Axiom UFW

OpenCode、Gatus、frpc 和 cloudflared 都不需要新增公网入站规则：

```bash
(
  set -euo pipefail
  : "${HOME_LAN_CIDR:?先 export HOME_LAN_CIDR}"

  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw allow in on lo
  sudo ufw allow proto tcp from "${HOME_LAN_CIDR}" to any port 22
  sudo ufw status numbered
  sudo ufw enable
)
sudo ufw status numbered
```

不要开放 `4096` 或 `8080`。

## 11. 可选兜底：cloudflared + Cloudflare Access

### 11.1 先创建 Access 应用

必须先创建 Access policy，再创建可公网解析的 tunnel hostname，避免短暂裸奔。

Cloudflare Zero Trust 控制台中执行：

1. 打开 **Access controls -> Applications**。
2. 创建 **Self-hosted and private** 应用。
3. 添加 public hostname，例如 `opencode-axiom.0xc1.space`。
4. 添加 Allow policy，只允许精确邮箱或受控组。
5. 只启用批准的 IdP；当前使用 Google。
6. 单 IdP 时启用 instant authentication。
7. 按需启用 MFA，并设置合理 session duration。
8. 用允许和不允许的两个身份分别验证。

Access 默认 deny，但必须存在匹配的 Allow policy 才能进入应用。不要使用 `Everyone`、宽泛域名 allow 或 bypass rule。

Cloudflare 官方还建议在 origin 或 cloudflared 上验证 Access application token。可在 Tunnel route 中启用 **Protect with Access**，或由应用验证 `Cf-Access-Jwt-Assertion`，防止 Access 控制面误配置产生旁路。

### 11.2 Ubuntu 安装 cloudflared

在 Axiom 执行：

```bash
sudo mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main" | sudo tee /etc/apt/sources.list.d/cloudflared.list
sudo apt-get update
sudo apt-get install -y cloudflared
cloudflared --version
```

### 11.3 创建 locally-managed tunnel

建议在受控运维工作站创建 tunnel：

```bash
cloudflared tunnel login
cloudflared tunnel create home-axiom
cloudflared tunnel list
```

记录 tunnel UUID，并把生成的 `<UUID>.json` 安全传输到 Axiom。`cert.pem` 是控制面账户证书，权限高于单 tunnel runtime JSON；不要长期留在 Axiom。

在 Axiom 创建服务用户和目录：

```bash
(
  set -euo pipefail
  : "${TUNNEL_UUID:?先 export TUNNEL_UUID}"
  : "${TUNNEL_CREDENTIALS_FILE:?先 export TUNNEL_CREDENTIALS_FILE}"
  test -f "${TUNNEL_CREDENTIALS_FILE}"

  sudo useradd --system --user-group --home-dir /var/lib/cloudflared --create-home --shell /usr/sbin/nologin cloudflared
  sudo install -d -o root -g cloudflared -m 0750 /etc/cloudflared
  sudo install -o root -g cloudflared -m 0640 \
    "${TUNNEL_CREDENTIALS_FILE}" \
    "/etc/cloudflared/${TUNNEL_UUID}.json"
)
```

### 11.4 Tunnel 配置

创建 `/etc/cloudflared/config.yml`：

把下面两处 `<UUID>` 替换为实际 UUID。cloudflared YAML 不会自动展开 shell 变量。

```yaml
tunnel: <UUID>
credentials-file: /etc/cloudflared/<UUID>.json
protocol: http2
metrics: 127.0.0.1:20241

ingress:
  - hostname: opencode-axiom.0xc1.space
    service: http://127.0.0.1:4096
  - hostname: status-axiom.0xc1.space
    service: http://127.0.0.1:8080
  - service: http_status:404
```

最后一条 catch-all `http_status:404` 不能省略。

当前 Axiom 固定 `protocol: http2`，因为 Clash/Mihomo 路由下默认 QUIC/UDP 曾出现 edge dial timeout。网络环境确认 QUIC 正常后再评估移除。

设置权限并检查 ingress：

```bash
sudo chown root:cloudflared /etc/cloudflared/config.yml
sudo chmod 0640 /etc/cloudflared/config.yml
sudo -u cloudflared cloudflared tunnel --config /etc/cloudflared/config.yml ingress validate
```

### 11.5 cloudflared systemd

创建 `/etc/systemd/system/cloudflared.service`：

```ini
[Unit]
Description=Cloudflare Tunnel connector
After=network-online.target opencode-server.service
Wants=network-online.target opencode-server.service

[Service]
Type=simple
User=cloudflared
Group=cloudflared
ExecStart=/usr/bin/cloudflared --config /etc/cloudflared/config.yml tunnel run
Restart=always
RestartSec=5
LimitNOFILE=100000
NoNewPrivileges=true
PrivateTmp=true
ProtectHome=true
ProtectSystem=strict
ProtectControlGroups=true
ProtectKernelModules=true
ProtectKernelTunables=true
ReadOnlyPaths=/etc/cloudflared

[Install]
WantedBy=multi-user.target
```

启动：

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now cloudflared.service
sudo systemctl status cloudflared.service
curl -fsS http://127.0.0.1:20241/ready
```

### 11.6 创建 tunnel DNS route

确认 Access 应用已存在后，在持有 `cert.pem` 的运维工作站执行：

```bash
cloudflared tunnel route dns home-axiom opencode-axiom.0xc1.space
cloudflared tunnel route dns home-axiom status-axiom.0xc1.space
```

这会创建指向 `<UUID>.cfargotunnel.com` 的 proxied CNAME。DNS route 成功只表示 hostname 指向 tunnel，不表示 Access policy 已正确限制用户。

## 12. 端到端验证

按层验证，不要直接从浏览器成功与否猜原因。

### 12.1 Axiom 本地应用

```bash
systemctl is-active opencode-server.service
curl -fsS http://127.0.0.1:4096/global/health
ss -ltnp | grep -E ':(4096|8080)\b'
```

`4096`、`8080` 应只绑定 `127.0.0.1`。

### 12.2 FRP

```bash
systemctl is-active frpc.service
journalctl -u frpc.service -n 100 --no-pager
```

在 Acorn：

```bash
systemctl is-active frps.service
curl -i http://127.0.0.1:18081/
curl -I http://127.0.0.1:7500/
```

`18081` 应返回 Axiom gateway 的 `302` 登录重定向，而不是 OpenCode 自身响应。

### 12.3 Auth 和 gateway

Acorn：

```bash
curl -I http://127.0.0.1:7777/web/
curl -i http://127.0.0.1:7778/healthz
curl -i http://127.0.0.1:7781/healthz
```

Axiom：

```bash
curl -i http://127.0.0.1:7779/healthz
curl -i http://127.0.0.1:7780/healthz
```

### 12.4 Nginx 直连源站

绕过公共 DNS，直接验证 Acorn IP、TLS SNI 和 Nginx：

```bash
curl -I --resolve auth.0xc1.wang:443:8.159.128.125 https://auth.0xc1.wang/
curl -I --resolve opencode-axiom.0xc1.wang:443:8.159.128.125 https://opencode-axiom.0xc1.wang/
curl -I --resolve frps-acorn.0xc1.wang:443:8.159.128.125 https://frps-acorn.0xc1.wang/
```

预期：

- auth 根路径 `302` 到 `/web/`。
- 未认证的受保护入口进入登录流程。
- 不在 allowlist 的已认证用户得到 `403`。
- 未认证请求不能到达业务 upstream。

### 12.5 浏览器认证

至少完成：

1. Email OTP 登录成功。
2. Passkey 注册和登录成功。
3. 允许身份可以访问 OpenCode、Gatus 和 frps dashboard。
4. 未允许身份稳定返回 `403`。
5. `/logout` 后旧 gateway session 不再可用。
6. 重启 gateway 后有效 session 仍可用。
7. OpenCode 的长连接、SSE/WebSocket 和实际交互正常。

### 12.6 公网暴露检查

从 Acorn 外部机器检查；该机器需先安装 `nmap`：

```bash
nmap -Pn -p 80,443,7000,2225,7500,7777-7781,18080-18081 8.159.128.125
```

预期 `7500`、`7777-7781`、`18080-18081` 不可从公网访问。`80` 应关闭。`7000` 和 `2225` 是否可见取决于来源 CIDR 规则。

### 12.7 Cloudflare 备用入口

在 Axiom 检查 connector：

```bash
systemctl is-active cloudflared.service
curl -fsS http://127.0.0.1:20241/ready
```

在持有 Cloudflare `cert.pem` 的运维工作站检查控制面：

```bash
cloudflared tunnel info home-axiom
```

浏览器分别验证允许账号、未允许账号和无登录状态。再停用 FRP 入口的客户端侧访问，确认备用 hostname 仍能独立工作；不要停生产服务来模拟故障。

### 12.8 重启验证

两台机器分别重启后重复：

```bash
systemctl --failed
systemctl is-active frps.service
systemctl is-active frpc.service
systemctl is-active nginx.service
systemctl is-active auth-mini.service
systemctl is-active opencode-server.service
systemctl is-active cloudflared.service
```

只在对应主机检查实际存在的 unit。

## 13. 备份、恢复和升级

### 13.1 必须备份

Acorn：

```text
/var/lib/auth-mini/auth-mini.sqlite
/var/lib/auth-mini-gateway/*.sqlite*
/etc/auth-mini-gateway/secret.env
/etc/frp/frp-token
/etc/frp/tls/frps-acorn.crt
/etc/frp/tls/frps-acorn.key
/etc/letsencrypt/
```

Axiom：

```text
/etc/frp/frp-token
/etc/frp/tls/ca.crt
/var/lib/auth-mini-gateway/*.sqlite*
/etc/auth-mini-gateway/secret.env
/etc/cloudflared/<UUID>.json
OpenCode 服务用户的配置和 provider credential
实际工作目录和项目数据
```

gateway 使用 SQLite WAL。最简单可靠的离线备份方式是先停止对应主机上的 gateway 实例，再复制整个 `/var/lib/auth-mini-gateway`。gateway 数据库包含 refresh token，备份必须视为 secret。

备份 auth-mini 前停止 `auth-mini.service`，或使用 SQLite online backup。恢复后校验 issuer、RP ID、JWKS、管理员凭证和 SMTP；仅恢复二进制不会恢复这些状态。

### 13.2 Secret 轮换影响

| Secret | 轮换影响 |
| --- | --- |
| FRP token | 两端必须协调更新并重启，期间 tunnel 中断 |
| FRP TLS certificate/CA | 先让 frpc 信任新 CA，再切换 frps 证书；监控证书到期时间 |
| gateway cookie secret | 所有 gateway 浏览器 cookie 失效 |
| gateway allowlist | 新请求按新策略授权，现有 session 也应复查 |
| SMTP API key | 必须重新写入 auth-mini 配置并发送测试 OTP |
| Tunnel JSON | 只影响对应 tunnel connector |
| Cloudflare DNS token | 影响后续证书续签，不影响已签发证书立即使用 |

### 13.3 升级顺序

1. 备份 SQLite 和 secret。
2. 阅读上游 release notes。
3. 在测试端口验证新二进制和配置。
4. 先升级 frps，再升级 frpc，或按上游兼容说明执行。
5. gateway 保持一个实例对应一个 DB，不做 multi-active 共享 SQLite 滚动升级。
6. 升级 OpenCode 后验证 `/global/health`、模型凭证、项目访问和长连接。
7. 升级 cloudflared 后验证 `/ready` 和两个备用 hostname。
8. 保留上一版二进制和数据库备份，直到端到端检查完成。

## 14. 常见故障

| 现象 | 优先检查 |
| --- | --- |
| frpc 连不上 | 两端 token 是否一致、Acorn `7000`、云安全组、UFW、时间、Clash/Mihomo TUN 路由 |
| Nginx `502` | Axiom 应用、本机 FRP remotePort、frpc proxy 注册、Nginx upstream 端口 |
| 浏览器空响应 | 公共 DNS 是否存在、是否解析到代理 fake IP、SNI/证书、Nginx 日志 |
| 登录循环 | `GATEWAY_PUBLIC_BASE_URL`、issuer、RP ID、callback hostname、Secure/SameSite cookie、系统时间 |
| 登录后 `403` | `ALLOW_EMAILS` 大小写/空格、`ALLOW_USER_IDS`、gateway 日志；不要先改 callback |
| Passkey 失败 | HTTPS origin、issuer 和 RP ID 是否精确匹配 `auth.0xc1.wang` |
| OTP 不发送 | auth-mini SQLite 中 SMTP 配置、Resend sender 验证、API key、465 implicit TLS |
| gateway 重启后掉登录 | SQLite 路径是否持久、cookie secret 是否变化、DB/WAL 权限 |
| OpenCode 页面能开但交互失败 | Nginx Upgrade/Connection、SSE/WebSocket timeout、OpenCode 服务日志 |
| cloudflared QUIC timeout | 保留 `protocol: http2`，检查出站 `7844` 和 Clash/Mihomo |
| Cloudflare hostname 未认证 | Access app 是否先创建、policy 是否匹配、是否误用 bypass/Everyone |
| Certbot 续签失败 | DNS token 权限、token 文件 mode、zone 选择、DNS propagation 时间 |
| frps dashboard 公网端口访问失败 | `7500` 本来就只允许 loopback，应通过 `frps-acorn.0xc1.wang` 访问 |

查看日志：

```bash
sudo journalctl -u frps.service -f
sudo journalctl -u frpc.service -f
sudo journalctl -u auth-mini.service -f
sudo journalctl -u 'auth-mini-gateway@*.service' -f
sudo journalctl -u nginx.service -f
sudo journalctl -u opencode-server.service -f
sudo journalctl -u cloudflared.service -f
```

auth-mini 日志可能包含邮箱和客户端 IP。不要把完整生产日志直接粘贴到公开 issue。

## 15. 上线检查表

- [ ] OpenCode/Gatus 只监听 loopback。
- [ ] frpc 和 frps 使用相同的高熵 token。
- [ ] frps 强制 TLS，frpc 使用私有 CA 和 `serverName` 校验服务端身份。
- [ ] frps `allowPorts` 只包含批准端口。
- [ ] frps dashboard 只监听 `127.0.0.1:7500`。
- [ ] frpc 的 HTTP proxy `localPort` 指向 Axiom gateway 端口，不指向应用端口。
- [ ] `18080`、`18081` 未被 UFW 和云安全组放行。
- [ ] auth-mini issuer、RP ID 和公网域名一致。
- [ ] 每个受保护域名有独立 gateway 实例和 SQLite。
- [ ] gateway env 不包含 `REQUIRE_PASSKEY`。
- [ ] Acorn `auth_request` 模式的 vhost 清除业务上游的浏览器 Cookie，并只注入 gateway 返回的身份头。
- [ ] Email OTP、Passkey、拒绝身份、logout 都已验证。
- [ ] OpenCode 长连接和实际操作已验证。
- [ ] Certbot `renew --dry-run` 成功。
- [ ] Cloudflare Access 在 tunnel DNS route 之前创建。
- [ ] Cloudflare 备用入口用允许和拒绝身份都验证过。
- [ ] SQLite、cookie secret、FRP token、Tunnel JSON 已纳入加密备份。
- [ ] 两台主机重启后服务自动恢复。

## 16. 参考资料

- [FRP](https://github.com/fatedier/frp)
- [auth-mini](https://github.com/zccz14/auth-mini)
- [auth-mini-gateway](https://github.com/Thrimbda/auth-mini-gateway)
- [OpenCode server](https://opencode.ai/docs/server/)
- [Cloudflare locally-managed tunnel](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/local-management/create-local-tunnel/)
- [Cloudflare Access self-hosted application](https://developers.cloudflare.com/cloudflare-one/access-controls/applications/http-apps/self-hosted-public-app/)

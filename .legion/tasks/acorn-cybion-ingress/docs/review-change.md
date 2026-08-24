# Review: acorn-cybion-ingress

结论：**PASS**（安全视角已展开，无 blocking finding）

## 审查对象

- `hosts/acorn/modules/platform.nix`：删除 `programs.nix-ld.enable = lib.mkForce false;`
- `hosts/acorn/modules/cybion.nix`：新增 vhost 模块
- `hosts/acorn/default.nix`：imports 增加 `./modules/cybion.nix`
- 验证证据：`docs/test-report.md`（Axiom 构建通过、nginx.conf 内容检查、acme 单元存在、既有 8 个 vhost 未扰动）

## Scope 检查

改动严格落在 contract scope 内（3 个仓库文件），无顺手扩边。任务文档（plan/rfc/test-report）在 PR 中一并提交。

## 正确性 / 可维护性

- vhost 配置完整复制了 auth-mini.nix 中 `mkNodeProxyVhost` 的成熟形态（该形态承载 status/opencode/pi 三个长连接服务），未发明新配置语言。
- `cloudflareDnsAcme.hosts` 是 listOf，与 auth-mini.nix、vaultwarden.nix 的注册自动合并，互不覆盖。
- 移除了 `proxy_set_header Upgrade/Connection`：cybion 服务端只有 SSE，无 WebSocket（tungstenite 仅为访问本机 Chrome CDP 的客户端侧），避免对 `$connection_upgrade` map 的隐式跨模块依赖。

## 安全视角（命中触发条件：公网暴露新入口 / 信任边界）

- 暴露面：公网 443 本就开放；1858 不出防火墙，仅 nginx 路径可达。cybion 公开路由只有 `/health` 与嵌入静态资源；`/api/*` 由 Auth Mini JWT + root_user_id 校验，executor 接口由一次性配对 token + Bearer access token 保护。不套 auth-mini-gateway 是 contract 决策（gateway 的 cookie/browser 流程与机器间 token 接口不兼容）。
- `Host` 头硬编码为 `cybion.0xc1.wang`：Auth Mini audience 绑定不受 Host 头欺骗影响。
- `X-Forwarded-Proto https` 硬编码：vhost onlySSL，控制端生成的配对 URL 恒为 https。
- `client_max_body_size 0`：放开 nginx 请求体上限。相关端点（文件对象、语音、executor 结果）全部要求 JWT/设备 token，未认证请求到不了大 body 路径；root user 即 owner，可接受。与 mkNodeProxyVhost 先例一致。
- nix-ld 开启：允许 acorn 上运行任意动态链接二进制，与 axiom 同 posture，用户显式要求；不改变任何现有服务的权限边界。

## 非阻塞建议

- acorn 上 cybion 进程当前为手动管理；若以后进程崩溃无人发现，可考虑加一个最小 systemd unit 或监控（本任务 contract 明确排除）。
- 仓库根目录存在未跟踪的 `acorn_password`、`acorn_id_ed25519` 明文/私钥文件，与本任务无关，建议另行处理。

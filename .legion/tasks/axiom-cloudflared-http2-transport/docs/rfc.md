# Design-lite: Axiom Cloudflared HTTP2 Transport Fix

## 背景

现有 axiom cloudflared 模块通过 `environment.etc."cloudflared/config.yml".text = configText` 生成 `/etc/cloudflared/config.yml`，systemd service 使用 `cloudflared --config /etc/cloudflared/config.yml tunnel run` 启动。现场配置中的 tunnel、credentials-file 和 ingress 均正确，opencode 本地服务也正常。

断链根因是 cloudflared 默认 QUIC transport 无法穿过当前 Clash/Meta fake-ip 网络：Cloudflare edge hostname 被解析到 `198.18.0.x`，日志重复出现 QUIC timeout。手动运行 `cloudflared tunnel --protocol http2 --config /etc/cloudflared/config.yml run` 已成功注册 connector。

## 选项

1. **在 axiom cloudflared extraConfig 中设置 `protocol = "http2"`**
   - 优点: 改动最小，只影响该 host 的 tunnel transport；无需改变全局代理/DNS；可直接通过 Nix 生成配置验证。
   - 风险: 需要部署后重启系统服务才永久生效；HTTP/2 相比 QUIC 性能特性不同。
2. **调整 Clash/Meta fake-ip 或 UDP 代理规则**
   - 优点: 保留 cloudflared 默认 QUIC。
   - 风险: 影响全局网络行为，验证面更大，可能引入其他服务回归。
3. **只保留临时用户态 HTTP/2 connector**
   - 优点: 立即可用。
   - 风险: 不 declarative、不可重启恢复、会和系统服务形成双 connector 状态。

## 决策

采用选项 1：在 `hosts/axiom/default.nix` 的 `modules.services.cloudflared.extraConfig` 顶层添加 `protocol = "http2"`。

该方案保持现有 tunnel id、credentials、hostname、ingress service、opencode service 和 Cloudflare Access policy 不变，只改变 cloudflared 到 edge 的 transport。它是最小、可回滚的 declarative 修复。

## 验证

- Targeted eval: 读取 `nixosConfigurations.axiom.config.environment.etc."cloudflared/config.yml".text`，确认 JSON 含 `"protocol":"http2"`。
- Targeted eval: 读取 `nixosConfigurations.axiom.config.systemd.services.cloudflared.serviceConfig.ExecStart`，确认仍通过 `/etc/cloudflared/config.yml` 启动。
- Optional build: 若耗时和依赖允许，运行 axiom toplevel build 或等价 dry eval。
- Runtime: 部署后重启 `cloudflared.service`，公网 hostname 应继续返回 Cloudflare Access 登录跳转；由于当前无 passwordless sudo，该项可能作为人工验证记录。

## 回滚

回滚只需 revert 本次 `hosts/axiom/default.nix` 的 `protocol = "http2"` 配置并重新部署。回滚不会触碰 secrets、DNS route、Access policy 或 opencode service。

## 自检

- Scope 限定到 axiom host-level cloudflared transport 配置。
- 不新增 secret、不读取 credential、不改认证/授权策略。
- 不改变公网 hostname 或 origin service。
- 无数据迁移，无持久状态变更。

# RFC: 在 charlie 上通过 Cloudflare Access 暴露 opencode server

## 1. 背景 / 问题

当前目标是在 `charlie`（`aarch64-darwin`）上提供一个可远程访问的 opencode server，用于受控访问本机 opencode 能力，同时满足以下约束：

- 服务仅监听本机回环地址，避免直接暴露在局域网或公网。
- 对外暴露统一走 Cloudflare Tunnel / Access，按邮箱策略控制访问。
- 服务需随机器重启自动恢复。
- 现有仓库中已经具备部分前置条件，但状态不一致：
  - `hosts/charlie/default.nix` 已配置 `OPENCODE_*` 环境变量，并安装 `cloudflared`。
  - `darwin/default.nix` 尚未导入 `modules/services/cloudflared.nix`。
  - `hosts/charlie/default.nix` 中已有一段被注释的 `modules.services.cloudflared` 示例配置。
  - `modules/services/cloudflared.nix` 实际使用 `extraConfig`，但注释/示例中部分地方仍写成 `config`，会误导使用者。
  - `charlie` 已存在 cloudflared credentials 的 age 文件，可作为 tunnel 凭据来源。

当前问题不是“能否手工跑起来”，而是“如何把它沉淀为一套可声明、可重建、可回滚的 Darwin 服务方案”。

## 2. 目标与非目标

### 目标

- 在 `charlie` 上以 launchd user agent 方式托管 `opencode serve`。
- 服务监听 `127.0.0.1:4096`，默认不暴露到非本机接口。
- 通过 `cloudflared tunnel run` 将指定 hostname 反向代理到本机 opencode server。
- 将 Access 按邮箱授权视为必需的外部运维步骤，并在文档中固化为上线门禁。
- 保证重启后 `opencode-server` 与 `cloudflared` 都能自动启动。
- 修正文档/注释中的 `config` vs `extraConfig` 偏差，降低后续误配风险。

### 非目标

- 不在本 RFC 内设计多用户、多实例或高可用部署。
- 不将 Cloudflare Access 做成 Terraform/IaC 自动化。
- 不覆盖 atlas 或其他主机的联动改造。
- 不在首版引入复杂的 launchd 依赖编排。

## 3. 风险分级

**分级：High**

理由：

1. 该变更会把本机 opencode 能力经 Cloudflare hostname 暴露给外部用户，安全边界发生变化。
2. 涉及 launchd、cloudflared、凭证文件、Cloudflare Access 四层组合，任何一层失配都可能导致不可用或误暴露。
3. 当前仓库存在 `config`/`extraConfig` 文档漂移，容易造成“看似配置正确但未生效”的部署风险。
4. 该服务面向远程访问，必须提供明确的验证、上线门禁与回滚流程，因此按 High 处理。

## 4. 设计概览

设计采用“本地 loopback 服务 + Cloudflare 转发 + Access 鉴权”的最小闭环：

- 本地服务 A：`opencode-server`
  - 通过 launchd user agent 运行。
  - 执行 `/Users/c1/.opencode/bin/opencode serve --hostname 127.0.0.1 --port 4096`。
  - 只绑定 localhost。
- 本地服务 B：`cloudflared`
  - 复用现有 `modules/services/cloudflared.nix` 的 Darwin launchd user agent 能力。
  - 通过 ingress 将单一 hostname 转发到 `http://127.0.0.1:4096`。
- 外部控制面：Cloudflare Access
  - 对该 hostname 配置 allow policy，按邮箱白名单控制访问。
  - Access 是鉴权层；ingress 只负责转发，不替代 Access。

## 5. 详细设计

### 5.1 opencode-server 启动方式

在 `hosts/charlie/default.nix` 新增 `launchd.user.agents.opencode-server`：

- `ProgramArguments` 使用绝对路径，避免依赖 launchd 的 PATH 行为：
  - `/Users/c1/.opencode/bin/opencode`
  - `serve`
  - `--hostname`
  - `127.0.0.1`
  - `--port`
  - `4096`
- `RunAtLoad = true`
- `KeepAlive = true`
- `EnvironmentVariables` 至少包含：
  - `HOME = /Users/c1`
  - `OPENCODE_ENABLE_EXA = 1`
  - `OPENCODE_EXPERIMENTAL = true`
- 为排障提供固定日志路径。

### 5.2 自动启动与失败行为

- `opencode-server` 与 `cloudflared` 都配置为 `RunAtLoad + KeepAlive`。
- 不增加显式 launchd 依赖；允许启动瞬间出现短暂后端不可达，验收以最终自恢复为准。
- 若 `opencode` 二进制缺失或端口被占用，`opencode-server` 应失败并在日志中可见。

### 5.3 端口与监听约束

- opencode server 固定监听 `127.0.0.1:4096`。
- 禁止监听 `0.0.0.0`。
- Cloudflare tunnel 也只回源到 `127.0.0.1:4096`，形成单一入口。

### 5.4 cloudflared ingress / hostname

在 `charlie` 上启用：

- `modules.services.cloudflared.enable = true`
- `tunnelId = <existing tunnel id>`
- `credentialsFile = ./secrets/cloudflared-credentials.age`
- `warpRouting.enabled = false`
- `extraConfig.ingress = [ { hostname = "opencode-charlie.0xc1.space"; service = "http://127.0.0.1:4096"; } { service = "http_status:404"; } ]`

说明：

- 首版采用单一 hostname，避免扩大暴露面。
- `warpRouting` 对本任务不是必需，默认关闭，避免引入额外网络语义。
- `http_status:404` 作为兜底规则，避免未匹配请求落到非预期目标。

### 5.5 Cloudflare Access 上线门禁

Cloudflare Access 不在仓库内自动化，但属于发布前置条件，必须遵循如下顺序：

1. 本机 `opencode-server` 可用。
2. cloudflared tunnel / ingress 可用。
3. 在 Cloudflare 中为 `opencode-charlie.0xc1.space` 创建 Access 应用。
4. 配置 allow policy，仅允许指定邮箱访问（默认示例：`siyuan.arc@gmail.com`）。
5. 验证已授权邮箱可访问、未授权邮箱被拒绝后，才视为“上线完成”。

换言之：**ingress 负责转发，Access 负责鉴权，两者缺一不可。**

### 5.6 文档 / 脚本修正

同步修正以下偏差：

- `modules/services/cloudflared.nix` 注释示例中的 `config = { ... }` 统一改为 `extraConfig = { ... }`。
- `docs/cloudflare-zero-trust.md` 与 `docs/charlie-macos-ssh-config.md` 的模块示例统一改为 `extraConfig`。
- `bin/cloudflared-setup` 生成的 Nix snippet 统一改为 `extraConfig`，避免新配置继续抄错。

## 6. Scope

### In Scope

- `charlie` 上 opencode server 的 Darwin 自启动。
- `darwin/default.nix` 导入 `modules/services/cloudflared.nix`。
- `hosts/charlie/default.nix` 启用并配置 cloudflared tunnel。
- 当前任务所触及文档 / 示例 / setup 脚本的一致性修正。
- 验证、回滚与 PR 交付文档。

### Out of Scope

- Access 策略的 API / Terraform 自动化。
- opencode server 的二次应用层鉴权增强。
- Atlas 或其他主机的同步改造。
- 多实例、多环境、多租户化方案。

## 7. 验证计划

1. **静态验证**
   - 相关 Nix 配置可成功评估。
   - `config` / `extraConfig` 漂移在本次修改范围内被消除。

2. **本地服务验证**
   - `launchctl` 中存在 `opencode-server` 与 `cloudflared`。
   - 本机访问 `127.0.0.1:4096` 能拿到 opencode server 响应。

3. **隧道验证**
   - `cloudflared` 日志可见 tunnel 建立。
   - Access 应用创建后，通过 hostname 可达 opencode 服务。

4. **访问控制验证**
   - 指定邮箱可访问。
   - 非授权邮箱被 Access 拒绝。

5. **重启恢复验证**
   - 主机重启后无需人工干预即可恢复 `opencode-server` 与 `cloudflared`。

6. **失败路径验证**
   - 4096 端口被占用时，`opencode-server` 启动失败且日志可见。
   - credentials 无效时，`cloudflared` 启动失败，且由于服务只监听 localhost，不会直接形成公网旁路暴露。

## 8. 回滚方案

最小回滚按以下顺序执行：

1. 在 Cloudflare 侧禁用或移除 `opencode-charlie.0xc1.space` 对应 Access 应用 / 公网入口。
2. 在仓库内禁用 `modules.services.cloudflared` 与 `launchd.user.agents.opencode-server`，然后执行 `darwin-rebuild switch --flake .#charlie`。
3. 验证：公网 hostname 不可访问；`launchctl` 中无对应 agent；若目标是完全下线，则 `127.0.0.1:4096` 也不再监听。

## 9. 风险与缓解

- **风险：launchd 环境与交互 shell 不一致导致服务不起**
  - 缓解：使用绝对路径 `/Users/c1/.opencode/bin/opencode`，并显式设置 `HOME` 与必要环境变量。

- **风险：Cloudflare tunnel 已通但 Access 未配置，产生错误的“已上线”认知**
  - 缓解：将 Access 视为上线门禁，并在文档与 PR body 中明确“未完成 Access 验证前不算发布完成”。

- **风险：`config` / `extraConfig` 混淆导致 tunnel 配置未生效**
  - 缓解：统一模块注释、主机示例、文档与 setup 脚本中的字段名。

- **风险：日志落在临时目录，不利于长期排障**
  - 缓解：首版仍提供固定日志路径用于快速排障，后续可再迁移到用户状态目录。

- **风险：仅依赖 Access，缺少应用层第二道认证**
  - 缓解：首版接受该风险，但在文档中记录后续可选加固项 `OPENCODE_SERVER_PASSWORD`。

## 10. 开放问题 / 默认假设

### 开放问题

- 是否后续需要为 opencode server 再增加 basic auth，形成 Access 之外的第二层认证？
- 是否未来要把 Access / DNS / policy 也纳入自动化？

### 默认假设

- `charlie` 上已有可用的 tunnel ID 与凭证文件。
- `opencode` 已安装在 `/Users/c1/.opencode/bin/opencode`。
- `opencode-charlie.0xc1.space` 可作为本次默认 hostname。
- Cloudflare Zero Trust 管理员有权限配置按邮箱放行策略。

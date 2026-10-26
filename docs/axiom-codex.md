# Axiom Codex 与 Charlie 中转

Axiom 运行 Codex CLI / App Server，Charlie 的桌面应用通过 `axiom-tunnel`
连接它。手机连接 Charlie 的 Remote，再选择 Axiom 远程项目。
Charles 管理 Axiom 时也使用已有的 `ssh axiom-tunnel`。

## 安装与配置

- Codex CLI 由官方 standalone installer 安装到用户目录：版本文件位于
  `~/.codex/packages/standalone`，`~/.local/bin/codex` 启动器调用
  `~/.local/lib/codex/bin/codex`。CLI 版本不由 Nix 固定。
- `hosts/axiom/modules/codex.nix` 声明加密凭据和远端文件读取兼容链接，不安装 Codex CLI。
  用户自己的 `~/.codex/config.toml` 保存 provider、模型和其他偏好。
- provider token 存放在 `hosts/axiom/secrets/codex-ntnl-key.age`，agenix
  解密至 `/run/agenix/codex-ntnl-key`，由 `c1` 以 `0400` 读取。
  `~/.local/bin/codex` 在调用方未提供 `NTNL_API_KEY` 时加载该凭据，并设置
  `CODEX_INSTALL_DIR`，使 CLI 自带更新器继续更新同一个用户级安装。
  明文不会写入 Nix store 或配置文件；凭据不可读时启动器仍会启动 Codex。
- Axiom 的历史、登录资料和其他现有数据继续使用 `/home/c1/.codex`。
- 后续在 Axiom 执行 `codex update` 原地更新；不需要修改 Nix 包、构建或切换系统。

更新后检查命令路径和版本：

```sh
ssh axiom-tunnel 'command -v codex && codex --version'
ssh axiom-tunnel 'codex update'
ssh axiom-tunnel 'codex --version'
```

## 远端文件预览兼容

桌面客户端 `26.1021.31345` 在 Unix 远端通过 `process/spawn` 执行
`/bin/cat <文件路径>` 读取预览内容。NixOS 默认没有 `/bin/cat`，因此可能出现
聊天、变更树正常，但 Markdown、HTML 无法打开；直接调用 `fs/readFile` 成功也不能排除该问题。

Axiom 的 Codex 模块通过 `systemd.tmpfiles.rules` 将 `/bin/cat` 链接到
`${pkgs.coreutils}/bin/cat`。规则在系统切换及启动时应用，随配置更新目标路径。
部署后应验证 `/bin/cat` 可执行、原始 `process/spawn` 请求成功，再重新打开桌面预览。
修改 `PATH` 无法修复客户端使用绝对路径的问题。

上游取消这一绝对路径依赖后可移除规则；移除规则不会自动删除已创建的链接，
清理时需先确认 `/bin/cat` 仍是本规则管理的符号链接。

## 日常切换 provider

启动时选择已配置的 provider，无需编辑默认值或运行 Nix：

```sh
ssh axiom-tunnel
codex -c 'model_provider="ntnl"'
```

`ntnl` 是 provider ID；其他自定义 provider 需要先在用户配置中添加定义和凭据。
CLI 的 `/model` 用于模型与推理强度选择，没有通用 `/provider` 热切换命令。
启动参数只作用于该 CLI 进程，不会替 Charlie / 手机已经打开的任务切换 provider。

要改变后续任务的默认值，直接编辑 Axiom 的 `~/.codex/config.toml` 中的
`model_provider`，不需要 rebuild。需要使用 NTNL provider 时，可配置：

```toml
model = "gpt-6-astra"
model_provider = "ntnl"

[model_providers.ntnl]
name = "NTNL"
base_url = "https://openai.ntnl.io/v1"
env_key = "NTNL_API_KEY"
requires_openai_auth = false
wire_api = "responses"
```

首次从旧的 Home Manager 配置迁移时，先把 `~/.codex/config.toml` 符号链接的
内容原样复制为同路径的普通文件，并设为 `0600`，再切换到不再声明该文件的新系统。
仅转换指向 Nix store 的旧链接；已有普通文件保持原样。后续部署无需重复迁移。

## Charlie 的入口

`config/codex/charlie.json` 由 Charlie 的 Home Manager 放到
`~/.codex/codex-app/config.json`，声明：

- SSH alias：`axiom-tunnel`
- 首个项目：`/home/c1/dotfiles`，显示为 **dotfiles · Axiom**

这个桌面配置文件独立于 `~/.codex/config.toml`，不会复制 Charlie 的其他 provider、
MCP、插件或权限配置到 Axiom。初次部署也可将此文件复制到上述位置；若已有配置，
应合并 `remoteConnections`，保留其他声明。

Charlie 当前桌面版本 **26.908.40834** 支持从磁盘重新加载该声明：

```sh
open -a ChatGPT 'codex://codex-app/apply-config'
ssh axiom-tunnel 'codex --version'
```

也可在桌面应用的 **设置 → 连接** 中管理 SSH 主机，并添加其他 Axiom 项目。
App Server 由桌面应用通过 SSH 启动，不部署公网 App Server 端口或额外常驻服务。

## 在手机上开始工作

1. 打开手机 ChatGPT，进入 **Remote / 远程**。
2. 选择已配对的 **Charlie**，新建任务。
3. 在项目列表中选择 **dotfiles · Axiom**，再输入任务。
4. 首次可让 Codex 运行 `hostname` 和 `pwd`：应分别返回 `axiom` 和
   `/home/c1/dotfiles`，以确认执行位置。

如果手机尚未显示 Charlie，在 Charlie 桌面应用打开 **设置 → 连接 → 控制此 Mac**，
选择添加设备，使用手机扫描二维码，并以同一 ChatGPT 账号与工作空间完成配对。
Charlie 已有的手机配对无需重新创建。让 Charlie 保持唤醒、联网并运行桌面应用，
Axiom 保持开机且 SSH 可达。

要在其他仓库工作，先在 Charlie 桌面端为 `axiom-tunnel` 添加相应远程目录，
然后从手机选择该项目；在 Charlie 的本地项目中新建任务仍会使用 Charlie。

## A、B、C 三种方式的核实

| 方案 | 结论与本次选择 |
| --- | --- |
| A：手机 → Charlie → SSH → Axiom | 官方文档支持桌面主机连接远程开发环境，再从手机控制该主机；本次采用。Charlie 需在线、保持唤醒、运行桌面应用，并完成 Remote 配对。 |
| B：手机 SSH + tmux + CLI | 可作为终端入口；使用 Axiom 用户目录里的 standalone Codex CLI，没有桌面应用的图形审阅体验。此次不新增手机 SSH 配置。 |
| C：自行实现 App Server 客户端 | 协议与 WebSocket transport 可用，但官方将此 transport 标为实验性且不受支持；本次不开发新客户端。 |

Linux 桌面预览版确已发布，但 NixOS 不在其正式支持的发行版列表中；本次安装的是
CLI / App Server。Linux 暂无 Computer Use，官方 Remote 主机支持列表仍是
macOS / Windows，因此不能把“Linux 可执行任务”理解为所有桌面与手机功能均原生支持。

来源（核实于 2026-09-15）：[远程连接](https://learn.chatgpt.com/zh-Hans/docs/remote-connections)、
[CLI](https://learn.chatgpt.com/zh-Hans/docs/codex/cli)、
[Linux 桌面预览](https://learn.chatgpt.com/zh-Hans/docs/linux/linux-app)、
[App Server](https://learn.chatgpt.com/zh-Hans/docs/app-server)。

## 验证与边界

SSH App Server 完成 `initialize`，并在只读沙盒中通过
`command/exec` 返回主机名 `axiom`。NTNL provider 曾用独立凭据完成真实模型请求，
返回 `AXIOM_NTNL_OK`。

Axiom 的 `codex` 命令由用户级启动器解析到官方 standalone 安装；检查时用
`command -v codex` 和 `codex --version` 确认实际入口与版本。

Axiom 原有 ChatGPT 登录资料保留。NTNL 模型请求使用独立 API key，不要求 ChatGPT 登录；
需要 ChatGPT 账号的其他工具仍取决于原登录是否有效。

手机端点击、审批与通知需要实际手机验证；桌面端连接和 SSH 命令测试不能替代这些验证。

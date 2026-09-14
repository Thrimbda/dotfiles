# Axiom Codex 与 Charlie 中转

Axiom 运行 Codex CLI / App Server，Charlie 的桌面应用通过 `axiom-tunnel`
连接它。手机连接 Charlie 的 Remote，再选择 Axiom 远程项目。
Charles 管理 Axiom 时也使用已有的 `ssh axiom-tunnel`。

## 安装与配置

- `packages/codex/default.nix` 固定官方 standalone **0.154.0** 与 SHA-256，
  保留 code-mode host、ripgrep、bubblewrap 和 zsh；修复 bundled zsh 在 NixOS
  上的 ELF loader 与 ncurses 路径。无需 npm 或另装 Node 来启动 Codex。
- `hosts/axiom/modules/codex.nix` 将 `codex` 加入系统 PATH，SSH 非交互登录也可用。
  只配置 Charlie 的 `ntnl-openai` provider 和 `gpt-6-astra` 模型。
- provider token 存放在 `hosts/axiom/secrets/codex-ntnl-openai-key.age`。
  agenix 解密至 `/run/agenix/codex-ntnl-openai-key`，由 `c1` 以 `0400` 读取。
  启动器通过 `NTNL_OPENAI_API_KEY` 注入，不把明文写入 Nix store 或配置文件。
- Axiom 的历史、登录资料和其他现有数据继续使用 `/home/c1/.codex`。
  初次检查未发现 npm Codex 安装，因此无需卸载其他 npm 包。
- 后续升级修改包版本与 hash，经构建、PR 和系统 switch 生效。
  不使用 `codex update` 另建一份用户目录安装来覆盖 Nix 版本。

在 Axiom 上构建：

```sh
cd /home/c1/dotfiles
nix build .#packages.x86_64-linux.codex
nix build .#nixosConfigurations.axiom.config.system.build.toplevel
```

switch 前比较当前运行系统，保留其他任务已部署但尚未合并的配置；不要直接以旧的
master 覆盖这些配置。此次部署时另有 Sunshine/FRP 任务，需保留其运行配置。

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

## A、B、C 三种方式的核实

| 方案 | 结论与本次选择 |
| --- | --- |
| A：手机 → Charlie → SSH → Axiom | 官方文档支持桌面主机连接远程开发环境，再从手机控制该主机；本次采用。Charlie 需在线、保持唤醒、运行桌面应用，并完成 Remote 配对。 |
| B：手机 SSH + tmux + CLI | 可作为终端入口；使用同一个 Nix Codex 包，没有桌面应用的图形审阅体验。此次不新增手机 SSH 配置。 |
| C：自行实现 App Server 客户端 | 协议与 WebSocket transport 可用，但官方将此 transport 标为实验性且不受支持；本次不开发新客户端。 |

Linux 桌面预览版确已发布，但 NixOS 不在其正式支持的发行版列表中；本次安装的是
CLI / App Server。Linux 暂无 Computer Use，官方 Remote 主机支持列表仍是
macOS / Windows，因此不能把“Linux 可执行任务”理解为所有桌面与手机功能均原生支持。

来源（核实于 2026-09-15）：[远程连接](https://learn.chatgpt.com/zh-Hans/docs/remote-connections)、
[CLI](https://learn.chatgpt.com/zh-Hans/docs/codex/cli)、
[Linux 桌面预览](https://learn.chatgpt.com/zh-Hans/docs/linux/linux-app)、
[App Server](https://learn.chatgpt.com/zh-Hans/docs/app-server)。

## 验证与边界

包构建已验证 CLI 版本、code-mode host、ripgrep、bubblewrap 和修复后的 zsh。
Axiom 完整系统构建通过；SSH App Server 完成 `initialize`，并在只读沙盒中通过
`command/exec` 返回主机名 `axiom`。使用 NTNL provider 的真实模型请求也成功调用
shell，返回 `AXIOM_CODEX_OK hostname=axiom` 与测试目录。

Axiom 原有 ChatGPT 登录刷新失败，账号关联工具出现 401；NTNL 的模型请求仍成功。
provider 的模型列表接口返回 OpenAI 标准 `data` 格式，Codex 的动态模型目录刷新会
报告格式不匹配；显式配置的 `gpt-6-astra` 已实测可用。此次未替换登录资料或扩展插件配置。

手机端点击、审批与通知需要实际手机验证；桌面端连接和 SSH 命令测试不能替代这些验证。

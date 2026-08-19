# hey 功能清单与 c1ctl Native 替换状态

基于当前仓库源码，`hey` 是一个 Janet 写的 dotfiles/NixOS 调度 CLI，入口在 `bin/hey`，核心命令在 `bin/hey.d/*.janet`，同时支持把 `bin/`、`hosts/$HOST/bin/`、`config/$WM/bin/`、`config/<namespace>/bin/` 下的脚本当成子命令派发。

## c1ctl 状态说明

| 状态 | 含义 |
|---|---|
| native | 已由 `c1ctl` Rust 代码直接实现 |
| native dispatch | `c1ctl` 已能解析并执行入口，但目标脚本本体仍是 shell/TS/Janet |
| delegated | `c1ctl` 会委托回 Janet `hey` |
| partial | `c1ctl` 只覆盖部分语义 |
| out of scope | 明确不迁入 Rust，通常是 Rofi |
| not native | 未由 `c1ctl` 原生实现 |

## 总览

| 类别 | hey 状态 | c1ctl 状态 |
|---|---|---|
| CLI 名称 | `hey` 仍存在，Janet 入口 | `c1ctl` 是新 Rust 主入口 |
| path/help/which/exec foundation | Janet 实现 | native |
| `.foo` / `wm` / `host` / `theme` / non-Rofi `@namespace` dispatch | Janet 实现 | native dispatch |
| Rofi | Janet/Rofi scripts | out of scope，`@rofi` exact delegation |
| mutating Nix/dotfiles workflows | Janet 实现 | delegated |
| dynamic shell/TS scripts | shell/TS/Janet | native dispatch，但脚本本体未 Rust 化 |

## 全局能力

| 功能 | 用法 | 说明 | c1ctl 状态 |
|---|---|---|---|
| 帮助 | `hey help COMMAND`、`hey h COMMAND`、`hey COMMAND --help` | 读取目标脚本头部注释作为帮助文本 | native |
| 定位命令 | `hey which COMMAND ...` | 打印最终解析到的脚本路径和转发参数 | native |
| Dry run | `hey -! ...` | 设置 dry-run；Janet `do?` 和 zsh `hey.do` 会尽量只打印不执行 | partial，`c1ctl` 会传 `HEYDRYRUN`，但具体脚本是否尊重仍取决于脚本 |
| Debug | `hey -? ...`、`hey -?? ...`、`hey -??? ...` | 设置 1/2/3 级 debug；也可通过 `HEYDEBUG` | partial，`c1ctl` 会解析并传 `HEYDEBUG` |
| 环境传递 | `HEYDRYRUN`、`HEYDEBUG`、`HEYSCRIPT`、`HEYENV` | 给下游 Janet/zsh 脚本继承当前 hey 状态 | partial，`c1ctl` 设置 `DOTFILES_HOME`、computed `PATH`、`HEYSCRIPT`、`HEYDRYRUN`、`HEYDEBUG`，不实现 `HEYENV` |
| 动态解析 | `hey .name`、`hey @rofi name`、`hey wm name` | 解析 `.d` 子目录、`.janet/.zsh/.sh/无扩展名` 脚本 | native dispatch；`@rofi` delegated |

## 核心命令

| 命令 | 用法 | 当前功能 | c1ctl 状态 |
|---|---|---|---|
| `build` / `b` | `hey build`、`hey build -a` | 编译并部署 `bin/hey`，`-a` 会带上构建依赖 | delegated |
| `build iso` | `hey build iso` | 为当前 NixOS host 构建 ISO，输出到 system profile | delegated |
| `build vm` | `hey build vm` | 调 `hey sync -- build-vm` 构建 VM | delegated |
| `build vm-with-bootloader` | `hey build vm-with-bootloader` | 调 `hey sync -- build-vm-with-bootloader` | delegated |
| `gc` | `hey gc [-a] [-s] [-d]` | Nix GC；默认清用户 profile，`-s` 清 system，`-a` 两者都清，`-d` 删除旧 generation | delegated |
| `hook` | `hey hook HOOK [ARGS...] [-g] [-f] [-v]` | 触发 hook 脚本；支持防重复、runtime lock、host hook、WM hook、生成的 `hooks.d` | delegated |
| `info` | `hey info [KEYS...]` | 从 `$XDG_DATA_HOME/hey/info.json` 读 flake/host/theme 等信息，默认 JSON 输出 | delegated |
| `info -r` | `hey info -r KEY...` | raw 输出 | delegated |
| `info ip` | `hey info ip [-w]` | 输出本机默认 IPv4；`-w` 查询公网 IP | delegated |
| `info user/repo` | `hey info owner/repo` | 通过 `nix-prefetch-git` 查询 GitHub repo | delegated |
| `info URL` | `hey info https://...` | 通过 `nix-prefetch-git` 查询 git URL | delegated |
| `ops` | `hey ops ...` | 占位命令，当前直接 `Not implemented yet` | delegated，但原命令本身未实现 |
| `path` | `hey path [-e|-d|-f] [-a] [AREA] [SEGMENTS...]` | 输出 dotfiles/XDG/host/theme/profile 等路径 | native |
| `path xdg` | `hey path xdg data foo` | 输出 `$XDG_DATA_HOME/foo` 这类路径 | native |
| `profile` / `pr` | `hey profile` | 输出 system profile 路径 | delegated |
| `profile -u` | `hey profile -u` | 输出 user profile 路径 | delegated |
| `profile ls` | `hey profile ls [-r]` | 列出 nixos/darwin rebuild generations，JSON 输出；`-r` 刷新缓存 | delegated |
| `profile rm` | `hey profile rm GEN...` | 删除指定 system generation；支持负数索引 | delegated |
| `profile diff` | `hey profile diff FROM [TO]` | 对比两个 generation 的 nix-store references | delegated |
| `pull` | `hey pull` | 更新所有 flake inputs | delegated |
| `pull INPUTS...` | `hey pull zen-browser 'hypr*' '!foo'` | 按 glob/否定 glob 更新匹配 inputs | delegated |
| `pull -o` | `hey pull -o input@rev`、`hey pull -o input=flake-uri` | 用 `--override-input` 临时 repin/update input | delegated |
| `reload` / `re` | `hey reload` | 触发 `hey hook reload -f -v`，成功后发通知 | delegated |
| `repl` | `hey repl [ARGS...]` | 打开预加载当前 flake 的 `nix repl` | delegated |
| `repl -j` | `hey repl -j` | 打开预加载 `hey` libs 的 Janet REPL | delegated |
| `repl -d` | `hey repl -d` | 打开 `nix develop $DOTFILES_HOME` | delegated |
| `swap` / `sw` | `hey swap FILES...` | 把 nix-store symlink 替换成可修改 copy，并记录到 `$XDG_DATA_HOME/hey/swap` | delegated |
| `swap -u` | `hey swap -u FILES...` | 恢复已 swap 文件 | delegated |
| `swap -l` | `hey swap -l` / `hey swap --list` | 列出已 swap 文件 | delegated |
| `swap --reset` | `hey swap --reset` | 恢复所有已知 swap 文件 | delegated |
| `sync` / `s` | `hey sync [ACTION] [ARGS...]` | 调 `nixos-rebuild` 或 `darwin-rebuild`，默认 action 是 `switch` | delegated |
| `sync --fast` | `hey sync --fast switch` | NixOS rebuild 时加 `--fast` | delegated |
| `sync check` | `hey sync check` / `hey sync ch` | 运行 `nix flake check`，不写 lock、不更新 lock | delegated |
| `sync rollback` | `hey sync rollback [GENERATION]` | 无 generation 时走 rebuild `--rollback switch`；有 generation 时切 system profile generation | delegated |
| `vars` | `hey vars` | 列出 runtime vars | delegated |
| `vars get` | `hey vars get KEY` | 读取 runtime var | delegated |
| `vars set` | `hey vars set KEY VALUE` | 设置 runtime var | delegated |
| `vars -g` | `hey vars -g ...` | 使用 persistent global vars | delegated |
| `get` / `set` | `hey get KEY`、`hey set KEY VALUE` | `hey vars get/set` 的顶层别名 | delegated |
| `test` | `hey test [ARGS...]` | 运行 `judge $DOTFILES_HOME/test/hey` | delegated |

## 派发能力

| 入口 | 解析目标 | 说明 | c1ctl 状态 |
|---|---|---|---|
| `hey exec CMD ...` | `$PATH` 中的命令 | 用 hey 的 PATH 规则查找并执行 | native |
| `hey ./script ...` / `hey /abs/script ...` | 明确脚本路径 | 直接执行给定路径 | native，且会阻止直接解析 `config/rofi/**` |
| `hey .name ...` | `hosts/$HOST/bin`、`config/$WM/bin`、`bin` | 依次查找当前 host、当前 WM、全局 bin 下的脚本 | native dispatch |
| `hey host name ...` | `hosts/$HOST/bin/name` | 只在当前 host 脚本目录派发 | native dispatch |
| `hey wm name ...` | `config/$WM/bin/name` | 只在当前 WM 脚本目录派发 | native dispatch |
| `hey theme name ...` | `modules/themes/$THEME/bin/name` | 支持主题脚本派发；当前仓库没有找到 theme bin 脚本 | native dispatch |
| `hey @rofi name ...` | `config/rofi/bin/name` | 指定 namespace 派发 | delegated，Rofi 不 native |
| `hey @hypr name ...` | `config/hypr/bin/name` | 指定 Hypr namespace | native dispatch |
| `hey @tmux name ...` | `config/tmux/bin/name` | 指定 tmux namespace | native dispatch |

## 全局 `bin/` 动态脚本

| 命令 | 用法 | 功能 | c1ctl 状态 |
|---|---|---|---|
| `.backup` | `hey .backup [push|pull]` | 同步 `~/.secrets/`、`~/projects/` 到 `/media/nas` 或从 NAS 拉回 | native dispatch，脚本未 Rust 化 |
| `.when` | `hey .when DATETIME` | 计算距离某时间/文件 mtime 的人类可读时长，或做相对时间计算 | native dispatch，脚本未 Rust 化 |
| `.cloudflared-setup` | `hey .cloudflared-setup --host HOST [--user USER] [--cidr CIDR]` | Cloudflare Zero Trust tunnel 初始化辅助，包含登录、建 tunnel、age 加密凭证、输出 Nix 配置片段 | native dispatch，脚本未 Rust 化 |
| `.lsiommu` | `hey .lsiommu` | 列出系统 IOMMU groups | native dispatch，脚本未 Rust 化 |
| `.qr` | `hey .qr FILE`、`echo TEXT | hey .qr` | 用 `qrencode` 输出 ANSI QR code | native dispatch，脚本未 Rust 化 |
| `.termcolors` | `hey .termcolors` | 打印终端真彩色渐变测试条 | native dispatch，脚本未 Rust 化 |
| `.autoclicker` | `hey .autoclicker` | 用 `xdotool` 或 `ydotool` 无限点击 | native dispatch，脚本未 Rust 化 |
| `.clash-switch.ts` | `hey .clash-switch.ts [list|switch NODE|NODE]` | Clash/Mihomo proxy group 列表、切换、交互选择 | native dispatch，脚本未 Rust 化 |
| `.clash-switch.ts --json` | `hey .clash-switch.ts list --json` | JSON 输出节点列表 | native dispatch，脚本未 Rust 化 |
| `.clash-switch.ts -c/-g/-s` | controller/group/secret | 可指定 controller URL、proxy group、API secret | native dispatch，脚本未 Rust 化 |
| `.optimize` | `hey .optimize [-l|-L] FILES|DIRS...` | 优化 PNG/JPG/GIF/PDF；默认无损，`-l` 有损，`-L` 只做有损 | native dispatch，脚本未 Rust 化 |

## Hypr/WM 脚本

| 命令 | 用法 | 功能 | c1ctl 状态 |
|---|---|---|---|
| `.slurp` | `hey .slurp [output|region|window] ...` | 封装 slurp，支持选显示器、区域、窗口 | native dispatch，脚本未 Rust 化 |
| `.quitactive` | `hey .quitactive` | 对当前 Hypr active window 的 PID 发 `SIGTERM` | native dispatch，脚本未 Rust 化 |
| `.screenshot` | `hey .screenshot [-s] [-o] [-f FILE] [region|window|output]` | 截图到剪贴板或文件；可用 swappy 编辑、pngquant 优化 | native dispatch，脚本未 Rust 化 |
| `.play-sound` | `hey .play-sound NAME`、`hey .play-sound ls` | 播放当前 theme sounds 下的音效；支持 `-v` 音量 | native dispatch，脚本未 Rust 化 |
| `.get-window` | `hey .get-window [GEOMETRY]` | 选窗口并输出对应 Hypr client JSON | native dispatch，脚本未 Rust 化 |
| `.get-font` | `hey .get-font [--xft|-c|-n|-s]` | 输出当前 theme terminal font，不同格式用于不同工具 | native dispatch，脚本未 Rust 化 |
| `.osd display` | `hey .osd display [OPTIONS] ICON TEXT` | 发 notify-send OSD，支持进度值、app/category、常驻、sound、hints | native dispatch，脚本未 Rust 化 |
| `.osd volume` | `hey .osd volume [-i|-o|-p PLAYER] [[+/-]LEVEL\|toggle]` | 控制输出、麦克风或 playerctl 音量并显示 OSD | native dispatch，脚本未 Rust 化 |
| `.osd brightness` | `hey .osd brightness [+/-]LEVEL` | 用 brightnessctl 调亮度并显示 OSD | native dispatch，脚本未 Rust 化 |
| `.osd toggle` | `hey .osd toggle --on/--off ...` | 显示开关型 OSD | native dispatch，脚本未 Rust 化 |
| `.get-activeworkspace` | `hey .get-activeworkspace [JQ_ARGS...]` | 输出真正 active workspace，包括 special workspace | native dispatch，脚本未 Rust 化 |
| `.picker` | `hey .picker [FMT]` | 用 hyprpicker 取色、复制、通知、播放反馈音 | native dispatch，脚本未 Rust 化 |
| `.screencast` | `hey .screencast [webm|mp4|gif] [SELECTOR]` | 录屏到 runtime 文件，把 URI 复制到剪贴板；再次运行会停止录制 | native dispatch，脚本未 Rust 化 |
| `.lock` | `hey .lock` | 兼容入口，实际执行 `caelestia shell lock lock` | native dispatch，脚本未 Rust 化 |
| `.export-env` | `hey .export-env [systemd|tmux] [-a] [ENVVARS...]` | 把当前环境变量导入 systemd/dbus 或 tmux | native dispatch，脚本未 Rust 化 |
| `.screendraw` | `hey .screendraw` | 切换 gromit-mpx 屏幕绘制，并显示 OSD | native dispatch，脚本未 Rust 化 |
| `.open-term` | `hey .open-term [-t TITLE] [-f FONT] [-F OFFSET] [-o KEY=VAL] -- [CMD...]` | 打开 foot 终端和 tmux session，special workspace 下自动增大字体 | native dispatch，脚本未 Rust 化 |
| `.set-monitors` | `hey .set-monitors [--on|--off] OUTPUTS...` | 根据 `hey info hypr monitors` 启用/禁用显示器 | native dispatch，脚本未 Rust 化 |
| `.toggle-zoom` | `hey .toggle-zoom [SCALE]` | 切换 Hypr cursor zoom，默认 2.0 | native dispatch，脚本未 Rust 化 |
| `.scratch emacs` | `hey .scratch emacs` | 打开大字体 Emacs scratch | native dispatch，脚本未 Rust 化 |
| `.scratch term` | `hey .scratch term` | 打开 scratch terminal 和 scratch calculator | native dispatch，脚本未 Rust 化 |

## Rofi 脚本

| 命令 | 用法 | 功能 | c1ctl 状态 |
|---|---|---|---|
| `@rofi appmenu` | `hey @rofi appmenu` | Rofi drun/run 应用启动器 | out of scope，delegated |
| `@rofi calcmenu` | `hey @rofi calcmenu` | Rofi calc 计算器 | out of scope，delegated |
| `@rofi filemenu` | `hey @rofi filemenu [ROFI_ARGS...]` | rofi-file-browser-extended 文件浏览器 | out of scope，delegated |
| `@rofi windowmenu` | `hey @rofi windowmenu` | Rofi window 切换菜单 | out of scope，delegated |
| `@rofi emojimenu` | `hey @rofi emojimenu` | rofimoji 表情菜单 | out of scope，delegated |
| `@rofi read` | `hey @rofi read [-P PLACEHOLDER] [-I ICON] [--password]` | 单行 dmenu 输入框 | out of scope，delegated |
| `@rofi powermenu` | `hey @rofi powermenu` | 关屏、锁屏、挂起、重启、选择 boot entry 重启、关机 | out of scope，delegated |
| `@rofi bookmarkmenu` | `hey @rofi bookmarkmenu [-r] [--profile PROFILE]` | 读取 Zen/Firefox bookmarks SQLite，通过 Rofi 打开书签 | out of scope，delegated |
| `@rofi audiomenu` | `hey @rofi audiomenu` | 用 pactl 切换默认输入/输出设备 | out of scope，delegated |
| `@rofi wifimenu` | `hey @rofi wifimenu [--rescan]` | 扫描/展示 wpa_supplicant Wi-Fi；连接/断开逻辑当前是 `not-implemented` | out of scope，delegated；原脚本未完整实现 |
| `@rofi mountmenu` | `hey @rofi mountmenu` | 目标是 udisks USB 挂载菜单，但当前 main 只显示 `Test`，真实逻辑被注释 | out of scope，delegated；原脚本未完整实现 |
| `@rofi vaultmenu` | `hey @rofi vaultmenu [-r] [-l]` | Bitwarden/Vaultwarden 菜单，支持解锁、同步、搜索 item、复制用户名/密码/TOTP/字段/附件、生成用户名/密码短语 | out of scope，delegated |
| `@rofi vaultmenu -l` | `hey @rofi vaultmenu -l` | 尝试回到上一次打开的 vault item | out of scope，delegated |

## Tmux 与 Host 脚本

| 命令 | 用法 | 功能 | c1ctl 状态 |
|---|---|---|---|
| `@tmux swap-pane` | `hey @tmux swap-pane [up|down|left|right|master]` | 与相邻 pane 或 master pane 交换 | native dispatch，脚本未 Rust 化 |
| `host set-monitors` | `hey host set-monitors [@all|@default|@primary|@tv|MONITOR...]` | `hosts/udon` 专用显示器别名，最终调用 `hey wm set-monitors` | native dispatch，脚本未 Rust 化 |

## 当前 Hook 能力

| Hook | 用法 | 功能 | c1ctl 状态 |
|---|---|---|---|
| `idle` | `hey hook idle --on/--off [dpms|lock|sleep]` | 空闲时调暗/恢复亮度、DPMS 开关、sleep 前暂停媒体/锁屏/音效 | delegated |
| `battery` | `hey hook battery --charging/--discharging/...` | 电池状态变化时调 Hypr 特效、亮度、OSD；`--poll` 会根据电量返回下次轮询间隔 | delegated |
| `gamemode` | `hey hook gamemode --on/--off` | 切换游戏模式相关 Hypr 设置并显示 OSD | delegated |
| `all` | fallback | 目前基本空实现 | delegated |

## 脚本库能力

| Helper | 功能 | c1ctl 状态 |
|---|---|---|
| `hey.do` | zsh 命令执行封装，支持 debug/dry-run、可选命令缺失 no-op、缺依赖时用 `cached-nix-shell` | not native |
| `hey.requires` | 检查依赖命令是否存在 | not native |
| `hey.echo` | 彩色/带 prefix 输出 | not native |
| `hey.log` | 受 `HEYDEBUG` 控制的日志 | not native |
| `hey.warn` / `hey.error` / `hey.abort` | warning/error/abort 输出 | not native |
| `hey.start` | 如果进程未运行则后台启动，可 `-r` 重启 | not native |
| `hey.cache` | 缓存命令输出并在交互 shell 中 source | not native |

## 明显未完成或实现不一致

| 项 | 状态 | c1ctl 状态 |
|---|---|---|
| `hey ops` | 完全未实现 | delegated，但仍未实现 |
| `@rofi wifimenu` | 能展示/扫描，但 connect/disconnect/direct connect 未实现 | out of scope，delegated |
| `@rofi mountmenu` | 真实 mount UI 被注释，当前只显示 `Test` | out of scope，delegated |
| `hey vars ls` | 文档写了 `ls`，代码实际只有 `hey vars` 空命令会 list | delegated |
| `hey sync --host` | 文档草稿里提到过，但当前 `sync.janet` 没实现 | delegated |
| 补全里的 `--cat/--edit/--new/--really` | `_hey` 补全里出现，但当前 Janet dispatcher 没看到对应实现 | not native |
| `reload` 文档选项 | 头部写了 `[-w|--wm] [-n|--nixos]`，代码实际不解析这些选项 | delegated |

## c1ctl Native 替换结论

| 分类 | 数量/范围 | 结论 |
|---|---|---|
| 已 native 的 hey foundation | `path`、`help`、`which`、`exec`、direct path、`.foo`、`host`、`wm`、`theme`、non-Rofi `@namespace` | 已完成第一批迁移 |
| 仍 delegated 的核心命令 | `build`、`gc`、`hook`、`info`、`ops`、`profile`、`pull`、`reload`、`repl`、`swap`、`sync`、`test`、`vars`、`get`、`set` | 尚未 native |
| 动态脚本 | `bin/*`、`config/hypr/bin/*`、`config/tmux/bin/*`、`hosts/$HOST/bin/*` | `c1ctl` 可派发，但脚本本体未 Rust 化 |
| Rofi | `config/rofi/**` | 明确 out of scope，`@rofi` delegated |
| 脚本库 | `lib/hey/*.janet`、`lib/zsh/hey.*` | 尚未 native |

当前最适合继续 native 化的顺序：

| 优先级 | 候选 | 原因 |
|---|---|---|
| 1 | `reload` / `hook` | 和 `c1ctl` 的控制面最接近，能减少 reload 对 Janet 的依赖 |
| 2 | `vars` / `get` / `set` | 行为小，状态模型清晰 |
| 3 | `info` | 可重塑为 `c1ctl info` / `c1ctl health` |
| 4 | `profile` / `gc` / `pull` | Nix workflow，有一定风险但边界明确 |
| 5 | `sync` | rebuild path 风险最高，最后迁 |
| 不迁 | Rofi | 已明确排除 |

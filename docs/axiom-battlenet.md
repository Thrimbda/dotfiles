# Axiom 国服战网

在 Axiom 桌面按 **Super + 空格**，搜索 **战网** 或 **Battle.net**，选择 **Battle.net 国服战网**。Apple 键盘的 Command 键对应 Super。

也可以在桌面会话的终端运行：

```sh
battlenet
```

Lutris 管理启动环境；国服战网负责账号登录、安装游戏及自身更新。在战网中选择《魔兽世界》：“无限”即可下载安装。

网易登录会打开 Linux 默认浏览器。若提示“使用浏览器完成登录”却没有打开网页，可在桌面终端执行 `systemctl --user restart xdg-desktop-portal.service` 后重新点击登录。Axiom 的启动配置会在导入显示环境后刷新已运行的 portal 服务，避免它沿用缺少 `DISPLAY` 的环境。

## 首次安装或重建环境

1. 打开 `lutris`，等待首次运行的组件更新完成。
2. 执行 `battlenet --install`，或在战网桌面入口的操作菜单中选择“安装国服战网”。
3. 保持默认目录 `~/Games/battlenet-cn`，完成官方安装器。无需再创建应用菜单快捷方式，NixOS 已提供入口。
4. 安装完成出现登录窗口后，先关闭战网，让 Lutris 完成登记，再通过上述入口启动并登录。

## 更新与文件位置

- 战网本体位于 `~/Games/battlenet-cn/drive_c/Program Files (x86)/Battle.net`，由当前用户拥有，可自行更新，不锁定战网版本。
- Lutris 使用 `GE-Proton (Latest)`，通过 umu 下载运行器和 Steam runtime；它们不在 Nix store 中固定版本。
- Lutris 的游戏设置保存在 `~/.local/share/lutris/games/`，运行组件保存在 `~/.local/share/lutris/runtime/`。
- Nix 管理 Lutris、umu、安装配方和桌面入口。系统 rebuild 不会重置战网账号设置、游戏文件或战网更新。

若报缺少 DXVK 等 Lutris 组件，打开 Lutris 设置的 Updates 页面完成更新，再重试。不要通过关闭 DXVK 来绕过组件缺失。

配置入口为 `hosts/axiom/modules/battlenet.nix`。其中针对 Lutris 0.5.22 修正安装器对 `ge-proton` 的解析，并在 FHS 环境中提供 Vulkan 检测工具。升级 Lutris 时应检查这两处兼容措施是否仍需要。

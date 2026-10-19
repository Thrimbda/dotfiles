# 可编辑的 SSH 配置

`config/ssh/` 保存 SSH 主配置、连接片段和用于选路的公开主机密钥。
安装时复制成 `~/.ssh/` 下权限为 `600` 的普通文件，可以直接编辑。
私钥不包含在这份备份中，需要另行放到新机器上。

## 新机器安装

在 dotfiles 仓库根目录执行：

```sh
./bin/ssh-config-apply
```

Charles 的 Home Manager activation 已接入同一脚本，正常 setup / switch
会自动执行。其他 Nix 主机可在系统配置中导入 `config/ssh/mutable.nix`；
不要同时用 `home.file` 管理这些 SSH 文件。

脚本只补齐缺失文件，已有普通文件保留本机内容。已有符号链接会转换为
内容相同的可写副本。主配置缺少 `config.d` 的 Include 时会补上；缺失的
公开主机密钥会补入 `known_hosts`，已有信任记录不会替换。
重复执行不会用仓库版本覆盖日常修改。

`ssh axiom` 和 `ssh charlie` 在局域网主机密钥验证通过时直连，否则经 Ant
中转；加 `-tunnel` 的别名始终走中转。新环境若局域网地址改变，编辑对应片段。

## 保存后续修改

本机修改不会自动回写仓库。要更新备份，在仓库根目录执行下面的复制，
然后检查 Git diff。只复制配置，避免把私钥加入 Git：

```sh
cp ~/.ssh/config config/ssh/config
cp ~/.ssh/config.d/axiom.conf config/ssh/axiom.conf
cp ~/.ssh/config.d/charlie.conf config/ssh/charlie.conf
cp ~/.ssh/config.d/relay.conf config/ssh/relay.conf
git diff -- config/ssh
```

跨机器使用的片段应保留 `%d`（SSH 展开的用户主目录），不要写死
`/Users/c1`。Linux 主配置在 `UseKeychain` 之前需要 `IgnoreUnknown UseKeychain`。
仓库更新不会自动覆盖已安装的副本；需要更新哪一份时，先查看差异再手动复制。

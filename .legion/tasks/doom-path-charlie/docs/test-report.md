# Test Report

## 验证目标

证明 charlie host 配置语法有效，并且生成的 zsh env 初始化内容确实会把 Doom CLI 与直接安装的 Emacs.app CLI shim 加入 `PATH`。

## 执行命令

```sh
nix-instantiate --parse hosts/charlie/default.nix >/dev/null
```

结果：通过，exit code 0。

```sh
nix eval --raw --no-eval-cache '.#darwinConfigurations.charlie.config.home-manager.users.c1.home.file.".config/zsh/.zshenv".text' \
  | sed -n '/modules.shell.zsh.envInit/,/modules.shell.zsh.envFiles/p'
```

结果：通过，exit code 0。相关输出包含：

```zsh
path=(
  "$XDG_CONFIG_HOME/emacs/bin"
  "/Applications/Emacs.app/Contents/MacOS/bin"
  "${path[@]}"
)
typeset -U path PATH
```

## 选择理由

`nix-instantiate --parse` 直接覆盖本次修改文件的 Nix 语法；`nix eval` 覆盖 charlie Darwin 配置生成路径，能证明 `modules.shell.zsh.envInit` 被实际纳入生成的 `.config/zsh/.zshenv`，比只检查 diff 更能证明用户可见效果。

## 跳过项

未执行完整 `darwin-rebuild switch`，因为本次验证只需要证明配置生成内容正确；实际切换系统配置属于用户机器状态变更，不应在 PR worktree 验证阶段隐式执行。

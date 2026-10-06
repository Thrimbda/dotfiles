# Doom Org/Norang Minimal - 验证报告

## 验证摘要

结果：PASS，存在非阻塞环境 warning。

本次验证选择优先覆盖三类风险：

- Doom 是否接受精简后的 module/package 配置。
- `bh-org.el` 在当前 Emacs 30 / Org 9.8 环境是否仍可加载。
- 已知 norang 锚点与兼容修补是否没有明显回归。

## 执行命令与结果

### Doom sync

命令：

```sh
DOOMDIR=/Users/c1/.config/doom/.worktrees/doom-org-norang-minimal ~/.config/emacs/bin/doom sync
```

结果：exit code 0。

关键信息：

- `No packages need attention`
- `All 77 packages are up-to-date`
- `Built init.30.2.el`
- `Finished`

选择理由：`init.el` 与 `packages.el` 是本任务核心改动，`doom sync` 能验证 Doom module/package graph 可解析并能生成 profile init 文件。

### Doom doctor

命令：

```sh
DOOMDIR=/Users/c1/.config/doom/.worktrees/doom-org-norang-minimal ~/.config/emacs/bin/doom doctor
```

结果：exit code 0。

关键信息：

- `Initialized Doom Emacs 2.2.0`
- `Detected 16 modules`
- `Detected 60 packages`
- 剩余 3 个 warning：
  - `unable to detect fonts because fontconfig isn't installed`
  - 检测到 `~/.config/doom/` 与 worktree 两个 private config；这是隔离 worktree 验证时的预期提示
  - `Cannot find gls (GNU ls)`，可能影响 dired

选择理由：`doom doctor` 能补充检查 Doom 本体、模块启用和常见环境问题；剩余 warning 不属于本任务实现缺口。

### Active config post-merge validation

PR 合并并刷新主 `/Users/c1/.config/doom` 后，重新验证 active config。

命令：

```sh
DOOMDIR=/Users/c1/.config/doom /Users/c1/.config/emacs/bin/doom sync
DOOMDIR=/Users/c1/.config/doom /Users/c1/.config/emacs/bin/doom doctor
```

结果：两个命令均 exit code 0。

关键信息：

- `doom sync`: `All 77 packages are up-to-date`，`Built init.30.2.el`，`Finished`
- `doom doctor`: `Initialized Doom Emacs 2.2.0`，`Detected 16 modules`，`Detected 60 packages`
- active config 下不再出现 worktree/private config 并存 warning
- 剩余 warning 为 fontconfig 字体检测 warning 两处，以及 `gls` 缺失

选择理由：确认最终写入用户实际使用的 `/Users/c1/.config/doom` 后，Doom 仍可同步、初始化并通过 doctor。

### Lisp 语法检查

命令：

```sh
emacs -Q --batch --eval '(dolist (file (quote ("init.el" "config.el" "packages.el" "bh-org.el"))) (with-temp-buffer (insert-file-contents file) (emacs-lisp-mode) (check-parens)) (princ (format "check-parens ok: %s\n" file)))'
```

结果：exit code 0。

输出：

```text
check-parens ok: init.el
check-parens ok: config.el
check-parens ok: packages.el
check-parens ok: bh-org.el
```

选择理由：快速确认四个被改动的 Emacs Lisp 文件没有括号结构错误。

### `bh-org.el` batch load

命令：

```sh
emacs -Q --batch \
  -L ~/.config/emacs/.local/straight/build-30.2/org \
  -L ~/.config/emacs/.local/straight/build-30.2/org-contrib \
  -L ~/.config/emacs/.local/straight/build-30.2/htmlize \
  -L ~/.config/emacs/.local/straight/build-30.2/ob-async \
  --eval '(setq user-emacs-directory (expand-file-name "~/.config/emacs/"))' \
  --eval '(setq org-user-agenda-files (quote ("~/OneDrive/cone")))' \
  --eval '(setq debug-on-error t)' \
  -l bh-org.el \
  --eval '(princ "bh-org load ok\n")'
```

结果：exit code 0。

输出：

```text
bh-org load ok
```

选择理由：直接证明 `org-iswitchb`、`incf`、Babel `sh`/`ammonite` 等兼容修补后，`bh-org.el` 可以在当前 Org 包环境中加载。

### Diff / scope 检查

命令：

```sh
git diff --check
git diff --stat
git diff --name-only
```

结果：exit code 0。

变更文件：

```text
bh-org.el
config.el
init.el
packages.el
```

统计：

```text
4 files changed, 31 insertions(+), 250 deletions(-)
```

选择理由：确认没有 whitespace error，且实际改动只触及 contract scope 内的 Doom private config 文件。

### Norang 锚点 / GPG 风险复查

命令：

```sh
rg -n "3CA66213-50ED-48B9-8E24-310B0959DA75" ~/OneDrive/cone -g '*.org' -g '*.org_archive'
gpg --list-secret-keys --keyid-format LONG F0B66B40
```

结果：

- Organization default clock task ID 存在于 `/Users/c1/OneDrive/cone/todo.org:157`。
- `F0B66B40` 没有本机 secret key，且 GPG homedir permissions 有 warning。

选择理由：continuous clocking 的默认锚点是 norang 工作流核心；GPG key 是 `org-crypt` 的已知残余风险，本任务记录但不创建/导入 key。

### Active Lisp checks

命令：

```sh
emacs -Q --batch --eval '... check-parens over /Users/c1/.config/doom/{init.el,config.el,packages.el,bh-org.el} ...'
emacs -Q --batch ... -l /Users/c1/.config/doom/bh-org.el --eval '(message "bh-org active load ok")'
```

结果：两个命令均 exit code 0。

输出：

```text
check-parens ok: /Users/c1/.config/doom/init.el
check-parens ok: /Users/c1/.config/doom/config.el
check-parens ok: /Users/c1/.config/doom/packages.el
check-parens ok: /Users/c1/.config/doom/bh-org.el
bh-org active load ok
```

选择理由：补证最终 active config 的 Lisp 结构和 `bh-org.el` load path，与 worktree 验证一致。

## 未覆盖 / 残余风险

- 没有启动 GUI Emacs 做人工交互烟测；当前证据覆盖配置解析、Doom sync、doctor 和 `bh-org.el` 加载。
- `org-crypt-key` 仍需用户提供本机可用 GPG secret key 才能真正加密 `:crypt:` 条目。
- `gls` 缺失可能影响 dired 体验，但不影响 Org/Norang 工作流核心。

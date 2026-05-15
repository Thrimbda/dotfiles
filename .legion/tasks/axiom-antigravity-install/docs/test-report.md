# Axiom Antigravity Install - Test Report

## 结论

PASS。axiom 配置已包含 Google Antigravity FHS package，目标 package 可构建，axiom 系统 toplevel 可完成 dry-run 评估。

## 验证命令

### 1. 用户包包含 Antigravity

```bash
nix eval --json .#nixosConfigurations.axiom.config.users.users.c1.packages --apply 'packages: builtins.filter (name: name == "antigravity" || name == "google-antigravity" || name == "antigravity-fhs" || name == "antigravity-1.15.8") (builtins.map (package: package.pname or package.name or "") packages)'
```

结果：PASS，输出 `[
"antigravity"
]`。

用途：直接证明 axiom 的声明式用户包列表包含 Antigravity，而不只是在文件中出现字符串。

### 2. Antigravity FHS package 可构建

```bash
nix build --no-link .#nixosConfigurations.axiom.pkgs.unstable.antigravity-fhs
```

结果：PASS。构建完成，未创建 result symlink；当前 flake lock 中目标版本为 `1.15.8`。

用途：证明所选 `pkgs.unstable.antigravity-fhs` derivation 可解析、可下载/构建，不是仅 eval 可见。

### 3. axiom 系统 toplevel dry-run

```bash
nix build --dry-run .#nixosConfigurations.axiom.config.system.build.toplevel
```

结果：PASS。dry-run 成功，输出中包含 `antigravity-1.15.8` 相关 derivations，并生成 axiom system toplevel derivation plan。

用途：证明完整 axiom NixOS 配置能解析到 rebuild 计划，并把 Antigravity 纳入系统构建闭包。

### 4. Diff whitespace

```bash
git diff --check
```

结果：PASS，无输出。

用途：检查补丁没有引入尾随空白或冲突标记。

## 选择理由

- `nix eval` 比纯 grep 更能证明 NixOS module 合并后的实际用户包列表。
- `nix build --no-link` 针对新增 package 本身，能发现上游下载、hash、wrapper 构建等问题。
- `nix build --dry-run` 针对 axiom toplevel，覆盖声明式 rebuild 解析路径且避免执行完整系统构建。
- 未运行 GUI 启动验证，因为 contract 只要求安装进入系统环境，不包含账号登录、扩展或运行态验证。

## 警告 / 已知限制

- Nix eval 输出了仓库既有 warning：`specialArgs.pkgs`、`mesa.drivers` deprecation、`hardware.pulseaudio` rename、`system` rename。这些不是本次 Antigravity 变更引入。
- `nix build --dry-run` 证明 rebuild plan 可解析，不会实际切换 axiom 系统。
- 当前 `nixpkgs-unstable` lock 中 `antigravity-fhs` 版本为 `1.15.8`；如果需要更新到更高上游版本，应另开 lock/update 任务。

---

*生成于: 2026-05-15*

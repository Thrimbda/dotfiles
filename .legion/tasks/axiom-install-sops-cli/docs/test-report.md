# Axiom Install Sops CLI - Test Report

## 结论

PASS。`pkgs.sops` 在当前 flake 的 `axiom` package set 中可用，`axiom` 最终 `users.users.c1.packages` 包含 `sops`，并且 `axiom` system toplevel derivation 可以成功求值生成。未执行 live `nixos-rebuild switch`。

## 为什么选择这些命令

- 本任务只添加一个 host-local CLI package，最直接证据是验证 package attribute 存在，并验证它出现在最终 NixOS 用户包集合中。
- `system.build.toplevel.drvPath` 求值可以验证完整 `axiom` 配置形状能生成系统构建 derivation，避免 live activation。
- `nix build --dry-run` 证明力更强，但本地执行受远端 cache 下载/重试影响，未在时限内完成，因此不作为 PASS 依据。

## 执行命令

### 1. 验证 `pkgs.sops` package attribute

Command:

```bash
nix eval --impure --raw .#nixosConfigurations.axiom.pkgs.sops.pname
```

Result: PASS

Output summary:

```text
sops
```

Notes:

- Nix emitted existing configuration warnings about `specialArgs.pkgs`; unrelated to this package install.

### 2. 验证最终用户包集合包含 `sops`

Command:

```bash
nix eval --impure --json .#nixosConfigurations.axiom.config.users.users.c1.packages --apply 'packages: builtins.any (pkg: (pkg.pname or "") == "sops") packages'
```

Result: PASS

Output summary:

```text
true
```

Notes:

- 这直接验证 `hosts/axiom/default.nix` 的 `user.packages` 变更进入最终 NixOS option 值。

### 3. 验证 `axiom` system toplevel derivation 可生成

Command:

```bash
nix eval --impure --raw .#nixosConfigurations.axiom.config.system.build.toplevel.drvPath
```

Result: PASS

Output summary:

```text
/nix/store/ivmd3j1ln9qpqxcx0vpmkdmplhfbw8ay-nixos-system-axiom-25.11.20260203.e576e3c.drv
```

Notes:

- Nix emitted existing warnings for `specialArgs.pkgs`, deprecated `mesa.drivers`, renamed `system`, and renamed `hardware.pulseaudio`; these warnings predate and are unrelated to adding `sops`.

### 4. Dry-run build attempt

Command:

```bash
nix build --impure --dry-run .#nixosConfigurations.axiom.config.system.build.toplevel
```

Result: INCONCLUSIVE

Output summary:

```text
warning: error: unable to download 'https://nix-community.cachix.org/...narinfo': HTTP error 500
error: interrupted by the user
shell tool terminated command after exceeding timeout 120000 ms
```

Notes:

- The command exceeded the 120 second tool timeout while retrying cache downloads.
- This is recorded as an environment/cache limitation, not an implementation failure.
- The toplevel derivation eval above was used as the non-fetching configuration-shape verification.

## 未执行

- `nixos-rebuild switch`: explicitly out of scope because it would activate the host configuration.
- `sops --version` on the live system: requires rebuilding/switching `axiom` first.

## 残余风险

- `sops` will only be available on the live `axiom` profile after the user applies the NixOS configuration.
- If future work needs declarative secrets integration, `sops-nix` adoption should be designed separately from this CLI install.

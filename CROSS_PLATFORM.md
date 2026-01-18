# 跨平台模块开发指南 (NixOS & nix-darwin)

本文档描述如何在此 dotfiles 项目中编写同时支持 NixOS 和 nix-darwin 的模块。

## 📋 目录

- [架构概述](#架构概述)
- [平台检测](#平台检测)
- [最佳实践](#最佳实践)
- [常见模式](#常见模式)
- [环境变量设置](#环境变量设置)
- [包安装](#包安装)
- [示例模块](#示例模块)
- [测试](#测试)

---

## 架构概述

### 项目结构

```
.
├── flake.nix              # 主入口，自动检测平台
├── default.nix            # NixOS 基础配置
├── darwin/default.nix     # nix-darwin 基础配置
├── lib/                   # 共享库函数
│   ├── nixos.nix         # mkFlake 基础设施
│   ├── options.nix       # 选项辅助函数（含 mkEnvVars）
│   └── ...
├── modules/               # 跨平台模块
│   ├── shell/
│   ├── dev/
│   ├── editors/
│   └── ...
└── hosts/                 # 主机配置
    ├── charlie/          # Darwin
    └── azar/             # NixOS
```

### 平台分离机制

1. **flake 级别**: 自动区分 `nixosModules` 和 `darwinModules`
2. **基础配置**: 平台特定的 `default.nix` 和 `darwin/default.nix`
3. **模块级别**: 通过条件检查实现跨平台兼容

---

## 平台检测

### 标准检测方法

```nix
{ pkgs, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in
{
  # 你的配置
}
```

### 何时使用平台检测

✅ **需要检测的情况**:
- 使用平台特定的系统选项（如 `virtualisation.docker`, `boot.kernel.sysctl`）
- 使用 systemd 服务或配置
- 使用 Linux 特定的包或功能
- 设置环境变量

❌ **不需要检测的情况**:
- 安装跨平台的包
- 设置 shell 别名
- 配置跨平台的应用程序

---

## 最佳实践

### 1. 平台特定配置应明确隔离

**好的做法** ✅:
```nix
config = mkMerge [
  # 通用配置
  {
    user.packages = [ pkgs.git ];
  }
  
  # Linux 特定
  (mkIf pkgs.stdenv.isLinux {
    virtualisation.docker.enable = true;
  })
  
  # Darwin 特定
  (mkIf pkgs.stdenv.isDarwin {
    homebrew.enable = true;
  })
];
```

**不好的做法** ❌:
```nix
config = {
  # 混合平台配置，难以维护
  virtualisation.docker.enable = if pkgs.stdenv.isLinux then true else false;
};
```

### 2. Linux 专用模块应添加保护

如果模块**完全是 Linux 专用**（如包含 boot、systemd、virtualisation 等选项）：

```nix
{ lib, config, pkgs, ... }:

# 整个模块包裹在 Linux 检查中
lib.mkIf pkgs.stdenv.isLinux {
  # 所有 NixOS 专用配置
  boot.kernel.sysctl = { ... };
  virtualisation.docker.enable = true;
}
```

参考: `modules/security.nix`

### 3. 服务模块应检查平台依赖

如果模块依赖 systemd 或其他 Linux 特定功能：

```nix
config = mkIf cfg.enable (mkMerge [
  # 通用配置
  {
    services.openssh.enable = true;
  }
  
  # systemd 特定配置（仅 Linux）
  (mkIf pkgs.stdenv.isLinux {
    systemd.user.tmpfiles.rules = [ ... ];
  })
]);
```

参考: `modules/services/ssh.nix`

---

## 常见模式

### 模式 1: 条件配置块

适用于大部分配置相同，少部分需要平台特定的场景。

```nix
config = mkIf cfg.enable (mkMerge [
  {
    # 共享配置
    user.packages = [ pkgs.nodejs ];
    environment.shellAliases.npm = "npm";
  }
  
  (mkIf pkgs.stdenv.isDarwin {
    # Darwin 特定
    home.packages = [ pkgs.nodejs ];
  })
  
  (mkIf pkgs.stdenv.isLinux {
    # Linux 特定
    systemd.user.services.node-server = { ... };
  })
]);
```

参考: `modules/dev/node.nix`, `modules/shell/zsh.nix`

### 模式 2: if-then-else 表达式

适用于两个平台配置差异较大的场景。

```nix
config = mkIf cfg.enable (
  if pkgs.stdenv.isDarwin then {
    # Darwin 完整配置
    environment.variables = { ... };
  } else {
    # Linux 完整配置
    environment.sessionVariables = { ... };
  }
);
```

参考: `modules/dev/java.nix`, `modules/xdg.nix`

### 模式 3: 组合条件

适用于需要多层条件检查的场景。

```nix
config = mkIf (cfg.enable && pkgs.stdenv.isLinux) {
  # 仅在启用且为 Linux 时应用
  virtualisation.docker.enable = true;
};
```

参考: `modules/services/docker.nix`

---

## 环境变量设置

### 使用 mkEnvVars 辅助函数

项目提供了统一的环境变量设置辅助函数（`lib/options.nix`）：

```nix
{ hey, pkgs, ... }:

with hey.lib;

config = mkMerge [
  # 其他配置...
  
  # 使用辅助函数设置环境变量
  (mkEnvVars pkgs {
    NPM_CONFIG_PREFIX = "$HOME/.npm";
    NODE_PATH = "$HOME/.npm/lib/node_modules";
  })
];
```

**工作原理**:
- **Darwin**: 使用 `environment.variables`
- **Linux**: 使用 `environment.sessionVariables`

### 手动设置（不推荐，除非有特殊需求）

```nix
config = mkMerge [
  (if pkgs.stdenv.isDarwin then {
    environment.variables.MY_VAR = "value";
  } else {
    environment.sessionVariables.MY_VAR = "value";
  })
];
```

---

## 包安装

### 标准包安装模式

对于大多数跨平台的包：

```nix
config = mkIf cfg.enable {
  user.packages = with pkgs; [
    git
    vim
    curl
  ];
};
```

### Darwin 需要额外安装到 home.packages

某些情况下 Darwin 需要同时安装到 `home.packages`：

```nix
config = mkIf cfg.enable (mkMerge [
  {
    user.packages = [ pkgs.nodejs ];
  }
  
  (mkIf pkgs.stdenv.isDarwin {
    home.packages = [ pkgs.nodejs ];
  })
]);
```

**注意**: 这种模式在项目中很常见，但可能存在冗余。需要进一步验证是否必要。

### 平台专用包

某些包只在特定平台可用：

```nix
user.packages = with pkgs; [
  git
  vim
] ++ lib.optionals pkgs.stdenv.isLinux [
  # Linux 专用包
  systemd
  at
] ++ lib.optionals pkgs.stdenv.isDarwin [
  # Darwin 专用包
  darwin.apple_sdk.frameworks.Security
];
```

---

## 示例模块

### 完整的跨平台模块示例

```nix
# modules/dev/example.nix
{ hey, lib, config, options, pkgs, ... }:

with lib;
with hey.lib;

let
  cfg = config.modules.dev.example;
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in {
  options.modules.dev.example = {
    enable = mkBoolOpt false;
    xdg.enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable (mkMerge [
    # 通用配置 - 所有平台
    {
      user.packages = with pkgs; [
        example-tool
      ];

      environment.shellAliases = {
        ex = "example-tool";
      };
    }

    # Darwin 特定配置
    (mkIf isDarwin {
      home.packages = with pkgs; [ example-tool ];
      
      # Darwin 上使用 launchd 而非 systemd
      launchd.user.agents.example = {
        script = "example-tool daemon";
        serviceConfig.RunAtLoad = true;
      };
    })

    # Linux 特定配置
    (mkIf isLinux {
      # Linux 上使用 systemd
      systemd.user.services.example = {
        description = "Example Tool Daemon";
        wantedBy = [ "default.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.example-tool}/bin/example-tool daemon";
          Restart = "on-failure";
        };
      };
    })

    # XDG 配置（使用辅助函数）
    (mkIf cfg.xdg.enable (mkEnvVars pkgs {
      EXAMPLE_CONFIG_HOME = "$XDG_CONFIG_HOME/example";
      EXAMPLE_CACHE_DIR = "$XDG_CACHE_HOME/example";
    }))
  ]);
}
```

---

## 测试

### 测试 Darwin 配置

```bash
# 构建 Darwin 配置（在 macOS 上）
nix build .#darwinConfigurations.charlie.system

# 应用配置
darwin-rebuild switch --flake .#charlie
```

### 测试 NixOS 配置

```bash
# 构建 NixOS 配置（在 Linux 上）
nix build .#nixosConfigurations.azar.config.system.build.toplevel

# 应用配置
sudo nixos-rebuild switch --flake .#azar
```

### 跨架构测试

由于架构限制（如 aarch64-darwin 无法原生构建 x86_64-linux），跨平台测试需要：

1. **使用远程构建器**: 配置远程 Linux/macOS 构建机
2. **使用 CI/CD**: GitHub Actions 等自动化测试
3. **使用虚拟机**: QEMU、UTM 等虚拟化工具

### 检查列表

在提交模块前检查：

- [ ] 模块在两个平台上都能成功构建
- [ ] Linux 专用选项包裹在 `isLinux` 检查中
- [ ] Darwin 专用选项包裹在 `isDarwin` 检查中
- [ ] systemd 配置仅在 Linux 上应用
- [ ] 环境变量使用 `mkEnvVars` 或正确的平台条件
- [ ] 包在两个平台上都可用（或使用 `lib.optionals`）

---

## 常见问题

### Q: 为什么 environment.variables 和 environment.sessionVariables 不同？

**A**: 
- `environment.variables`: nix-darwin 上的标准方式，在 shell 初始化时设置
- `environment.sessionVariables`: NixOS/home-manager 的标准方式，通过 PAM 会话设置

这是两个系统的实现差异，使用 `mkEnvVars` 可以自动处理。

### Q: 什么时候应该将整个模块包裹在平台检查中？

**A**: 
- 模块**完全依赖** Linux 特定功能时（如 `security.nix`）
- 模块使用 `boot.*`、`virtualisation.*` 等 NixOS 专用选项时
- 模块主要是 systemd 服务时

否则，使用条件块更灵活。

### Q: 如何处理某个包只在一个平台上可用？

**A**:
```nix
user.packages = with pkgs; [
  common-package
] ++ lib.optionals pkgs.stdenv.isLinux [
  linux-only-package
];
```

### Q: Darwin 配置为什么需要同时设置 user.packages 和 home.packages？

**A**: 这是项目历史原因导致的模式。目前看起来 `home.nix` 已经做了别名处理，这个双重安装可能是冗余的。建议逐步验证并清理。

---

## 参考模块

以下是项目中跨平台处理优秀的模块示例：

- **`modules/xdg.nix`**: 完整的平台分离，使用辅助函数
- **`modules/dev/node.nix`**: 条件配置块，环境变量处理
- **`modules/shell/zsh.nix`**: 包过滤，条件选项
- **`modules/editors/emacs.nix`**: 应用链接，平台特定功能
- **`modules/home.nix`**: Home Manager 集成，别名处理

---

## 贡献

添加新模块时：

1. 参考本指南和示例模块
2. 在两个平台上测试（或使用 CI）
3. 添加注释说明平台特定的部分
4. 保持代码风格一致

---

**最后更新**: 2026-01-18
**维护者**: dotfiles contributors

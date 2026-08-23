# 验证报告: Q4 256K 默认档与 Q6 高精度档

## 当前结论

静态配置与 Q4 工件加载验证通过。运行时迁移等待交互式 sudo 授权：当前 active link 仍指向 Q5，必须先用旧控制命令选择 Q4，才能部署移除 Q5 支持的新 generation。

## 已执行验证

| 验证 | 结果 | 证据 |
| --- | --- | --- |
| Nix 文件解析 | PASS | `nix-instantiate --parse hosts/axiom/modules/qwen.nix >/dev/null` 成功。 |
| 整机配置评估与构建 | PASS | `nix eval .#nixosConfigurations.axiom.config.system.build.toplevel.drvPath --raw` 和 `nix build --no-link .#nixosConfigurations.axiom.config.system.build.toplevel` 成功。 |
| Q5 配置移除 | PASS | `hosts/axiom/modules/qwen.nix` 中没有 Q5/q5 引用。 |
| 生成 launcher | PASS | Q4 分支为 262144/Q8/`--n-gpu-layers all`；Q6 分支为 131072/Q4/`--n-gpu-layers all`；只有 Q4/Q6 固定 target。 |
| Q4 MTP 工件 | PASS | SHA-256 为 `5df52200763806fad5c01add7b1be13e9ef96dd1932a41226632693aac321b7b`；CPU-only llama.cpp MTP 加载成功。 |
| 差异卫生 | PASS | `git diff --check` 成功。 |

## 待完成运行时验证

| 验证 | 状态 | 前置条件 |
| --- | --- | --- |
| 旧 generation 切至 Q4 | BLOCKED | 在交互式终端运行 `qwen-model q4`；旧控制命令失败时会恢复 Q5。 |
| 激活 Q4/Q6-only generation | BLOCKED | 旧命令确认 Q4 healthy 后，从此 worktree 运行 `sudo nixos-rebuild switch --flake .#axiom`。 |
| Q4 全 GPU 256K API/吞吐 | BLOCKED | 依赖新 generation 已激活。 |
| Q6 128K fallback | BLOCKED | 依赖新 generation 已激活。 |
| 删除 Q5 工件 | BLOCKED | 依赖 Q4 与 Q6 均通过运行时验证。 |

## 选择理由

完整 NixOS build 与生成 launcher 检查直接验证 profile 绑定和 Q5 控制面删除。CPU-only MTP load 验证 Q4 工件格式可被当前 llama.cpp 解析。它们不能替代单 GPU、桌面负载下的容量和吞吐证据，因此保留运行时验收门。

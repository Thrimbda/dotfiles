# 验证报告: Q4 256K 默认档与 Q6 高精度档

## 当前结论

静态配置、Q4/Q6 运行时 profile 与 Q5 删除均通过。Q4 是当前 active 的全 GPU 256K/Q8 默认档，Q6 是已验证的 128K/Q4 fallback 档。

## 已执行验证

| 验证 | 结果 | 证据 |
| --- | --- | --- |
| Nix 文件解析 | PASS | `nix-instantiate --parse hosts/axiom/modules/qwen.nix >/dev/null` 成功。 |
| 整机配置评估与构建 | PASS | `nix eval .#nixosConfigurations.axiom.config.system.build.toplevel.drvPath --raw` 和 `nix build --no-link .#nixosConfigurations.axiom.config.system.build.toplevel` 成功。 |
| Q5 配置移除 | PASS | `hosts/axiom/modules/qwen.nix` 中没有 Q5/q5 引用。 |
| 生成 launcher | PASS | Q4 分支为 262144/Q8/`--n-gpu-layers all`；Q6 分支为 131072/Q4/`--n-gpu-layers all`；只有 Q4/Q6 固定 target。 |
| Q4 MTP 工件 | PASS | SHA-256 为 `5df52200763806fad5c01add7b1be13e9ef96dd1932a41226632693aac321b7b`；CPU-only llama.cpp MTP 加载成功。 |
| Q4 migration 与新 generation | PASS | 先用旧控制命令成功切至 Q4，再从本 worktree 执行 `sudo nixos-rebuild switch --flake .#axiom`；新 Q4/Q6-only generation 成功激活。 |
| Q4 256K/Q8 全 GPU profile | PASS | `qwen-model status` 报告 Q4 selected、service active、health ok；启动日志报告 `n_ctx_slot = 262144`；实际命令含 Q8 K/V cache 和 `--n-gpu-layers all`。 |
| Q4 长生成吞吐 | PASS | 1024-token API 生成达到 107.91 tok/s；GPU SM 持续 96-97%、功耗约 500W，CPU 平均 31.6%（约单核），消除了 Q5 混合推理瓶颈。 |
| Q6 fallback | PASS | 交互式 `qwen-model q6` 报告 selected q6、service active、health ok；启动日志确认 `n_ctx_slot = 131072`。 |
| Q4 恢复 | PASS | 后续 `qwen-model q4` 报告 selected q4、service active、health ok；启动日志再次确认 `n_ctx_slot = 262144`。 |
| Q5 控制面删除 | PASS | `qwen-model q5` 仅返回 Q4/Q6 的 usage；Nix 源和生成 launcher 均不包含 Q5 target。 |
| Q5 工件删除 | PASS | 模型目录仅保留 `RVN-Q4_K_M-mtp.gguf`、`RVN-Q6_K-mtp.gguf`、模板与 active link。 |
| 差异卫生 | PASS | `git diff --check` 成功。 |

## 已知边界

- Q4 256K/Q8 在当前桌面负载下使用约 30,970 MiB / 32,607 MiB GPU 显存；保持一个并行 slot，增加并发前必须重新做容量验证。
- `--n-gpu-layers all` 触发的 `common_fit_params` warning 只是说明 llama.cpp 不会自动收缩用户强制的配置；Q4/Q6 随后均完整加载并通过运行时验证。

## 选择理由

完整 NixOS build 与生成 launcher 检查直接验证 profile 绑定和 Q5 控制面删除。CPU-only MTP load 验证 Q4 工件格式可被当前 llama.cpp 解析。它们不能替代单 GPU、桌面负载下的容量和吞吐证据，因此保留运行时验收门。

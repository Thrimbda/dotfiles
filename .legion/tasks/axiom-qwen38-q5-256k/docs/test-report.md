# 验证报告: Q5 默认模型与 256K 上下文

## 结论

配置构建和生成启动器验证通过。Q5 修复版已通过 CPU-only 实际加载；实际 NixOS Q5 服务启动仍需在交互式终端执行，因为当前会话没有可用的 sudo TTY。

## 已执行验证

| 验证 | 结果 | 证据 |
| --- | --- | --- |
| Nix 文件解析 | PASS | `nix-instantiate --parse hosts/axiom/modules/qwen.nix >/dev/null` 成功。 |
| 服务配置评估 | PASS | `nix eval .#nixosConfigurations.axiom.config.systemd.services.qwen3-8-27b.serviceConfig.ExecStart --raw` 返回 `qwen-launcher`。 |
| 整机配置评估 | PASS | `nix eval .#nixosConfigurations.axiom.config.system.build.toplevel.drvPath --raw` 返回 Axiom system derivation。 |
| 整机构建 | PASS | `nix build --no-link .#nixosConfigurations.axiom.config.system.build.toplevel` 成功，生成 qwen launcher、model control 和 unit。 |
| 生成启动器 | PASS | 已实现的 `qwen-launcher` 通过 `bash -n`；Q4/Q5 分支包含 `--ctx-size 262144 --cache-type-k q8_0 --cache-type-v q8_0`，Q6 分支保留 131072/Q4。 |
| Q5 旧工件诊断 | FAIL | revision `51b0712` 的文件虽与发布 SHA-256 `ce340152...d71245b` 一致，但 llama.cpp 报 `invalid GGUF type 545038532` 并拒绝加载。 |
| Q5 修复工件 | PASS | revision `3d0bfd5` 的文件已原子替换，大小 19,682,419,936 bytes，SHA-256 为 `ef6c307c53da1e0a577b27df0b636c2818880aabe5c132f423a404e36b391365`。 |
| Q5 CPU-only MTP 加载 | PASS | `llama-cli --model RVN-Q5_K_M-mtp.gguf --ctx-size 64 --n-gpu-layers 0 --no-warmup --spec-type draft-mtp --spec-draft-n-max 2 --single-turn --prompt ok --n-predict 1` 成功加载并退出。 |
| 当前生产服务基线 | PASS | `systemctl is-active qwen3-8-27b.service` 返回 `active`，`curl --fail --silent --show-error --max-time 5 http://127.0.0.1:8081/health` 返回 `{"status":"ok"}`。 |
| 差异卫生 | PASS | `git diff --check` 成功。 |

## 未执行验证

| 验证 | 状态 | 原因与恢复条件 |
| --- | --- | --- |
| `nixos-rebuild switch --flake .#axiom` | BLOCKED | `sudo -n true` 返回“需要密码”；需要在 Axiom 的交互式终端完成授权。 |
| `qwen-model q5`、Q5 health/API 和 GPU 显存 | BLOCKED | 以旧工件切换时已自动恢复 Q6；修复版文件已就位。当前 agent 会话的 `qwen-model q5` 因无 sudo TTY 未执行重启。请在交互式终端执行；它会在启动或 health check 失败时自动恢复前一模型。 |
| Q6 回滚实测 | BLOCKED | 在 Q5 验证完成或失败后，执行 `qwen-model q6` 并检查 health endpoint。 |

## 选择理由

完整 NixOS build 同时验证 Nix 表达式、生成的 systemd unit、`qwen-model` 和 launcher，证明力高于只做文本搜索。检查生成 launcher 则直接证明模型选择与 profile 的绑定关系。运行中的现有服务 health check 仅作为部署前基线，不替代新 generation 的验收。

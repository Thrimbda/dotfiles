# 验证报告: Q5 默认模型与 256K 上下文

## 结论

配置构建、部署和运行时验证均通过。Q5 使用原生 262144-token 上下文和 Q8 KV cache 正常运行。

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
| 全 GPU 容量诊断 | FAIL（已修复） | Q5 使用 262K/Q8 时，`--n-gpu-layers all` 触发 `failed to fit params to free device memory: n_gpu_layers already set by user to -2`，尚未加载权重即退出。 |
| 自动 offload launcher | PASS | 完整 NixOS build 成功；生成的 Q5/Q4 launcher 保留 262K/Q8 参数且不再传入 `--n-gpu-layers`，允许 llama.cpp 默认 `--fit` 自动选择可放入 GPU 的层数。 |
| 新 generation 部署与 Q5 选择 | PASS | 在 Axiom 交互式终端部署后，`qwen-model status` 报告 `selected: q5`、`service: active`、`health: ok`。 |
| 256K/Q8 运行时 profile | PASS | 启动日志报告 `n_ctx_slot = 262144`；systemd `ExecStart` 含 `--cache-type-k q8_0 --cache-type-v q8_0`，且没有 `--n-gpu-layers`。 |
| GPU 和系统内存 | PASS | `nvidia-smi` 报告 30,665 MiB / 32,607 MiB 已用，余 1,413 MiB；服务 RSS 为 19.8 GiB，系统可用内存为 37 GiB。 |
| OpenAI 兼容 API | PASS | `POST /v1/chat/completions` 携带 `reasoning_effort: low` 返回 `READY`，生成速度 40.57 tok/s。 |
| 当前生产服务基线 | PASS | `systemctl is-active qwen3-8-27b.service` 返回 `active`，`curl --fail --silent --show-error --max-time 5 http://127.0.0.1:8081/health` 返回 `{"status":"ok"}`。 |
| 差异卫生 | PASS | `git diff --check` 成功。 |

## 已知边界

- RVN chat template 仅支持 `xhigh`、`medium` 和 `low` reasoning effort；`minimal` 会返回 500。这不是默认服务配置，默认 `medium` 与实测 `low` 均正常。
- Q6 的 131K/Q4 profile 在 Q5 工件失败时由现有自动恢复逻辑成功启动；Q4 profile 未做单独运行时测试。

## 选择理由

完整 NixOS build 同时验证 Nix 表达式、生成的 systemd unit、`qwen-model` 和 launcher，证明力高于只做文本搜索。检查生成 launcher 则直接证明模型选择与 profile 的绑定关系。运行中的现有服务 health check 仅作为部署前基线，不替代新 generation 的验收。

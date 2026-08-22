# RFC: Q5 默认模型与 256K 上下文

## 状态

Draft

## 背景

当前服务以 `RVN-Q6_K-mtp.gguf`、131072 上下文和 Q4 KV cache 运行。运行中的进程占用约 29GB GPU 显存。目标 Q5 MTP 工件为同一 RVN 发布者的 `RVN-Q5_K_M-mtp.gguf`。

Qwen 3.8 27B 原生上下文为 262144 tokens。该模型在 262K 下的 Q8 KV cache 约为 8 GiB。仅把所有档位改为 Q8/262K 会使 Q6 档超过单张 32GB RTX 5090 的可靠容量，因此 Q6 必须保留原有的 128K/Q4 profile 才能作为实际可用的回滚档。

## 选项

### 选项 A: 保留 Q6，统一改为 Q8/262K

不采用。Q6 权重与 262K Q8 KV cache 的组合预计超过可用显存；保留 `qwen-model q6` 命令但让其无法启动不是有效回滚。

### 选项 B: 将默认 Q5 设为 Q8/262K，并为 Q6 保留 128K/Q4 profile

采用。Q5 释放约 3GB 权重显存，用于更大的 Q8 KV cache。启动器根据 `active.gguf` 的固定受控目标选择 profile：Q5 和 Q4 使用 262K/Q8；Q6 维持现有 128K/Q4。这样默认服务满足长上下文目标，且 Q6 可在启动失败时被 `qwen-model` 自动恢复。

### 选项 C: 将默认模型改为 Q4

不采用。可留出更多显存余量，但在本机已可尝试 Q5 的前提下，质量退让没有必要；Q4 仍保留为低显存回滚档。

## 决策与边界

- 使用 RVN 修复 revision `3d0bfd507a4451ec83da4cdf641f8f251b6768fb` 的 `RVN-Q5_K_M-mtp.gguf`，并在切换前验证 SHA-256 `ef6c307c53da1e0a577b27df0b636c2818880aabe5c132f423a404e36b391365`。
- 在 Nix 模块中新增固定的 Q5 路径，缺省 `active.gguf` 仅在尚未存在时指向 Q5。
- 扩展 `qwen-model` 状态识别、选择命令和 usage 文本以支持 Q5；仅接受 Q4、Q5、Q6 三个固定文件路径。
- 将 `llama-server` 的启动改为受控 launcher。Q5 与 Q4 使用 `--ctx-size 262144 --cache-type-k q8_0 --cache-type-v q8_0`；Q6 使用当前的 131072/Q4 profile。
- 不改变服务端口、API 别名、聊天模板、MTP 参数或模型控制命令的原子切换/失败恢复语义。

## 验证与回滚

1. 对修改后的 Nix 配置执行评估，确认 launcher 生成的参数和 `qwen-model` 三个固定目标正确。
2. 部署到 Axiom 后，执行 `qwen-model q5`；该命令在启动或 health check 失败时应恢复到前一有效目标。
3. 通过 `/health`、`qwen-model status`、systemd `ExecStart` 和 `nvidia-smi` 确认 Q5 使用 Q8/262K profile 且没有 GPU OOM。
4. 发起 API 生成请求；若启动、健康或生成失败，执行 `qwen-model q6` 恢复此前的 Q6/128K/Q4 profile。

## 风险

- Q5 256K/Q8 的预计空闲显存很小，最终是否可用以实际启动后的 GPU 用量为准。
- 较早 revision `51b0712` 的 Q5 MTP 工件虽然通过其发布的 SHA-256 校验，但 llama.cpp 在 GGUF metadata 解析时拒绝它；不得重新使用。修复版工件大小为 19,682,419,936 bytes，且已通过 CPU-only MTP 加载验证。
- Q6 是回滚档而非 256K 档。其 128K/Q4 profile 是为保证单卡可启动而保留的容量限制。

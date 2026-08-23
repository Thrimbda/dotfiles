# 交付摘要: Q5 默认模型与 256K 上下文

## Mode

implementation

## 交付结果

- Axiom 的默认 Qwen 模型选择现在包含固定的 Q4、Q5、Q6 目标；未初始化时选择 Q5。
- Q5/Q4 使用原生 262144-token 上下文和 Q8 K/V cache；Q6 保持已验证的 131072-token/Q4 cache 回滚 profile。
- launcher 不再强制全部权重进入 GPU，交由 llama.cpp 默认 `--fit` 在保留长上下文 KV cache 的前提下决定 GPU offload。
- 已替换上游无法解析的 Q5 MTP 文件，修复版 SHA-256 为 `ef6c307c53da1e0a577b27df0b636c2818880aabe5c132f423a404e36b391365`。

## 运行时证据

- `qwen-model status` 报告 Q5 已选中、服务 active、health ok。
- 启动日志确认 `n_ctx_slot = 262144`；实际命令包含 Q8 K/V cache 且没有 `--n-gpu-layers`。
- RTX 5090 使用 30,665 MiB / 32,607 MiB GPU 显存，系统仍有 37 GiB 可用内存。
- OpenAI 兼容 API 使用 `reasoning_effort: low` 返回 `READY`，生成速度 40.57 tok/s。

## 已知边界

- GPU 仅余约 1.4 GiB，不应提高并发或平行 slot 数。
- 当前 RVN chat template 只支持 `xhigh`、`medium` 和 `low` reasoning effort；`minimal` 不受支持。
- Q6 自动回滚已在旧 Q5 工件加载失败时成功触发；Q4 没有单独进行运行时测试。

## 证据索引

- 设计：`docs/rfc.md`
- RFC 审查：`docs/review-rfc.md`
- 验证：`docs/test-report.md`
- 变更审查：`docs/review-change.md`

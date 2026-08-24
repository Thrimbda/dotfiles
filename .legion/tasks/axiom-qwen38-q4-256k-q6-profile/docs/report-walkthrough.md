# 交付摘要: Q4 256K 默认档与 Q6 高精度档

## Mode

implementation

## 交付结果

- Q4_K_M 是默认与 `qwen-model q4` 的全 GPU 262144-token/Q8 KV cache 档。
- Q6_K 保留为 `qwen-model q6` 的全 GPU 131072-token/Q4 KV cache 高精度档。
- Q5 已从 Nix 配置、控制命令、launcher 和本机模型目录移除。
- Q4、Q6 均保持固定文件路径选择和原子 symlink 切换，未引入任意模型路径。

## 性能证据

- Q4 长生成：107.91 tok/s，GPU SM 96-97%，功耗约 500W，CPU 平均约单核。
- 这消除了 Q5 256K profile 的约 30.4 tok/s、12 CPU 核混合推理瓶颈。
- Q4 当前占用约 30,970 MiB / 32,607 MiB GPU 显存，限制为一个并行 slot。

## 运行时证据

- Q4 health、256K startup profile、Q8 cache 和 OpenAI-compatible API 均通过。
- Q6 已实际切换至 128K profile 并 health 通过，随后成功恢复 Q4。
- Q5 命令只返回 Q4/Q6 usage，模型目录中 Q5 文件已不存在。

## 证据索引

- 设计：`docs/rfc.md`
- RFC 审查：`docs/review-rfc.md`
- 验证：`docs/test-report.md`
- 变更审查：`docs/review-change.md`

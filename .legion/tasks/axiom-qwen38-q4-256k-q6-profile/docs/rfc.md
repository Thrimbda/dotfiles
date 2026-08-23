# RFC: Q4 256K 默认档与 Q6 高精度档

## 状态

Draft

## 背景

Q5 的 262144-token/Q8 profile 已可启动，但 llama.cpp 必须将部分权重置于 CPU，实测 1024-token 长生成约 30.4 tok/s，CPU 约占用 12 个核，GPU SM 通常仅 13-48%。当前服务仍选择 Q5。

本机已有 Q4 MTP 工件（16,998,720,736 bytes，SHA-256 `5df52200763806fad5c01add7b1be13e9ef96dd1932a41226632693aac321b7b`）和 Q6 MTP 工件。用户要求使用 Q4 作为高速 256K 档，保留 Q6 作为高精度 128K 档，并移除 Q5。

## 选项

### 选项 A: Q4 256K/Q8 全 GPU，Q6 128K/Q4 全 GPU

采用。Q4 较 Q5 释放足够的模型显存，使 262K Q8 KV cache 与桌面负载可尝试全 GPU offload。Q6 保留其原有的 128K/Q4 cache profile，作为高精度且可全 GPU 的受控选择。

### 选项 B: 保留 Q5 256K 混合推理

不采用。它保持较高权重精度，但已实测 CPU 成为生成瓶颈，GPU 计算资源没有被充分利用。

### 选项 C: Q6 也改为 256K/Q8

不采用。Q6 权重加 256K Q8 KV cache 在单张 32GB RTX 5090 上没有可靠的全 GPU 容量，重现 Q5 的混合推理问题。

## 决策与迁移

- Q4 profile 固定为 `--ctx-size 262144 --cache-type-k q8_0 --cache-type-v q8_0 --n-gpu-layers all`。
- Q6 profile 固定为 `--ctx-size 131072 --cache-type-k q4_0 --cache-type-v q4_0 --n-gpu-layers all`。
- 移除 Q5 路径、`qwen-model q5`、状态识别和 launcher 分支；缺省链接目标改为 Q4。
- 当前 active link 指向 Q5。部署删除 Q5 支持的新 generation 前，必须用已部署的控制命令选择 Q4 并确认健康，确保新 launcher 启动时只会看到支持的 Q4 target。
- 部署新 generation 后先验证 Q4，再切换 Q6 并验证 fallback，最后返回 Q4。只有此时才删除 Q5 工件。

## 验证与回滚

1. 对 Q4 执行 CPU-only llama.cpp MTP 加载；检查 Nix 解析、整机构建和生成 launcher 参数。
2. 用当前控制命令选择 Q4，检查 health endpoint；失败时它自动恢复当前 Q5。
3. 激活新 generation，确认 Q4 启动日志报告 262144 context、Q8 cache 与全 GPU layers；采样 API 生成的 GPU SM、CPU 使用和 tok/s。
4. 执行 `qwen-model q6` 并检查 131072/Q4 与 health，再返回 Q4。
5. 删除 Q5 文件，确认 `qwen-model q5` 不再是可用命令、模型目录中不存在 Q5 工件。
6. 若 Q4 全 GPU OOM 或 API 失败，在 Q5 删除前使用当前/新控制命令切换 Q6；删除后 Q6 是唯一高精度回滚档。

## 风险

- Q4 的 256K/Q8 全 GPU profile 仍可能受桌面应用显存波动影响；保持一个并行 slot。
- 删除 Q5 是不可逆的本地文件操作，但不会影响 Q4/Q6 文件或模型控制的原子恢复机制。
- Q4 与 Q6 的性能比较必须以实际 API 请求期间的 GPU 与 CPU 样本为准，不能从空闲 `GPU-Util` 推导。

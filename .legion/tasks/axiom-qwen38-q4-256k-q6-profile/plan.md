# Axiom Qwen Q4 256K 与 Q6 档位

## 目标

将 Axiom 默认 Qwen 部署改为全 GPU 的 Q4_K_M、262144-token、Q8 KV cache 档位，同时保留 Q6_K 的全 GPU 128K/Q4 cache 高精度档，并移除 Q5。

## 问题陈述

Q5 256K/Q8 在单张 32GB RTX 5090 上需要 CPU/GPU 混合推理，实测仅约 30 tok/s 且 GPU SM 利用率偏低。

## 验收标准

- [x] 默认模型与 qwen-model q4 使用 Q4_K_M MTP、262144 context、Q8 K/V cache 和全 GPU offload。
- [x] qwen-model q6 使用 Q6_K MTP、131072 context、Q4 K/V cache 和全 GPU offload。
- [x] Q5 不再出现在 Nix 配置、模型控制命令、运行时可选目标或模型目录。
- [x] Q4 API 生成、health endpoint、256K 启动 profile、GPU 显存与吞吐均在 Axiom 实测通过。
- [x] Q6 fallback 启动和 health endpoint 实测通过。

## 假设 / 约束 / 风险

- **假设**: 现有 RVN-Q4_K_M-mtp.gguf 已可被 llama.cpp 加载。
- **假设**: Q4 权重加 256K Q8 KV cache 可与桌面工作负载共同放入 32GB RTX 5090。
- **约束**: 仅改动 Axiom Qwen 配置、此任务文档和相关 wiki。
- **约束**: Q4/Q6 只能通过固定受控路径选择；不接受任意模型路径。
- **约束**: 在 Q4 已验证前不得删除 Q5 模型工件。
- **约束**: 不在 Acorn 执行任何 Nix build 或 deployment。
- **风险**: Q4 256K 全 GPU 可能因桌面显存占用而 OOM。
- **风险**: 模型切换和 deployment 会短暂中断本地 API。
- **风险**: 删除 Q5 后仅能通过 Q4/Q6 恢复，必须先验证两档服务。

## 要点

- Q4_K_M
- Q6_K
- 262144 context
- full GPU
- Q5 removal

## 范围

- hosts/axiom/modules/qwen.nix
- .legion/tasks/axiom-qwen38-q4-256k-q6-profile/
- .legion/wiki/
- /home/c1/.local/share/models/qwen3.8-27b/RVN-Q5_K_M-mtp.gguf

## 设计索引 (Design Index)

> **Design Source of Truth**: .legion/tasks/axiom-qwen38-q4-256k-q6-profile/docs/rfc.md

**摘要**:
- Q4 和 Q6 各自采用固定缓存/上下文/GPU layer profile；Q4 是 256K 默认档，Q6 是 128K 高精度档。
- 部署前先使用当前受控命令切换并验证 Q4，成功后再激活删除 Q5 支持的新 generation。
- 在两档运行时验证后删除 Q5 工件，释放本地磁盘。

## 阶段概览

1. **设计与审查** - 确认 Q4/Q6 profile、迁移顺序与 Q5 删除回滚边界
2. **实现** - 更新模型选择、全 GPU profile 与 Q5 清理配置
3. **验证与交付** - 部署并验证 Q4/Q6 profile、吞吐和 Q5 删除

---

*创建于: 2026-08-23 | 最后更新: 2026-08-23*

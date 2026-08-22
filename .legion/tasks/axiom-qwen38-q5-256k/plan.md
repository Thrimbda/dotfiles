# Axiom Qwen Q5 256K 配置

## 目标

将 Axiom 上的 Qwen 3.8 27B 默认部署切换为 Q5_K_M 权重、Q8 KV cache 和原生 262144 token 上下文。

## 问题陈述

现有服务使用 Q6_K、Q4 KV cache 和 131072 token 上下文，无法为稳定的 256K 长上下文运行保留足够显存余量。

## 验收标准

- [ ] 默认 active.gguf 在未显式选择模型时指向 Q5_K_M MTP 工件。
- [ ] qwen-model 支持受控地选择 Q4、Q5 或 Q6，并能报告 Q5 选择状态。
- [ ] llama-server 使用 --ctx-size 262144 与 K/V 均为 q8_0 的 KV cache。
- [ ] Nix 评估通过；部署后服务健康且全量 GPU 配置可启动。

## 假设 / 约束 / 风险

- **假设**: Q5_K_M MTP GGUF 与现有 Q4/Q6 文件位于同一模型目录。
- **假设**: 单 RTX 5090 32GB 的 Q5_K_M 加 Q8 KV cache 可容纳 262144 token 上下文。
- **约束**: 仅修改 Axiom 的 Qwen 配置和任务交付文档。
- **约束**: 保留 Q4/Q6 作为可回滚的受控选择，不接受任意模型路径。
- **约束**: 不在 Acorn 上执行任何 Nix build 或 deployment。
- **风险**: Q5 工件缺失或完整 262144 token KV allocation 超出可用显存，导致服务启动失败。
- **风险**: 切换后 API 服务会在 systemd 重启期间短暂不可用。

## 要点

- Q5_K_M
- Q8 KV cache
- 262144 context
- rollback

## 范围

- hosts/axiom/modules/qwen.nix
- .legion/tasks/axiom-qwen38-q5-256k/

## 设计索引 (Design Index)

> **Design Source of Truth**: .legion/tasks/axiom-qwen38-q5-256k/docs/rfc.md

**摘要**:
- 保留单一 active.gguf 选择点，将默认种子和固定目标控制命令扩展为 Q5。
- 使用 Q8 K/V KV cache 释放长上下文显存，并保留 Q4/Q6 作为回滚选项。
- 先做 Nix 评估，再部署并通过 health endpoint 和 GPU 内存检查验证。

## 阶段概览

1. **设计与审查** - 记录模型、缓存与上下文切换的设计、内存风险及回滚方案
2. **实现** - 更新 Qwen 模型选择与 llama-server 参数
3. **验证与交付** - 评估、部署并验证服务健康、模型选择和 GPU 余量

---

*创建于: 2026-08-22 | 最后更新: 2026-08-22*

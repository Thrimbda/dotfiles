# Axiom Qwen Q5 256K 配置 - 日志

## 会话进展 (2026-08-22)

### ✅ 已完成

- 完成 Q5/Q8/262K profile 实现、Q5 MTP 工件下载和完整 NixOS system build。
- 确认旧 Q5 MTP revision 的上游文件无法被 llama.cpp 解析，下载并原子替换修复 revision 3d0bfd5。
- 修复版通过 SHA-256 和 CPU-only MTP 实际加载验证。
- 定位 Q5 256K/Q8 启动失败为强制全 GPU offload，而非模型文件或 KV cache 参数错误。
- 移除 --n-gpu-layers all，构建并检查使用 llama.cpp 默认 --fit 的新 launcher。
- Q5 修复工件、256K/Q8 profile 和自动 GPU fit 已在 Axiom 部署并验证。
- 确认 Q5 selected、262144 context、health endpoint、OpenAI API 和 GPU/系统内存用量。
- 完成变更审查、交付摘要和 wiki writeback。

(暂无)
### 🟡 进行中

- 初始化任务日志。
- 等待有交互式 sudo 授权的部署和运行时验收。
- 等待交互式 qwen-model q5 切换并验证 GPU 运行时。
- 等待部署自动 offload generation 并实测 Q5 GPU 层数、显存和 API。
- 等待 PR #199 结束生命周期。
### ⚠️ 阻塞/待定

- 当前会话的 sudo 需要密码，无法激活新的 NixOS generation 或切换到 Q5。
- 当前 agent 会话无 sudo TTY，无法替用户重启 systemd 服务。
- 当前 agent 会话无 sudo TTY，无法替用户激活新的 generation。

(暂无)
---

## 关键文件

(暂无)
---

## 关键决策

| 决策 | 原因 | 替代方案 | 日期 |
|------|------|----------|------|
| (暂无) | - | - | - |
---

## 快速交接

**下次继续从这里开始：**

1. 将 Draft PR #199 标记为 ready，尝试 auto-merge，并跟进 PR 终态。

**注意事项：**

- Live Q5 profile: 30,665 MiB / 32,607 MiB GPU memory, 40.57 tok/s API generation with reasoning_effort=low。
- PR: https://github.com/Thrimbda/dotfiles/pull/199; state: OPEN draft; no checks reported; no review decision。

(暂无)
(暂无)
(暂无)
---

*最后更新: 2026-08-23 05:25 by Legion CLI*

# Expand Axiom Qwen context to 128K - 日志

## 会话进展 (2026-08-20)

### ✅ 已完成

- Materialized the 128K context contract
- Changed the generated Qwen service context to 131072
- Built the complete Axiom closure
- Recorded partial verification, review PASS, walkthrough, PR body, and active wiki writeback

(暂无)
### 🟡 进行中

- 初始化任务日志。
- Merge and activate the 128K service, then align OpenCode
### ⚠️ 阻塞/待定

(暂无)

(暂无)
---

## 关键文件

- **`hosts/axiom/default.nix`** [completed]
  - 作用: Set the Qwen server context to 131072
  - 备注: Complete Axiom closure builds successfully
---

## 关键决策

| 决策 | 原因 | 替代方案 | 日期 |
|------|------|----------|------|
| Use 131072 without RoPE overrides | The GGUF reports n_ctx_train=262144, so 128K remains model-native while Q4 KV is projected to fit the RTX 5090 | Retain 64K; attempt 256K with likely VRAM overflow | 2026-08-20 |
---

## 快速交接

**下次继续从这里开始：**

1. Commit, rebase, push, and merge the service change
2. Switch Axiom from merged origin/master
3. Verify 128K runtime and GPU capacity
4. Align the global OpenCode context and finish closeout

**注意事项：**

- OpenCode remains at 65536 until the merged service proves 128K capacity
---

*最后更新: 2026-08-20 06:28 by Legion CLI*

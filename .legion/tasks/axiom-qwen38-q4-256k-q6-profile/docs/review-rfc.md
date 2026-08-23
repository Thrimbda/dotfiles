# RFC 审查: Q4 256K 默认档与 Q6 高精度档

## 结论

PASS

## 审查范围

- `.legion/tasks/axiom-qwen38-q4-256k-q6-profile/plan.md`
- `.legion/tasks/axiom-qwen38-q4-256k-q6-profile/docs/rfc.md`
- 当前 `hosts/axiom/modules/qwen.nix` 的受控模型选择与 launcher 行为

## 发现

无阻塞项。

RFC 明确了 Q5 active link 与新 launcher 删除 Q5 支持之间的迁移风险，并要求先用已部署控制命令切换 Q4。Q4/Q6 的上下文、KV cache 和 GPU layer profile 固定且可观测；Q5 删除被放在两档运行时验证之后，Q6 则保留为可用回滚档。

## 实施条件

- Q4 全 GPU 256K 启动必须通过实际 API 生成、GPU SM/显存与 CPU 使用样本验证，而不能只凭 service active 判断。
- Q6 128K fallback 必须在 Q5 删除前完成一次启动与 health 验证。
- 若 Q4 全 GPU 容量不足，不删除 Q5 文件，先恢复 Q6 并回到设计阶段。

# RFC 审查: Q5 默认模型与 256K 上下文

## 结论

PASS

## 审查范围

- `.legion/tasks/axiom-qwen38-q5-256k/plan.md`
- `.legion/tasks/axiom-qwen38-q5-256k/docs/rfc.md`
- `hosts/axiom/modules/qwen.nix` 的当前模型选择、服务启动和失败恢复行为

## 发现

无阻塞项。

RFC 解决了此前“全局提升到 256K/Q8 后 Q6 无法作为可用回滚档”的问题：profile 与固定模型目标绑定，Q6 继续使用已验证的 128K/Q4 参数。Q5 工件缺失、显存余量小和服务重启均有可执行验证及回滚路径。

## 实施条件

- 切换前下载并确认 `RVN-Q5_K_M-mtp.gguf` 存在。
- 启动 Q5 后必须以 health endpoint、一次 API 生成和 `nvidia-smi` 验证；若任何步骤失败，使用 `qwen-model q6` 恢复。
- 不能以“控制命令仍接受 q6”为由跳过 Q6 profile 的实际启动验证。

## 修订审查 (2026-08-23)

PASS

`--n-gpu-layers all` 已被识别为 Q5 256K/Q8 无法启动的直接原因。移除该强制参数并使用 llama.cpp 默认 `--fit` 是最小且可回滚的修复：它不降低上下文或 KV cache 精度，并保留 Q6 的 128K/Q4 回滚 profile。生成 launcher 已验证不再传入该参数；剩余阻塞仅是需要交互式部署后进行运行时验收。

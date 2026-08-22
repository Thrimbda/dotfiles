# 变更审查: Q5 默认模型与 256K 上下文

## 结论

FAIL - 交付验证被部署授权阻塞。

## 阻塞项

1. `hosts/axiom/modules/qwen.nix` 的新 systemd generation 尚未激活，Q5 的 256K/Q8 profile 因此未在 RTX 5090 上实际启动。
   - **原因**: `sudo -n true` 需要交互式密码，当前会话无法执行 `nixos-rebuild switch` 或 `qwen-model q5`。
   - **影响**: 无法证明 32GB VRAM 能稳定容纳 Q5、262144 tokens 和 Q8 KV cache，也无法验收 API 生成与 Q6 自动回滚。
   - **最小解除方式**: 在 Axiom 的交互式终端从此 worktree 执行 `sudo nixos-rebuild switch --flake .#axiom`，随后执行 `qwen-model q5` 并复核 health endpoint、生成请求、`nvidia-smi` 和 `qwen-model q6` 回滚。

## 非阻塞审查结果

- 范围限定为 Qwen 服务模块和任务产物；没有无关代码变更。
- Q5 被纳入固定白名单路径，未扩大 sudo-adjacent model control 的输入面。
- 生成 launcher 将 Q5/Q4 的 256K/Q8 参数与 Q6 的已验证 128K/Q4 profile 分离，避免 Q6 命令成为不可启动的伪回滚。
- Nix 解析、完整 Axiom system build、生成脚本语法和参数分支均通过；详见 `test-report.md`。

## 安全视角

未触发。变更没有引入鉴权、信任边界、密钥或用户可控高权限输入；模型切换仍限制为三个固定本地文件。

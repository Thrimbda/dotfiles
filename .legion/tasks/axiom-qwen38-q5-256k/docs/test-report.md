# 验证报告: Q5 默认模型与 256K 上下文

## 结论

配置构建和生成启动器验证通过。实际 NixOS 切换与 Q5 服务启动尚未执行：当前会话没有非交互式 sudo 权限。

## 已执行验证

| 验证 | 结果 | 证据 |
| --- | --- | --- |
| Nix 文件解析 | PASS | `nix-instantiate --parse hosts/axiom/modules/qwen.nix >/dev/null` 成功。 |
| 服务配置评估 | PASS | `nix eval .#nixosConfigurations.axiom.config.systemd.services.qwen3-8-27b.serviceConfig.ExecStart --raw` 返回 `qwen-launcher`。 |
| 整机配置评估 | PASS | `nix eval .#nixosConfigurations.axiom.config.system.build.toplevel.drvPath --raw` 返回 Axiom system derivation。 |
| 整机构建 | PASS | `nix build --no-link .#nixosConfigurations.axiom.config.system.build.toplevel` 成功，生成 qwen launcher、model control 和 unit。 |
| 生成启动器 | PASS | 已实现的 `qwen-launcher` 通过 `bash -n`；Q4/Q5 分支包含 `--ctx-size 262144 --cache-type-k q8_0 --cache-type-v q8_0`，Q6 分支保留 131072/Q4。 |
| Q5 工件 | PASS | 文件存在，大小 19,230,486,016 bytes，SHA-256 为 `ce34015241702a9258c8cbca64012bf03a05fda919ebd1c6613d88773d71245b`。 |
| 当前生产服务基线 | PASS | `systemctl is-active qwen3-8-27b.service` 返回 `active`，`curl --fail --silent --show-error --max-time 5 http://127.0.0.1:8081/health` 返回 `{"status":"ok"}`。 |
| 差异卫生 | PASS | `git diff --check` 成功。 |

## 未执行验证

| 验证 | 状态 | 原因与恢复条件 |
| --- | --- | --- |
| `nixos-rebuild switch --flake .#axiom` | BLOCKED | `sudo -n true` 返回“需要密码”；需要在 Axiom 的交互式终端完成授权。 |
| `qwen-model q5`、Q5 health/API 和 GPU 显存 | BLOCKED | 依赖新的 NixOS generation 已切换。切换后执行该命令；它会在启动或 health check 失败时自动恢复前一模型。 |
| Q6 回滚实测 | BLOCKED | 在 Q5 验证完成或失败后，执行 `qwen-model q6` 并检查 health endpoint。 |

## 选择理由

完整 NixOS build 同时验证 Nix 表达式、生成的 systemd unit、`qwen-model` 和 launcher，证明力高于只做文本搜索。检查生成 launcher 则直接证明模型选择与 profile 的绑定关系。运行中的现有服务 health check 仅作为部署前基线，不替代新 generation 的验收。

# Acorn vnStat 流量记账：交付审阅指南


## 交付视角与结论

- 交付类型：`implementation`
- Workflow profile：`strict`
- 风险：`high`
- 阶段结论：`PASS`
- 审查状态：`PASS`
- 最终状态：实现、部署、验证和审查均已通过，等待 PR 生命周期完成。

已在 Acorn 启用本地 vnStat 流量记账服务。闭包在 Axiom 构建并远程激活，服务已启动并登记主网卡 ens5，现有公网服务保持运行。

## 人类注意力与当前动作

- 聚合注意力：`skim`
- 当前唯一人类动作：审阅变更和已记录的首次采样限制。
- lifecycle 边界：PR 合并、检查、审查、清理和主工作区刷新仍属于后续 Git 生命周期。
- 停止点：PR 合并、检查、审查、清理和主工作区刷新仍属于后续 Git 生命周期。
- 摘要：首次采样尚未完成；这是新建 vnStat 数据库的预期状态。
- 证据：\.legion/tasks/acorn\-vnstat\-traffic\-accounting/docs/test\-report\.md、\.legion/tasks/acorn\-vnstat\-traffic\-accounting/docs/review\-change\.md


## 未解决的认知状态

当前证据未登记需要单独聚合的未解决 claim。

## 领域验证摘要

当前证据未登记领域或权威 verifier。

## 范围

### 范围内

- 在 hosts/acorn/modules/platform\.nix 中启用 NixOS 原生 vnStat 服务。
- 从 Axiom 构建并远程激活 Acorn 配置。

### 范围外

- 历史流量或按进程流量归因。
- 阿里云计费、带宽、公网服务或防火墙配置变更。

## 证据地图

| 证据 | 类型 | 状态 | locator |
| --- | --- | --- | --- |
| 稳定任务契约 | plan | PASS | \.legion/tasks/acorn\-vnstat\-traffic\-accounting/plan\.md |
| 高风险基础设施设计与回滚方案 | rfc | PASS | \.legion/tasks/acorn\-vnstat\-traffic\-accounting/docs/rfc\.md |
| RFC 设计审查 | review\-rfc | PASS | \.legion/tasks/acorn\-vnstat\-traffic\-accounting/docs/review\-rfc\.md |
| Axiom 构建、远程激活和主机验证 | test\-report | PASS | \.legion/tasks/acorn\-vnstat\-traffic\-accounting/docs/test\-report\.md |
| 实现范围与安全审查 | review\-change | PASS | \.legion/tasks/acorn\-vnstat\-traffic\-accounting/docs/review\-change\.md |

## 交付路径

1. Axiom 本地构建 NixOS 闭包。
2. 远程复制并激活 Acorn 上的新配置。
3. 服务启动并将 ens5 纳入本地计数数据库。

## 变更与决定

- hosts/acorn/modules/platform\.nix：启用 services\.vnstat。

## 验证与审查状态

| 检查 | 状态 | 证据 |
| --- | --- | --- |
| 有效 NixOS 配置将 services\.vnstat\.enable 求值为 true。 | PASS | \.legion/tasks/acorn\-vnstat\-traffic\-accounting/docs/test\-report\.md |
| Axiom 构建和 Acorn 远程激活成功，vnstat\.service 已启动。 | PASS | \.legion/tasks/acorn\-vnstat\-traffic\-accounting/docs/test\-report\.md |
| vnStat 已登记 ens5；新数据库等待第一个采样周期。 | INFO | \.legion/tasks/acorn\-vnstat\-traffic\-accounting/docs/test\-report\.md |

## 风险与限制

- vnStat 无法恢复安装前流量，且仅提供网卡级汇总，不能归因至单一服务。；缓解：将其作为未来账单趋势检测基线；若持续异常，再单独设计进程级或云侧流量归因。
- 刚创建的数据库没有可显示的完整日/月样本。；缓解：保持服务运行，待首个采样周期完成后通过 vnstat \-\-days 和 vnstat \-\-months 查看数据。

## 审阅清单

- [ ] 仅引入本地计数服务，没有新增监听端口、密钥或外部遥测。
- [ ] 新服务和现有公网服务已在远程激活后验证。
- [ ] 密码未写入配置、报告或提交内容。

## 渲染交接

- PR-backed：是
- 状态：`local`
- 说明：报告包含生产主机服务与流量细节；仅保留为本地和受限 PR 评审产物，不发布公开预览。

## 最终状态与下一阶段

- 当前状态：实现、部署、验证和审查均已通过，等待 PR 生命周期完成。
- 下一阶段：提交分支、推送、创建 PR 并按仓库规则处理检查与审查。
- lifecycle 声明：本报告是 PR 输入，不证明 PR 检查、审查、合并、worktree 清理或主工作区刷新已经完成。

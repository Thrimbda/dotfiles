# Aliyun Acorn ECS Deploy

## 目标

把 `hosts/aliyun-acorn` 从现有 QCOW2 image target 推进到可在 Alibaba Cloud ECS 导入和启动的交付路径：本地构建/校验镜像，复用 `~/Work/aliyun-ops` 的凭证安全与 CLI/Terraform 操作约束，形成可执行的上传/导入/实例启动步骤，并在获得明确授权时执行真实云侧变更。

## 问题陈述

`aliyun-acorn` 已经有 NixOS host 与 QCOW2 image flake，但历史记录只完成了本地求值与 dry-run；还缺少面向 Alibaba Cloud 的实际导入路径、资源边界、验证步骤和失败清理方案。直接临场操作 ECS/OSS 容易混入凭证、tfstate、付费资源和 boot-mode/networking 风险，需要先把操作方法从 `~/Work/aliyun-ops` 提炼成本任务的受控流程。

## 验收标准

- [ ] `hosts/aliyun-acorn/image#aliyun-image` 的当前可构建性被验证；如受 builder 限制阻塞，阻塞原因和下一步明确记录。
- [ ] 从 `~/Work/aliyun-ops` 提炼出 Aliyun 凭证、CLI/Terraform、敏感文件和真实云侧 apply 的操作约束，并写入本任务证据。
- [ ] 部署设计覆盖 QCOW2 构建产物、OSS 上传位置、ECS custom image import、UEFI/EFI boot mode、实例网络/安全组、SSH/串口 first boot 验证、回滚和资源清理。
- [ ] 如需要仓库改动，只新增最小的部署文档或辅助脚本；不提交 AccessKeys、Aliyun profile、terraform.tfstate、terraform.tfvars、明文密码或本地云资源导出。
- [ ] 在未获得明确授权前，不执行会创建、修改或删除 Aliyun 付费资源的命令；真实执行命令必须先列出预期资源与清理路径。
- [ ] 完成后提供 reviewer-facing walkthrough、验证报告、review 结论和 wiki writeback。

## 假设 / 约束 / 风险

- **假设**: 本机或可用 builder 可以运行 Nix；如果不能直接实现 x86_64-linux QCOW2，则任务先产出可复现 build/upload/import 流程和明确 blocker。
- **假设**: Aliyun CLI 凭证按 `~/Work/aliyun-ops` 的既有模式由操作者本地配置，不写入 dotfiles 仓库。
- **假设**: 默认优先复用已有 Aliyun region 和运维约束；具体 bucket、VPC、vSwitch、security group、instance type 需要通过本地凭证查询或用户确认。
- **约束**: 遵守 Legion workflow；生产仓库改动在 contract 稳定后进入 `git-worktree-pr` envelope。
- **约束**: 不提交任何云凭证、CLI profile、Terraform state、tfvars、明文密码、镜像大文件或云账号导出。
- **约束**: Aliyun 上的付费资源创建、替换或删除必须显式确认后才能执行。
- **约束**: 优先最小可审计方案；不要把本任务扩展成通用云平台框架或重写 `~/Work/aliyun-ops`。
- **风险**: QCOW2 build 可能依赖 x86_64-linux builder，当前机器未必能实际产出镜像。
- **风险**: ECS 自定义镜像导入对 OSS bucket region、image format、boot mode 和权限有要求，配置错误会导致导入失败或实例无法启动。
- **风险**: 实例网络、安全组或 SSH/cloud-init 配置错误可能造成首启后不可达，需要串口和清理路径。
- **风险**: 真实云操作会产生费用，并可能留下 OSS 对象、自定义镜像、磁盘或 ECS 实例等残留资源。

## 要点

- 推荐路径: 先做 research + RFC，明确命令、资源、回滚和验证，再做最小实现。
- 安全边界: Aliyun 账号凭证只存在操作者本地 profile；任务证据只记录命令形状和非敏感资源约束。
- 验证边界: 本地静态验证和 image build 可在仓库内完成；真实 first boot 只能在 Aliyun ECS 实例上验证。

## Non-goals

- 不在未授权情况下创建、替换或删除 Aliyun 付费资源。
- 不把 AccessKeys、Aliyun CLI profile、Terraform state、tfvars、明文密码、镜像大文件或云账号导出提交进仓库。
- 不重构 `~/Work/aliyun-ops`，该仓库在本任务中只作为只读操作方法来源。
- 不解决 `aliyun-acorn` 上所有后续应用部署或服务迁移问题；本任务聚焦 ECS custom image first boot 闭环。

## 范围

- hosts/aliyun-acorn/README.md - 补充或校正 ECS custom image import/deploy 操作说明。
- hosts/aliyun-acorn/image/ - 验证现有 QCOW2 image target，必要时做最小修正。
- .legion/tasks/aliyun-acorn-ecs-deploy/ - 保存 research、RFC、验证、review、walkthrough 和日志证据。
- ~/Work/aliyun-ops - 只读参考既有 Aliyun 操作方法，不把该仓库作为本任务默认改动范围。

## 设计索引 (Design Index)

> **Design Source of Truth**: .legion/tasks/aliyun-acorn-ecs-deploy/docs/rfc.md（待创建）

**摘要**:
- 核心流程: 构建 QCOW2，上传到 OSS，调用 ECS ImportImage 创建自定义镜像，再用受控网络与安全组启动实例并验证 first boot。
- 验证策略: 先用 Nix eval/build 和文档/脚本静态检查验证仓库变更；真实 Aliyun CLI/Terraform 命令只在凭证和付费资源确认后执行并记录。

## 阶段概览

1. **Contract** - Create stable Legion task contract
2. **Research and Design** - Research dotfiles image target and aliyun-ops operation method
3. **Implementation** - Enter git-worktree-pr envelope
4. **Verification** - Run local Nix and static verification
5. **Review** - Review implementation for scope, security, and operational risk
6. **Delivery** - Produce walkthrough and PR body

---

*创建于: 2026-06-16 | 最后更新: 2026-06-16*

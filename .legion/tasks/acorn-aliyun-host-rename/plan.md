# Acorn Aliyun Host Profile Rename

## 目标

删除旧的 hosts/acorn 主机配置，并让现有 hosts/aliyun-acorn 成为新的 canonical hosts/acorn 与 nixosConfigurations.acorn。

## 问题陈述

仓库同时存在旧 acorn 主机配置和 aliyun-acorn 主机配置。用户要求删掉原有 acorn，并把 aliyun-acorn 改名为 acorn；如果只移动目录而不同步 flake 暴露名、嵌套 image flake、hostName、runbook 和引用，后续构建与部署命令会继续指向旧名称或失效。

## 验收标准

- [ ] 旧 hosts/acorn 的 Azure/开发型配置不再作为 active host profile 存在。
- [ ] 原 hosts/aliyun-acorn 的 NixOS 配置、modules、secrets、image flake 和 runbook 迁移到 hosts/acorn。
- [ ] active Nix 配置暴露为 nixosConfigurations.acorn，目标 hostName 改为 acorn，active source 中不再依赖 nixosConfigurations.aliyun-acorn。
- [ ] 与目标 host profile 直接相关的命令、路径、镜像命名和文档引用更新为 acorn；历史 Legion 记录只在新的收口 wiki 中补充当前真相，不重写历史。
- [ ] 完成可审阅验证，至少覆盖 acorn flake attr 求值、hostName 求值，以及可行的 scoped Nix 构建或 dry-run。

## 假设 / 约束 / 风险

- **假设**: 用户说的 acorn 指 hosts/acorn 与 flake host profile，不包括仓库根目录的 acorn_id_ed25519 key material。
- **假设**: aliyun-acorn 的 Aliyun provider 语义仍然存在，但主机身份名称应改为 acorn。
- **假设**: 不需要在本任务中执行远端部署、DNS 切换、Terraform 迁移或密钥轮换。
- **约束**: 使用 Legion workflow，并在稳定 contract 后进入 git-worktree-pr envelope。
- **约束**: 不查看、解密或重加密 age secret 内容，除非 Nix 结构要求路径移动。
- **约束**: 保持最小正确改动；不顺手重构 unrelated host/module 配置。
- **风险**: mapHosts 会从目录名生成 flake host attr，目录重命名会改变 nixosConfigurations 暴露名。
- **风险**: 嵌套 hosts/acorn/image flake 若仍引用旧 attr 会在镜像构建时失败。
- **风险**: Axiom/frp/nginx 相关引用可能同时表达远端主机身份和 Aliyun provider，错误替换可能造成运维文档混乱。

## 要点

- 采用 rename/cutover 方案，而不是保留兼容 alias。
- 旧 acorn 删除和 aliyun-acorn 改名作为同一个 atomic repo change 交付。
- 历史任务记录保持历史语义，只新增当前任务与 wiki 总结。

## 范围

- hosts/acorn/**
- hosts/aliyun-acorn/**
- flake/Nix active references that point to aliyun-acorn or acorn host attrs
- 直接相关的 README/runbook 和 host-to-host references
- .legion/tasks/acorn-aliyun-host-rename/** 与 .legion/wiki/** 收口记录

## 非目标

- 不删除或轮换仓库根目录的 `acorn_id_ed25519` key material。
- 不部署远端主机、不执行 DNS/Terraform/Aliyun API 变更、不迁移运行中数据。
- 不为旧的 `aliyun-acorn` flake attr 保留兼容 alias，除非 RFC/review 发现 active consumer 必须依赖它。
- 不重写历史 `.legion/tasks/**` 记录中的旧任务语境。

## 风险等级

- Medium: 该任务是机械 rename/cutover，但会影响 host profile 暴露名、镜像构建入口和跨主机引用，属于多模块联动配置改动。

## 设计索引 (Design Index)

> **Design Source of Truth**: .legion/tasks/acorn-aliyun-host-rename/docs/rfc.md (待创建)

**摘要**:
- 先用 RFC 明确重命名边界、需要替换的 active references、历史 Legion 文档不回写的边界。
- 实现时以目录级迁移为中心，删除旧 hosts/acorn，再把 hosts/aliyun-acorn 移到 hosts/acorn，并同步 Nix attr/hostName/image/runbook 引用。
- 验证以 Nix flake attr/hostName/image attr 求值和 scoped build/dry-run 为主，远端部署不在本任务内。

## 阶段概览

1. **Contract and RFC** - Materialize stable task contract and short RFC
2. **Implementation** - Rename host profile and update active references
3. **Verification and Review** - Run scoped validation and readiness review
4. **Delivery Writeback** - Produce walkthrough and wiki writeback

---

*创建于: 2026-07-07 | 最后更新: 2026-07-07*

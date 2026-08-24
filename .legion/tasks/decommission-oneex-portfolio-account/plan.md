# Undeploy 1Ex Portfolio Adapter

## 目标

Permanently stop deploying `oneex-portfolio-adapter` on Acorn with the smallest declarative change.

## 问题陈述

The service is currently inactive, but `hosts/acorn/default.nix` still imports its module, so a reboot or later NixOS activation can restore it.

## 验收标准

- [ ] Remove only `./modules/oneex-portfolio-adapter.nix` from the Acorn import list
- [ ] Do not modify 1Exchange, auth-mini, browser state, encrypted secrets, the adapter module, or its package snapshot
- [ ] Validate and build only on Axiom, then activate Acorn with the mandated remote-switch command
- [ ] After activation, the adapter unit, process, port `8090`, and nginx vhost are absent
- [ ] Unrelated critical Acorn services remain active with no new failed unit
- [ ] No secret or credential material is printed, persisted, or committed

## 假设 / 约束 / 风险

- **假设**: The single module import owns the adapter service, nginx vhost, service user, and package evaluation
- **约束**: Make no cleanup change beyond removing that import
- **约束**: Never build or evaluate the Acorn closure on Acorn
- **约束**: Stop on Axiom build, transfer, or activation failure; never fall back to Acorn
- **风险**: The stopped service can restart before final activation if Acorn reboots; recheck it immediately before deployment
- **风险**: Source files, ciphertext, the globally declared runtime age secret, external metadata, DNS, old generations, and store paths intentionally remain

## 要点

- One-line production change removes the complete active deployment boundary.
- Existing inactive state limits the pre-deployment window.
- Runtime checks, not deletion of dormant source artifacts, prove completion.

## 范围

- Remove one import from `hosts/acorn/default.nix`
- Validate on Axiom
- Merge, deploy from Axiom, and verify Acorn runtime state

## 非范围

- Delete the adapter module, package snapshot, encrypted secret file/declaration, or globally generated runtime age secret
- Modify any 1Exchange Fund, source, account, or accounting record
- Read, delete, or rotate auth-mini credentials
- Modify browser state, DNS, Git history, old Nix generations, or store garbage collection

## 设计索引 (Design Index)

> **Design Source of Truth**: `.legion/tasks/decommission-oneex-portfolio-account/docs/rfc.md`

**摘要**:
- Remove the single Acorn import and nothing else.
- Deliver through the isolated PR branch.
- Activate only from Axiom and verify the deployment is absent.

## 阶段概览

1. **Implementation** - Remove the import and validate on Axiom
2. **Delivery** - Merge and activate from Axiom
3. **Closeout** - Verify runtime state and record evidence

---

*创建于: 2026-08-24 | 最后更新: 2026-08-24*

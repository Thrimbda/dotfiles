# Register private 1Ex portfolio Fund

## 目标

Register the deployed 1Ex portfolio adapter as a Custom Account Source and create the user-owned private USD Fund named My Portfolio.

## 问题陈述

The adapter is live and authenticated, but no enabled Custom Account Source or private Fund is registered in 1Ex. Preflight confirms the configured exclusion UUID is unused, so it can become the new Fund ID and prevent recursive valuation without changing Acorn configuration.

## 验收标准

- [x] An enabled user-owned Custom Account Source named 1Ex Portfolio Adapter uses https://1ex-portfolio.0xc1.wang with the adapter derived Bearer header, without committing the header or seed.
- [x] 1Ex local account discovery includes ONEEX_PORTFOLIO/<USER_ID> and exposes the same stable product and position IDs as the direct adapter response.
- [x] A private USD Fund named My Portfolio is bound to that AccountID, is not publicly subscribable, and can sample its full portfolio value.
- [x] The already deployed EXCLUDED_FUND_ID becomes the created Fund ID, and direct adapter positions exclude that Fund to prevent recursion.
- [x] No Acorn configuration update is needed after preflight; no Nix build runs on Acorn for this registration-only path.
- [x] No existing Funds, source credentials, or plaintext secrets are altered or committed.

## 假设 / 约束 / 风险

- **假设**: The authenticated user owns the existing 1Ex portfolio data and may create Custom Account Sources and private Funds.
- **假设**: The deployed adapter can obtain a valid 1Ex session for the configured identity.
- **假设**: My Portfolio is the approved Fund display name.
- **约束**: Do not print or persist the adapter Bearer, Ed25519 seed, user token, or decrypted environment values.
- **约束**: Do not modify existing 1Ex Funds, credentials, or account mappings.
- **约束**: All Acorn builds and activation use the local build host and the mandated remote nixos-rebuild command.
- **风险**: A wrong exclusion ID creates recursive valuation or double counting.
- **风险**: Upstream auth or 1Ex reads can fail transiently and must fail closed.
- **风险**: Creating the source and Fund is an external persistent mutation and requires idempotent inspection and rollback handling.

## 要点

- Reuse the verified-unused deployed exclusion UUID as both the new Fund ID and adapter exclusion ID.
- Register the source only after verifying the deployed exclusion already matches the target Fund ID.
- Keep source and Fund mutations idempotent and verify them through 1Ex unified discovery.

## 范围

- .legion/tasks/register-oneex-portfolio-fund/**
- .legion/wiki/**
- 1Ex Custom Account Source and private Fund records

## 非目标

- Change the adapter's portfolio mapping, bearer derivation, or upstream authentication design.
- Modify, delete, or reprice existing Funds, balances, credentials, or account mappings.
- Create a public Fund, enable subscriptions, or expose the adapter without its bearer boundary.
- Re-encrypt or redeploy the Acorn environment when the existing verified-unused exclusion UUID is sufficient.

## 设计索引 (Design Index)

> **Design Source of Truth**: docs/rfc.md

**摘要**:
- Inspect existing 1Ex sources and Funds first, then reuse the verified-unused deployed exclusion UUID as the private Fund ID.
- Derive the Bearer only in secure runtime memory, then create or reconcile one source plus one private Fund idempotently without changing the Acorn environment.
- Validate discovery, direct/source position equality, Fund sampling, privacy/subscription state, and absence of the Fund ID from the adapter response before delivery.

## 阶段概览

1. **Design and preflight** - Inspect current sources and Funds, fix source/Fund identity, and record rollback
2. **Confirm recursion exclusion** - Verify the deployed exclusion UUID is unused and reserve it as the future Fund ID
3. **Register and validate account source** - Create or reconcile the enabled 1Ex Custom Account Source
4. **Create and validate private Fund** - Create and sample the private USD My Portfolio Fund
5. **Review and delivery** - Record verification, review, wiki, and PR lifecycle evidence

---

*创建于: 2026-08-18 | 最后更新: 2026-08-18*

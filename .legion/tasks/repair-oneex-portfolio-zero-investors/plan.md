# Repair My Portfolio zero-investor NAV

## 目标

Remove the erroneous owner investment accounting state so My Portfolio shows the portfolio value exactly once, has no investors or issued shares, remains private with subscriptions closed, and continues recording trading NAV.

## 问题陈述

My Portfolio currently has an owner investor and initial cash-flow event despite no real investment. The live reducer retains that event as a portfolio-sized total deposit and issued shares beside current Trading NAV, so the Fund page can present two asset-like values for the same portfolio.

## 验收标准

- [x] A redacted live preflight identified the exact erroneous owner-profile and initial-cash-flow events before mutation.
- [x] Only those approved initialization events were removed, in an order that kept the remaining event stream reducible.
- [x] The Fund remains enabled and private with subscription_open=false; self-service investment is unavailable.
- [x] A fresh sample set total assets equal to sampled trading equity with zero active investors, zero issued shares, and zero funding balance.
- [x] No source binding, adapter credential, Fund ID, access grant, settlement, unrelated event, secret, or external money movement changed.

## 假设 / 约束 / 风险

- **假设**: The reported double-like presentation is caused by the previously recorded owner initial cash flow retaining fictitious total deposit and issued-share state beside current Trading NAV; the live event stream must confirm this before deletion.
- **假设**: The Fund remains owner-readable and its Custom Account Source is healthy enough to take a fresh sample.
- **假设**: The user has explicitly approved removal of the erroneous owner profile and initial cash-flow accounting events.
- **约束**: Treat event deletion as a destructive accounting repair: capture a redacted audit snapshot, delete only exact approved event indexes, and stop on any mismatch or failed reducer validation.
- **约束**: The user authorizes repeated read-only source-health checks for transient `502` responses within a bounded execution window. DELETE, Fund upsert, and NAV sample requests remain state-confirmed one-shot operations and are never blindly retried.
- **约束**: Do not create compensating investors, cash flows, shares, settlements, transfers, or replacement Fund/source objects.
- **约束**: Preserve the current trading account, Fund ID, source binding, privacy, adapter credentials, and hourly sampling. Confirm `subscription_open=false`; use a preserving Fund upsert only if a correction is actually needed, never as a no-op write.
- **约束**: Keep authentication material, opaque headers, tokens, and decrypted runtime values out of logs, docs, commits, and PR text.
- **风险**: Deleting the wrong event or using a stale event index can corrupt accounting history or leave the stream unreducible.
- **风险**: A source/NAV failure during the repair can make post-mutation valuation ambiguous. Only the pre-mutation read-only source check may retry; a write response always requires a state read before any further action.
- **风险**: With zero issued shares, 1Exchange intentionally reports unit price 1; the verified viewer metric is the total-assets NAV series, not a per-unit investment price.

## 要点

- The repair must prove the fictitious investor/deposit state and viewer projection from live Fund event state rather than rely only on historical task notes.
- Delete the positive cash-flow event before the owner-profile event, rereading events and statements after each destructive step.
- Confirm the existing Fund configuration keeps subscriptions closed; use the preserving upsert contract only if that setting needs correction.
- Retry only source-position reads while `502` is transient; after a healthy response, re-select current event indexes before the first DELETE.

## 范围

- In scope: live read-only preflight, exact initialization-event deletion, subscription lock assertion, one fresh NAV sample, verification, and delivery evidence.
- Out of scope: source/adapter changes, credential rotation, Fund replacement, historical trading-NAV rewrites, user/owner authorization changes, external investment, settlement, taxation, or any compensating cash-flow/share event.

## 设计索引 (Design Index)

> **Design Source of Truth**: docs/rfc.md

**摘要**:
- Use the live event stream as the authority: proceed only when it contains exactly the known initial owner profile and positive cash-flow artifacts, plus expected trading NAV history.
- Remove the cash flow first, then the profile, preserving reducer validity at each boundary; no automatic retry or broad history rewrite is permitted.
- Confirm the same Fund configuration has subscriptions closed, take a fresh trading sample, and verify one-source total assets plus zero-investor/zero-share state.

## 阶段概览

1. **Design and review** - Document the accounting-repair design and pass high-risk RFC review.
2. **Live preflight** - Capture a redacted live snapshot of Fund configuration, statement, source health, NAV, and event indexes.
3. **Apply bounded repair** - Delete only the approved initial cash-flow and owner-profile events, preserve Fund configuration with subscriptions closed, and take one fresh sample.
4. **Verify and close** - Verify the repaired Fund, perform security/change review, publish walkthrough and wiki evidence, and complete PR lifecycle cleanup.

---

*创建于: 2026-08-21 | 最后更新: 2026-08-21*

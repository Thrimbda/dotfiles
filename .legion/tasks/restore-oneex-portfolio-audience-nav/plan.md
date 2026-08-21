# Restore 1Ex portfolio NAV sampling

## 目标

Restore authenticated adapter sampling and initialize My Portfolio units from the current verified Fund assets.

## 问题陈述

The active adapter mints device tokens for auth.ntnl.io while 1Exchange requires 1ex.ntnl.io, causing the Custom Account Source to return 502. My Portfolio has positive assets but zero issued units, so its unit price remains 1.

## 验收标准

- [ ] The active Acorn binary contains the redirect_uri audience fix and the Custom Account Source positions request returns HTTP 200 with complete positions.
- [ ] A fresh immediate Fund sample succeeds before any accounting write, reports fully priced positions, and establishes the exact current baseline.
- [ ] Exactly one owner initial-investment event issues units from that baseline, followed by a successful immediate sample with unit price derived from Fund assets and issued units.
- [ ] No password, private key, bearer token, decrypted environment value, or opaque source header appears in task artifacts, commits, command output, or PR text.

## 假设 / 约束 / 风险

- **假设**: origin/master already contains the required adapter source fix; the active Acorn closure is stale.
- **假设**: Axiom's missing prior adapter output remains live in its local Nix database and cannot be safely deregistered, so a fresh derivation identity is required.
- **假设**: The Fund remains owner-readable, has positive assets, and has zero current units until initialization.
- **假设**: The user has authorized a current-baseline initialization rather than historical performance backfill.
- **约束**: Never build or evaluate the NixOS closure on Acorn. Deploy only from Axiom with the prescribed remote nixos-rebuild command.
- **约束**: Use a clean dotfiles worktree based on origin/master; retain unrelated main-worktree changes untouched.
- **约束**: Do not write a Fund investor or cash-flow event until a same-run immediate sample confirms the source is healthy.
- **风险**: This crosses an authentication boundary and production deployment path; a mismatched audience must fail closed rather than fall back to another token type.
- **风险**: The initial accounting event is non-idempotent. A failed post-write sample must stop and be treated as an accounting repair decision, not retried blindly.
- **风险**: The current total assets are live and may change between preflight and initialization; only the fresh pre-write sample is a valid baseline.

## 要点

- Deployment-only remediation: the tracked vendor already sends redirect_uri, but the active binary does not. A version-only derivation identity bump forces Axiom to build a fresh output from that vendor source instead of requiring its missing prior output.
- The Fund unit price is total assets divided by total issued units; zero units intentionally project as 1.
- The investor initialization is a controlled financial event, not a source or Fund configuration change.

## 范围

- Redeploy the current dotfiles adapter package from a clean worktree and verify the live binary and source behavior.
- Use a short-lived Acorn runtime session to read Fund state, record one approved owner baseline, and immediately resample.
- Produce task-local design, verification, review, walkthrough, and wiki evidence.
- Out of scope: auth-mini or 1Exchange code changes, credential rotation, Fund/source rebinding, and historical performance backfill.

## 设计索引 (Design Index)

> **Design Source of Truth**: docs/rfc.md

**摘要**:
- Use the existing redirect_uri implementation and a version-only Nix derivation identity bump; do not modify adapter runtime source unless verification proves the tracked vendor is insufficient.
- Treat a successful live source read and immediate Fund sample as hard prerequisites for the one accounting mutation.
- Rollback the deployment through the prior NixOS generation if source verification fails; do not compensate a financial event without an explicit accounting-repair decision.

## 阶段概览

1. **Design and review** - Document the deployment and accounting safety design, then complete RFC review.
2. **Deploy and verify source** - Redeploy the current adapter closure from Axiom and verify the active binary plus custom-source positions path.
3. **Initialize Fund units** - Take a fresh Fund sample, create the approved owner baseline once, and immediately resample.
4. **Closeout** - Run verification, security review, walkthrough, wiki writeback, and PR lifecycle cleanup.

---

*创建于: 2026-08-20 | 最后更新: 2026-08-20*

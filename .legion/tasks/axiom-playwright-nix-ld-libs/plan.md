# Fix Axiom Playwright nix-ld runtime libraries

## 目标

Make Playwright Chromium launch reliably on Axiom when invoked through both the Nix-packaged playwright wrapper and npm/npx-installed Playwright browsers.

## 问题陈述

Axiom runs NixOS. Playwright officially supports Debian/Ubuntu Linux targets, so npm/npx Playwright downloads an Ubuntu fallback browser. That browser bypasses the Nix-packaged playwright wrapper and fails at process startup because nix-ld does not expose libglib-2.0.so.0 and related Chromium runtime libraries.

## 验收标准

- [ ] System playwright can launch Chromium and capture a screenshot.
- [ ] An npm/npx-installed Playwright Chromium can launch with the configured nix-ld runtime libraries.
- [ ] Axiom NixOS configuration evaluates and plans a system build successfully.
- [ ] The change is scoped to Playwright runtime support and Legion handoff evidence.

## 假设 / 约束 / 风险

- **假设**: Axiom keeps modules.dev.playwright.enable = true.
- **假设**: NixOS nix-ld remains enabled by the shared dotfiles base configuration.
- **假设**: npx Playwright users may continue to use browser caches under ~/.cache/ms-playwright, so nix-ld library exposure is still useful in addition to the Nix playwright wrapper.
- **约束**: Do not replace the Nix-packaged playwright-test wrapper or pin npm Playwright versions globally.
- **约束**: Do not broaden the task into browser cache cleanup, Node/npm policy changes, or full Playwright version upgrades.
- **约束**: Keep the fix local to the Playwright development module where the feature is enabled.
- **风险**: npx Playwright versions can require additional browser libraries in the future.
- **风险**: The host only receives the persistent fix after a nixos-rebuild switch.

## 要点

- The system playwright wrapper already sets PLAYWRIGHT_BROWSERS_PATH to Nix store browsers and works.
- The failing path is npm/npx Playwright launching downloaded Ubuntu fallback Chromium through nix-ld.
- Adding the Chromium runtime libraries to programs.nix-ld.libraries is the minimal persistent NixOS fix.

## 范围

- modules/dev/playwright.nix
- .legion/tasks/axiom-playwright-nix-ld-libs/**
- Non-goal: changing host-specific axiom settings outside enabling the existing Playwright module.
- Non-goal: committing downloaded Playwright browser artifacts or temporary screenshots.

## 设计索引 (Design Index)

> **Design Source of Truth**: docs/rfc.md (design-lite)

**摘要**:
- Use fast-track design-lite because this is a small, reversible Nix module fix with no API, schema, auth, or data migration impact.
- Keep pkgs.playwright-test as the preferred wrapper and add nix-ld runtime libraries for npm/npx fallback browser binaries.
- Verify both Playwright invocation paths plus Nix evaluation/build planning.

## 阶段概览

1. **brainstorm** - Materialize stable task contract
2. **design-lite** - Record minimal design decision
3. **engineer** - Add Playwright runtime libraries to nix-ld
4. **verify-change** - Run Playwright and Nix validation
5. **review-change** - Review readiness and risks
6. **report-walkthrough** - Prepare reviewer handoff
7. **legion-wiki** - Write durable wiki summary

---

*创建于: 2026-06-21 | 最后更新: 2026-06-21*

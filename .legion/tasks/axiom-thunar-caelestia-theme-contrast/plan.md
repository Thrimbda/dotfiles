# Axiom Thunar Caelestia Theme Contrast

## 目标

Align Axiom Thunar/GTK and Fcitx visible theming with the current Caelestia/qtengine direction so file manager text and backgrounds have readable contrast.

## 问题陈述

The live Axiom Thunar window shows a dark header but light content/sidebar surfaces with near-white labels, making file names and navigation entries almost unreadable. Existing wiki conclusions also overfit to an older assumption that Catppuccin assets should be avoided, while the current user intent is to make GTK/Thunar and Fcitx match Caelestia rather than preserve Autumnal/Graphite at all costs.

## 验收标准

- [ ] Axiom declarative configuration selects a GTK theme path that gives Thunar readable text/background contrast and matches the current Caelestia/qtengine direction better than Graphite-pink-Dark.
- [ ] Fcitx visible theme is aligned with the same Caelestia-oriented theme direction where the repository has declarative ownership.
- [ ] Outdated wiki guidance that categorically avoids Catppuccin visible assets is updated or superseded to reflect the new decision.
- [ ] No live nixos-rebuild switch is performed as part of this task.
- [ ] Verification records Nix evaluation/build evidence and any live-session checks that remain post-deploy.

## 假设 / 约束 / 风险

- **假设**: The target host is Axiom and the reported screenshot is from Thunar under the current Caelestia desktop session.
- **假设**: Caelestia/qtengine currently uses a BreezeDark-based Qt direction, so the GTK/Fcitx solution should prefer a matching dark theme rather than patching Thunar text colors in isolation.
- **假设**: Static Nix validation can prove generated configuration and package closure, while final contrast still needs a live graphical session smoke after deployment.
- **约束**: Follow Legion workflow and git-worktree-pr delivery.
- **约束**: Preserve unrelated dirty changes in the main checkout.
- **约束**: Keep the fix declarative and repository-owned; do not edit live user GTK config by hand.
- **约束**: Do not mutate user-private Fcitx dictionaries, Rime data, Thunar bookmarks, or file manager state.
- **风险**: Changing the shared Autumnal GTK theme may affect other GTK applications on hosts using that theme.
- **风险**: Fcitx theme package names and available variants may differ from the intended Caelestia-aligned choice.
- **风险**: Headless validation cannot prove final perceived contrast in Thunar; post-switch visual smoke remains required.

## 要点

- Prefer an upstream maintained dark GTK theme aligned with Caelestia/qtengine over Thunar-specific CSS hacks.
- Make the Fcitx visible theme follow the same current theme decision rather than keeping an old anti-Catppuccin rule.
- Update durable wiki truth so future theme tasks do not inherit stale visual assumptions.

## 范围

- Update Axiom/Autumnal GTK theme selection or related theme module wiring as needed for Thunar readability.
- Update Fcitx visible theme configuration if declaratively owned by this repository.
- Update Legion task artifacts and wiki decisions/patterns for the new theme direction.
- Validate generated Axiom theme attributes, relevant package closure/config, and Axiom toplevel build or dry-run.

## 非目标

- Do not edit live `~/.config/gtk-*`, Thunar, Fcitx, or Rime user state by hand.
- Do not change Thunar behavior, bookmarks, file associations, or file manager features.
- Do not redesign the whole Caelestia shell or qtengine integration beyond the theme consistency issue.
- Do not perform a live `nixos-rebuild switch`; final visual confirmation remains post-deploy work.

## 设计索引 (Design Index)

> **Design Source of Truth**: docs/rfc.md will capture the chosen theme alignment approach before implementation.

**摘要**:
- Treat the screenshot as a theme consistency bug, not a Thunar feature bug.
- Evaluate a minimal theme switch toward the Caelestia/qtengine dark direction first; only add app-specific CSS if package-level theming cannot satisfy contrast.
- Keep live visual confirmation as a post-deploy smoke check and avoid touching private runtime state.

## 阶段概览

1. **Contract Materialization** - Create and review the Legion task contract.
2. **Design Gate** - Write and review a concise RFC for GTK/Thunar and Fcitx theme alignment.
3. **Implementation** - Update theme configuration for Axiom Thunar/GTK and Fcitx contrast alignment.
4. **Verification** - Validate generated configuration and package/build surfaces.
5. **Review And Handoff** - Review readiness, write walkthrough, and update Legion wiki.

---

*创建于: 2026-05-14 | 最后更新: 2026-05-14*

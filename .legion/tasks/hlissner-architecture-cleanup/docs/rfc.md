# RFC: Hlissner-aligned Dotfiles Architecture Cleanup

> **Profile**: RFC Heavy（跨模块架构清理）
> **Status**: Draft
> **Owners**: OpenCode / user
> **Created**: 2026-05-12
> **Last Updated**: 2026-05-12

---

## Executive Summary
- **Problem**: 本仓库继承 hlissner 的轻量 flake/module/host 框架，但 Darwin、Axiom Wayland/Caelestia、host-local services 和历史迁移让边界变厚，后续改动容易重复推理或误改行为。
- **Decision**: 保留现有框架，不迁移 flake-parts/devos；本 PR 只做边界保持的 helper/路径/注释/文档清理。
- **Why now**: 用户要求在学习 hlissner 架构后做一次“完全不影响功能”的清理，并通过 PR 交付但不自动合并。
- **Impact**: 预期减少重复平台/env 发射、消除部分硬编码 home/path、降低 Hyprland/Caelestia 常量漂移和注释噪音。
- **Risks**: `_module.check = false`、Git-backed flake 新文件不可见、generated Hyprland/UWSM text 细微变化、Darwin/Linux env target 差异。
- **Rollout**: 在隔离 worktree 中分小步实现，每个 slice 都配 Nix/static validation。
- **Rollback**: PR 未合并前直接丢弃分支/worktree；合并后通过 revert PR 回滚，无数据迁移或 persistent state migration。

---

## 1. Background / Motivation
当前仓库的上层组织仍是 hlissner 风格：thin `flake.nix`，自制 `lib.mkFlake`，filesystem-discovered `hosts` 和 recursive modules。与上游不同的是，本仓库已扩展 Darwin module set、fallback-friendly flake args、Axiom Hyprland/UWSM/Caelestia 桌面产品、Cloudflare/opencode/autossh host-local 服务，以及 Legion evidence/wiki 层。

直接复制 hlissner 上游代码会破坏当前约束：上游是 Linux-only，依赖 hard `HEYENV`，桌面 baseline 是 DMS/Quickshell/Rofi，而当前真源是 Darwin-safe shared modules + Axiom Caelestia product path。因此本次应复制“组织原则”，不复制“运行时产品”。

## 2. Goals
- 让平台边界、desktop env 常量、host-local path 和 generated config ownership 更清楚。
- 在不改变 public options、host module enablement 和 service behavior 的前提下降低重复。
- 保持 hlissner-style host shape：`modules` 表达意图，`config` 表达 host-local escape hatch，`hardware` 表达机器事实。
- 产出可 review 的 PR、验证报告、walkthrough 和 wiki writeback。

## 3. Non-goals
- 不迁移到 flake-parts/devos，不重写 `mkFlake`。
- 不替换 Caelestia Shell，不恢复 DMS/Quickshell/end4/Rofi 作为主产品路径。
- 不抽象 Cloudflare Access policy、tunnel、opencode/autossh 为新的通用服务模块，除非后续任务单独设计。
- 不升级 inputs，不改 `flake.lock`，不改 secret recipient/path/content。
- 不做 live deployment，不运行 `switch`，不自动 merge PR。

## 4. Constraints
- **Compatibility**: Existing `modules.*` option names and host `modules = { ... }` intent must remain stable.
- **Security / privacy**: Do not read `token.env` or secret plaintext. Do not change Cloudflare Access, tunnel IDs, SSH reverse ports or credentials paths.
- **Operational**: Implementation must run inside `git-worktree-pr` envelope. PR is created but not automatically merged.
- **Validation**: New files under `modules/` must be named or placed so recursive module discovery does not import helper files as modules.
- **Behavior**: Any intended behavior adjustment, even minor, must be explicitly called out in implementation log and delivery report, and kept only if reviewer/user acceptance is clear before merge.

## 5. Definitions
- **Behavior-preserving cleanup**: Nix-evaluated options, generated service commands, generated Hyprland/UWSM functional lines, host module enablement and secret/service endpoints remain equivalent.
- **Allowed light behavior adjustment**: A small correction discovered during cleanup that is explicitly documented, validated, and left for reviewer/user acceptance before merge, with no expansion of user-facing feature surface.
- **Helper file**: Internal Nix helper skipped by recursive module import, for example by `_` prefix under `modules/`.

---

## 6. Proposed Design

### 6.1 High-level Architecture
Keep the current architecture and clean inside it:
- `flake.nix` remains the thin entrypoint.
- `lib/` remains the custom framework layer.
- `hosts/*/default.nix` keep the `modules` / `config` / `hardware` separation.
- `modules/**` keep public options stable.
- Internal helper extraction is allowed only when it does not become a recursive module and does not change generated outputs.

The cleanup is intentionally split into three implementation slices:
- **Slice A: zero-output cleanup** - remove unused local helpers and stale comments; update task/docs only.
- **Slice B: platform/env boundary cleanup** - use existing platform-aware env helpers where output target remains identical; centralize Wayland/QT constants shared by Hyprland and Caelestia.
- **Slice C: path normalization cleanup** - replace current-user hardcoded home strings with `config.user.home`/derived variables where evaluated values stay identical for the current hosts.

### 6.2 Detailed Design
**Slice A: zero-output cleanup**
- Remove unused local code such as `modules/desktop/default.nix`'s dead `setEnv` binding if still unused at implementation time.
- Remove or refresh stale comment-only noise where it does not carry useful operational context.
- Do not remove historical Legion task evidence; only active source comments/docs are in scope.

**Slice B: platform/env boundary cleanup**
- Prefer `mkEnvVars pkgs <attrs>` for simple Linux/Darwin env target branching already represented by `environment.sessionVariables` vs `environment.variables`.
- Introduce at most one internal helper for desktop env constants, e.g. `_env.nix` under a `_`-prefixed path or filename, so `mapModulesRec'` skips it.
- The helper may expose data such as:
  - Wayland session vars: `ELECTRON_OZONE_PLATFORM_HINT`, `NIXOS_OZONE_WL`, `MOZ_ENABLE_WAYLAND`.
  - Caelestia/Qt vars: `QT_QPA_PLATFORM`, `QT_QPA_PLATFORMTHEME`, `QT_WAYLAND_DISABLE_WINDOWDECORATION`, `QT_AUTO_SCREEN_SCALE_FACTOR`.
- Generated config text should preserve existing file paths and line semantics: `hypr/custom/env.conf`, `hypr/custom/*.conf`, `uwsm/env`, and `caelestia-shell.service` environment.

**Slice C: path normalization cleanup**
- Use `config.user.home` and derived `opencodeDir`/log paths where the evaluated result is identical to current literals.
- Candidate host-local surfaces:
  - Axiom opencode service and autossh service home/working directory.
  - Charlie opencode launchd agent home/working directory/log path.
  - Charlie/Charles/Azar user home references only where exact evaluated equivalence is trivial to prove.
- Do not generalize these into reusable modules in this PR; host-local service shape remains host-local.

---

## 7. Alternatives Considered

### Option A: Documentation/comment-only cleanup
- **Pros**: Lowest risk; easy rollback; almost impossible to change behavior.
- **Cons**: Does not address repeated env/path patterns that currently create maintenance cost.
- **Why not**: Too weak for the user's request to make the codebase cleaner after architecture study.

### Option B: Boundary-preserving helper/path cleanup（chosen）
- **Pros**: Improves real maintainability while preserving current architecture and behavior; can be verified by evaluated config/units/generated text.
- **Cons**: Requires careful helper placement and targeted validation to avoid hidden behavior drift.
- **Why chosen**: Best fit for “cleaner architecture” without changing product direction or enabling new features.

### Option C: Broad architecture extraction into reusable service modules
- **Pros**: Could reduce host-local duplication for opencode/autossh/cloudflared.
- **Cons**: Creates new public module contracts and cross-platform service abstractions; higher risk of changing service semantics/security boundaries.
- **Why not**: Too much behavior and security surface for this PR. Split into future tasks only if repeated use proves the need.

### Option D: Import or emulate hlissner upstream more directly
- **Pros**: Strong alignment with the reference repository.
- **Cons**: Upstream is Linux-only, DMS/Quickshell/Rofi-oriented, and conflicts with current Darwin/Caelestia/Legion constraints.
- **Why not**: Violates current task contract and repo truth.

### Decision
Choose **Option B** with strict scope limits. The implementation should be small enough to review line-by-line and each changed behavior-sensitive string should be evaluable or inspectable.

---

## 8. Migration / Rollout / Rollback

### 8.1 Migration Plan
- No data migration.
- No user state migration.
- No secret migration.
- No host deployment in this task.

### 8.2 Rollout Plan
- Create an isolated worktree/branch.
- Implement slices in order: A, B, C.
- After each behavior-sensitive slice, run targeted static/eval checks before continuing where feasible.
- Create PR and leave it unmerged for review.

### 8.3 Rollback Plan
- Before merge: delete/abandon PR branch/worktree.
- After merge: revert the PR. No persistent schema/state changes require extra rollback steps.
- If validation shows behavior drift not explicitly accepted, revert that slice and keep only preceding safe slices.

---

## 9. Observability
- No new runtime observability is required because this is not a deployed runtime feature.
- Review/debug observability is through generated artifacts:
  - `docs/test-report.md` for commands/results.
  - `docs/review-change.md` for readiness findings.
  - PR diff for exact file changes.
  - Rendered/evaluated generated config or unit snippets where relevant.

---

## 10. Security & Privacy
- Do not read or print secrets.
- Do not touch age secret contents, Cloudflare credentials, Cloudflare Access policies, tunnel IDs, ingress hostnames, opencode bind host/port, or reverse SSH remote ports.
- Path normalization must not broaden permissions or change service users.
- Any service unit/plist path changes must be evaluated for exact equivalence before delivery.

---

## 11. Testing Strategy
- **Static checks**:
  - `git diff --check`
  - targeted grep for forbidden drift: flake inputs/lock, tunnel IDs, secret paths, opencode ports, reverse SSH ports.
- **Nix eval/build**:
  - Evaluate `.#hostMetadata` or equivalent host metadata to confirm host discovery still works.
  - Evaluate/build representative NixOS host `axiom` toplevel when feasible.
  - Evaluate representative Darwin host `charlie` config when feasible in current environment.
- **Generated output checks**:
  - Inspect generated Hyprland env/keybind/workspace/uwsm config text for stable functional lines.
  - Inspect Axiom systemd unit and Charlie launchd plist values for opencode/autossh if path normalization touches them.
- **Manual validation checklist**:
  - Real Axiom Hyprland/Caelestia smoke remains deployment-side: session start, launcher/sidebar, OSD/media/brightness, screenshot/recording, lock, wallpaper, terminal/browser launch.
  - Real Darwin smoke remains deployment-side: shell/env/opencode/launchd/cloudflared if touched.

---

## 12. Milestones
- **Milestone 1: Baseline and zero-output cleanup**
  - Scope: task docs, comments, dead local helpers.
  - Acceptance: no behavior-sensitive Nix expressions changed except deleted unused bindings/comments; `git diff --check` passes.
  - Rollback impact: trivial file revert.
- **Milestone 2: Platform/env helper cleanup**
  - Scope: `default.nix`, `modules/home.nix`, `modules/desktop/default.nix`, `modules/desktop/hyprland.nix`, `modules/desktop/caelestia.nix`, optional internal helper file.
  - Acceptance: env target paths and generated values stay equivalent; no Darwin desktop import; helper file is not recursively imported as a module.
  - Rollback impact: revert helper and call-site changes.
- **Milestone 3: Host path normalization**
  - Scope: host-local literals in `hosts/axiom/default.nix`, `hosts/charlie/default.nix`, optionally `hosts/charles/default.nix` or `hosts/azar/default.nix` if exact-equivalence is clear.
  - Acceptance: evaluated service command/home/log paths remain identical for current hosts.
  - Rollback impact: revert host path changes.
- **Milestone 4: Verification and delivery**
  - Scope: `docs/test-report.md`, `docs/review-change.md`, walkthrough, PR body, wiki writeback.
  - Acceptance: validation evidence and reviewer-facing summary are complete; PR exists and remains unmerged.

---

## 13. Open Questions
- [ ] Final validation commands may be constrained by local Nix resources; record any skipped commands and why in `docs/test-report.md`.

---

## 14. Implementation Notes
- Put internal helper files under `_`-prefixed names/dirs if they live under `modules/`, because `lib/modules.nix` skips `_` entries.
- Prefer small diffs over large moves. Do not move `config/hypr/hyprland.conf` or change generated file paths.
- Do not extract opencode/autossh/cloudflared service modules in this task.
- If a cleanup produces non-equivalent generated text, either document it as an allowed light behavior adjustment for explicit reviewer/user acceptance or revert it.

---

## 15. References
- Plan: `.legion/tasks/hlissner-architecture-cleanup/plan.md`
- Research: `.legion/tasks/hlissner-architecture-cleanup/docs/research.md`
- Current truth: `.legion/wiki/decisions.md`, `.legion/wiki/patterns.md`, `.legion/wiki/maintenance.md`
- Reference clone: `/tmp/opencode/hlissner-dotfiles`

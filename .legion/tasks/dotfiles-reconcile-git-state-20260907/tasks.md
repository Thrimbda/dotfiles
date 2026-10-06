# Dotfiles Git State Reconciliation Tasks

## 当前状态

- Profile：Strict
- 当前阶段：`delivery` — attention: review
- 当前检查项：完成 finalized staged diff检查并创建PR；等待复核后才可merge/cleanup
- 进度：IN PROGRESS

## 阶段 Checklist

1. [x] `brainstorm` — contract 已收敛并落盘。
2. [x] `spec-rfc` — 定义资产分类、远端覆盖、秘密、恢复与处置设计。
3. [x] `review-rfc` — round 1 FAIL 后补齐 Constx 独有事故模式；round 2 PASS / attention: skim。
4. [x] `engineer` — 已构造 Doom完成证据与 archive failure shield 候选；按设计不在 merge 前删除原件。
5. [x] `verify-change` — pre-delivery PASS / attention: review；C4按完整协议延后到merge后cleanup。
6. [x] `review-change` — PASS / attention: review；M1 final staged checks阻塞merge。
7. [~] `delivery` — 准备commit/rebase/push/PR；复核落盘前禁止auto-merge、merge与cleanup。

# Const X Azar Public Deployment Tasks

## 当前状态

- Profile：Strict
- 当前阶段：`verify-change`
- 进度：IN PROGRESS

## 阶段 Checklist

1. [x] `brainstorm` — contract、目标主机、现有入口与权限边界已确认。
2. [x] `spec-rfc` — D-ROOT-001 已决，固定-SHA / generation rollback 已修订。
3. [x] `review-rfc` — 独立 re-review PASS / attention: skim。
4. [x] `engineer` — 已实现范围内的 Nix 配置与发布支持。
5. [~] `verify-change` — 记录构建、Nix eval、DNS、TLS、运行时和安全验证。
6. [ ] `review-change` — 独立审查范围、认证边界与证据。
7. [ ] `delivery` — PR、merge、远端切换、canary、cleanup、主工作区刷新。

# 验证报告：Azar 原生 Auth Mini 与 auto-redirect release uplift

## 范围与方法

本报告覆盖两层事实：原生 Auth Mini G2 ingress 已部署，以及 source PR #83 (`059eab4d6a8eac156333f9357838d8ab9acc203c`) 的自动 redirect release 已由 Axiom 构建、由 Azar 安装。Azar 不构建 Nix system 或 Const X binary。

所有证据已脱敏：只包含 SHA、unit state、HTTP code、路径和配置性质；不包含 token、cookie、密码、完整 config、age 解密内容或 pairing URL。

## Claim 登记与结果

| Claim | 预注册 | 状态 | 直接证据 |
| --- | --- | --- | --- |
| D1 | objective / now / routine；critical；block-merge；direct ingress 可能公开用户 API、运行错误 binary 或失去 auth config | PASS | [G1 binding](evidence/g1-transition-92112fac.txt) 先证明 gateway hard gate；[G2 raw runtime](evidence/g2-runtime-059eab4.txt) 记录 `ExecStart`/MainPID/proc executable/两次 SHA、config check、auth config、401 与有效 Nginx server block；[manifest](evidence/release-manifest-059eab4.txt) 和 [source provenance](evidence/source-provenance-059eab4.txt) 绑定 source/Axiom/Azar。 |
| D2 | objective / now / routine；high；block-merge；gateway topology collateral outage | PASS | [G2 raw runtime](evidence/g2-runtime-059eab4.txt) 记录 constx gateway inactive、auth-mini/Nginx/其它 gateway active；[Nix eval](evidence/nix-eval-059eab4.txt) 和 [ACME hosts](evidence/acme-hosts-059eab4.txt) 记录 base/staging 形状与单一 host ownership；[public peer record](evidence/public-and-peer-059eab4.txt) 记录本机/Axiom 200/401。 |
| D3 | objective / deferred / routine；critical；defer-by-user-decision；Run Environment machine protocol | DEFERRED | 本机 launchd 与 Axiom user service 均 active；用户明确要求不由本 agent 继续 pairing/Tool Call E2E，而由用户自行观察。未把 service/connection 状态提升为 pair/tool-result PASS。 |
| D4 | objective / deferred / routine；critical；defer-by-user-decision；production Auth Mini passkey/browser | DEFERRED | 用户将在生产域名自行确认直接 redirect、登录、callback 和受保护内容；本 agent 不执行或声明该 E2E PASS。 |

## 执行记录

| 检查 | 结果 | 原始证据 |
| --- | --- | --- |
| Acorn base/staging Nix eval | PASS | [nix-eval-059eab4.txt](evidence/nix-eval-059eab4.txt) |
| Source/Axiom binary/manifest provenance | PASS | [source-provenance-059eab4.txt](evidence/source-provenance-059eab4.txt), [release-manifest-059eab4.txt](evidence/release-manifest-059eab4.txt), [axiom-build-059eab4.txt](evidence/axiom-build-059eab4.txt) |
| G1 gateway hard gate before G2 | PASS | [g1-transition-92112fac.txt](evidence/g1-transition-92112fac.txt) |
| Azar stage, config preflight, G2 switch and runtime binding | PASS | [g2-runtime-059eab4.txt](evidence/g2-runtime-059eab4.txt), [acme-hosts-059eab4.txt](evidence/acme-hosts-059eab4.txt) |
| Public reachability and existing peer service state | PASS / deferred scope | [public-and-peer-059eab4.txt](evidence/public-and-peer-059eab4.txt) |

## 延后验证与回退

`D-20260902-R4` 的 owner 是用户。触发是本 release 已完成 Azar switch；方法是访问 `https://constx.0xc1.wang`，确认无 Continue 中间页、直接进入 issuer、完成登录、callback 回到应用，并确认受保护 API/page。若出现 redirect loop、不能回到应用或仍被拒绝，停止进一步 rollout，将 `releaseSha` 回退为 `92112facdb30a1a3a02e0a31fadcf3ff4a6ea379`，由 Axiom 重新 build 后以同一 switch 路径安装到 Azar。

`D3` 同样保留给用户的实际 temporary pairing / Tool Call / result / revoke 观察；当前 active services 只证明待验证条件仍在，不替代 machine-protocol E2E。

## Verdict

PASS

## 会话注意力摘要

- 阶段：verify-change
- 阶段结论：PASS
- 注意力等级：review
- 判断变化：G2 direct ingress 与 native Auth Mini 保持运行，同时 constxd release 已升级到 source PR #83 的 auto-redirect binary。
- 关键发现：
  1. 实际 systemd process、canonical executable、manifest 和 SHA-256 均绑定到 `059eab4` release。
  2. direct Nginx 无 `auth_request`，但应用 auth enabled 且未认证 API 保持 401；constx gateway 已停止，其他 gateway/auth-mini healthy。
  3. D3/D4 依用户明确要求保持 DEFERRED，未被本报告描述为通过。
- 阻塞项：无 source/config/runtime deployment blocker。
- 残余风险：用户尚未报告 production browser/passkey 和 full Tool Call canary 结果。
- 人类动作：用户自行完成 D3/D4 观察；在结果落 log 前不得声称 production E2E PASS。
- 自动下一步：独立 review-change、dotfiles PR merge；G2 已运行，不进行额外 auth topology 变更。
- 完整证据：
  - docs/evidence/nix-eval-059eab4.txt
  - docs/evidence/axiom-build-059eab4.txt
  - docs/evidence/azar-runtime-059eab4.txt
  - docs/evidence/public-and-peer-059eab4.txt

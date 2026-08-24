# Expose cybion on acorn via nginx at cybion.0xc1.wang with nix-ld runtime - 日志

## 会话进展 (2026-08-24)

### ✅ 已完成

(暂无)

(暂无)
### 🟡 进行中

- 初始化任务日志。
### ⚠️ 阻塞/待定

(暂无)

(暂无)
---

## 关键文件

(暂无)
---

## 关键决策

| 决策 | 原因 | 替代方案 | 日期 |
|------|------|----------|------|
| review-rfc PASS with two amendments folded into rfc.md | nginx blast radius mitigated by NixOS acme preliminarySelfsigned default (nginx starts on self-signed cert, real cert reloads later); client_max_body_size raised to 0 and proxy extraConfig aligned to mkNodeProxyVhost to match proven long-connection pattern and avoid proxy-below-app 413s | FAIL and rewrite; keep 64m cap | 2026-08-24 |
---

## 快速交接

**下次继续从这里开始：**

1. (none)

**注意事项：**

(暂无)
---

*最后更新: 2026-08-24 10:36 by Legion CLI*

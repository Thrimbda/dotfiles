# Expose cybion on acorn via nginx at cybion.0xc1.wang with nix-ld runtime

## 目标

Run cybion on acorn the standard way: nix-ld executes the pristine upstream binary, and nginx exposes the service at https://cybion.0xc1.wang with a Cloudflare DNS-01 certificate and DNS record.

## 问题陈述

cybion was migrated to acorn with a fragile patchelf plus bundled-libs hack because acorn force-disables nix-ld; the service is reachable only via SSH tunnel and cannot self-update.

## 验收标准

- [ ] acorn enables nix-ld and the pristine upstream cybion binary runs without patching
- [ ] nginx vhost cybion.0xc1.wang proxies to 127.0.0.1:1858 with an ACME certificate issued via the repo Cloudflare DNS-01 token
- [ ] DNS-only A record cybion.0xc1.wang -> 8.159.128.125 created through the Cloudflare API using the same token
- [ ] https://cybion.0xc1.wang/health is publicly reachable and the paired worker tunnel stays online
- [ ] config change lands through a worktree PR, merges, and deploys from Axiom with the AGENTS.md nixos-rebuild command

## 假设 / 约束 / 风险

- **假设**: cybion data already lives on acorn at ~/.cybion and ~/.cybion-worker and stays untouched
- **假设**: cybion listens on 0.0.0.0:1858 on acorn as a manually managed process
- **假设**: acorn user c1 can read /run/agenix secrets and activate system switches via sudo
- **约束**: no nix build or system-closure evaluation on acorn; build on Axiom only
- **约束**: deploy only with: nixos-rebuild switch --flake .#acorn --target-host c1@8.159.128.125 --build-host localhost --sudo --ask-sudo-password --use-substitutes -L
- **约束**: no systemd unit for cybion; the user restarts it manually
- **约束**: public port 80 stays closed; ACME uses DNS-01
- **约束**: cybion endpoint is exposed directly without auth-mini-gateway because it enforces its own Auth Mini JWT and machine token boundaries
- **风险**: nginx config change shares blast radius with existing auth/vault vhosts; mitigated by additive vhost plus nginx config test at switch time
- **风险**: ACME DNS-01 issuance failure leaves the vhost without a cert; mitigated by checking acme service logs after switch
- **风险**: swapping back to pristine binaries needs a brief restart window for the manually managed processes

## 要点

- 待补充

## 范围

- hosts/acorn/modules/platform.nix: drop the nix-ld mkForce false override
- new hosts/acorn/modules/cybion.nix: vhost, ACME host registration, SSE-friendly proxy settings, raised client_max_body_size
- hosts/acorn/default.nix: import the cybion module
- Cloudflare DNS-only A record for cybion.0xc1.wang via API token from /run/agenix/cloudflare-dns-env on acorn
- replace patched binaries with pristine upstream binaries on acorn and restart both processes

## 非目标 (Non-goals)

- 不为 cybion 创建 systemd unit；进程由用户手动重启
- 不在 cybion 前面套 auth-mini-gateway
- 不改变 worker 拓扑、配对关系或已迁移数据
- 不迁移 cybion 的设置或历史

## 设计索引 (Design Index)

> **Design Source of Truth**: [docs/rfc.md](docs/rfc.md)

**摘要**:
- follow the vaultwarden.nix pattern: module-local vhost plus cloudflareDnsAcme host registration
- reuse the mkNodeProxyVhost-style proxy hardening: SSE buffering off, 24h timeouts, X-Forwarded-Proto https so pairing URLs are https
- raise client_max_body_size above the global 256k for uploads, voice audio, and executor transfer chunks
- treat the DNS record as part of the release artifact per existing acorn wiki decisions
- non-goals: no systemd unit for cybion, no auth-mini-gateway fronting, no worker topology changes, no cybion data migration

## 阶段概览

1. **design-gate** - spec-rfc: short RFC with options, decision, verification for the ingress change
2. **implement** - engineer: nix-ld revert plus cybion nginx module in an isolated worktree
3. **deliver** - git-worktree-pr: open PR, merge, clean worktree, refresh main workspace

---

*创建于: 2026-08-24 | 最后更新: 2026-08-24*

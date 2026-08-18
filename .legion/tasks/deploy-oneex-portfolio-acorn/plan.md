# Deploy 1Ex portfolio adapter on Acorn

## 目标

Deploy the 1Ex portfolio adapter as a hardened Acorn systemd service behind https://1ex-portfolio.0xc1.wang, using a long bearer token and no plaintext repository secrets.

## 问题陈述

No Acorn service, nginx virtual host, encrypted environment file, or reproducible Nix package currently exists for the adapter.

## 验收标准

- [x] The adapter runs as a non-root enabled systemd service bound only to loopback.
- [x] https://1ex-portfolio.0xc1.wang proxies to the adapter through nginx with a valid ACME certificate.
- [x] The configured bearer token is at least 32 characters and is not committed in plaintext.
- [x] The configuration is built locally and applied using the required remote nixos-rebuild command; Acorn performs no build.
- [x] Authenticated discovery and positions requests succeed within the Custom Account Source deadline.

## 假设 / 约束 / 风险

- **假设**: Cloudflare DNS-01 credentials already configured on Acorn can issue the selected hostname certificate.
- **假设**: The existing registered local Ed25519 identity remains valid for auth-mini.
- **假设**: GitHub revision 8dcf21f9a2549212bff4b380dc5daf3f5c1236f9 is the reproducible upstream adapter source baseline.
- **约束**: Do not run any Nix build or evaluation on Acorn.
- **约束**: Run the remote switch from this local machine with nixos-rebuild switch --flake .#acorn --target-host c1@8.159.128.125 --build-host localhost --sudo --ask-sudo-password --use-substitutes -L.
- **约束**: Keep private key material, service environment, and bearer token out of plaintext tracked files and logs.
- **约束**: Do not alter unrelated Acorn services or 1Ex business mapping.
- **风险**: DNS/ACME issuance or remote activation can fail and require rollback to the prior NixOS generation.
- **风险**: The live Fund read is slower than the former adapter timeout; deployment must retain the locally verified 5.8-second read budget.
- **风险**: A public endpoint can be probed, so it must remain protected by the adapter bearer check.

## 要点

- Pin the upstream Rust source in a Nix package and apply only the verified read-timeout delta.
- Use an agenix-owned environment file and a dedicated unprivileged service account.
- Expose only nginx TLS while the adapter itself remains on 127.0.0.1.

## 范围

- packages/oneex-portfolio-adapter/**
- hosts/acorn/modules/oneex-portfolio-adapter.nix
- hosts/acorn/default.nix
- hosts/acorn/secrets/secrets.nix
- hosts/acorn/secrets/oneex-portfolio-adapter-env.age
- Cloudflare DNS-only A record for 1ex-portfolio.0xc1.wang
- .legion/tasks/deploy-oneex-portfolio-acorn/**

## 设计索引 (Design Index)

> **Design Source of Truth**: docs/rfc.md

**摘要**:
- A pinned GitHub source is built with the existing unstable Rust platform and a narrow patch raises the read budget from 4.5 to 5.8 seconds.
- A dedicated system user receives an agenix environment file containing the existing identity seed, authenticated user ID, loopback bind address, and a no-op exclusion placeholder.
- Nginx terminates TLS for 1ex-portfolio.0xc1.wang and transparently forwards the bearer-protected API to the loopback service.

## 阶段概览

1. **Design and preflight** - Record the package, secret, nginx, timeout, validation, and rollback design
2. **Implement Acorn configuration** - Add the pinned package, systemd/nginx module, ACME certificate, and encrypted environment
3. **Build, deploy, and verify** - Build locally, switch Acorn remotely, and validate the HTTPS API
4. **Review and delivery** - Capture verification, review, walkthrough, wiki, and PR lifecycle evidence

---

*创建于: 2026-08-18 | 最后更新: 2026-08-18*

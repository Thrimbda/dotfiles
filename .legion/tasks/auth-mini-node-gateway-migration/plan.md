# Auth Mini Node Gateway Migration

## 目标

Move authentication enforcement and reverse proxying for Acorn-published Axiom services onto Axiom while retaining auth-mini, TLS termination, and FRP ingress on Acorn.

## 问题陈述

Acorn currently owns the status-axiom and opencode-axiom gateway instances while Axiom FRP proxies connect directly to Gatus and OpenCode. This centralizes application proxying on Acorn and leaves the node-local leg without the intended gateway boundary.

## 验收标准

- [ ] Axiom runs dedicated auth-mini-gateway proxy-mode instances in front of Gatus and OpenCode using loopback listeners and loopback upstreams.
- [ ] Axiom FRP proxies target the gateway listeners rather than application ports; Gatus and OpenCode remain bound to loopback.
- [ ] Acorn retains auth-mini, TLS, auth-gateway, and frps-acorn protection while status and OpenCode virtual hosts forward all application traffic to the corresponding FRP remote ports without local auth gateway instances.
- [ ] The gateway package is pinned to upstream revision 28a4a273ea9b2725191dce35233f55972beaac6f with verified Nix hashes.
- [ ] Axiom receives an independently encrypted gateway environment secret; no plaintext secret or runtime session database is committed or logged.
- [ ] Proxy behavior needed by OpenCode and Gatus, including WebSocket upgrades, streaming, uploads, cookies, redirects, and forwarded headers, is preserved or explicitly bounded by the implementation note.
- [ ] Static evaluation, package/host validation that is safe for the current machine, security review, and delivery review pass with recorded evidence.
- [ ] The change is delivered and merged through a pull request.

## 假设 / 约束 / 风险

- **假设**: A cutover may invalidate existing status and OpenCode gateway sessions and require users to authenticate again.
- **假设**: No runtime SQLite session database migration is required because session continuity is less important than a clean declarative trust boundary.
- **假设**: Axiom can reach Acorn auth-mini through the existing public HTTPS auth endpoint used by current gateways.
- **假设**: The two Axiom services continue to listen on 127.0.0.1:8080 and 127.0.0.1:4096.
- **约束**: Do not build or evaluate an Acorn system closure on Acorn; any live Acorn deployment must be initiated from Axiom with the mandated remote nixos-rebuild command.
- **约束**: Do not expose secrets, allowlists, session identifiers, or decrypted age material in logs, commits, reviews, or PR artifacts.
- **约束**: Do not add Nginx to Axiom or broaden public firewall exposure.
- **约束**: Preserve unrelated worktree changes and untracked files.
- **约束**: Use an isolated Git worktree and deliver through a PR.
- **风险**: Incorrect forwarded-header trust could permit client IP spoofing or silently change audit behavior.
- **风险**: Incorrect Nginx or gateway buffering and timeout settings could break OpenCode streaming, uploads, or WebSockets.
- **风险**: A bad FRP port mapping could bypass authentication or make a service unavailable.
- **风险**: Secret recipient or service ownership mistakes could prevent startup or expose credentials.
- **风险**: Removing Acorn gateway state causes a planned session reset and requires a rollback path.

## 要点

- Keep Acorn as public TLS and auth-mini authority while moving service-specific gateway enforcement to Axiom.
- Use separate Axiom gateway instances and state directories for Gatus and OpenCode.
- Treat the FRP remote ports as private ingress reachable through Acorn Nginx and firewall policy, not as public application endpoints.
- Keep the change host-local and minimal: preserve Acorn's existing service generator and define the two Axiom services directly in the Axiom host configuration.
- Document cutover, rollback, session reset, and verification evidence before implementation is considered ready.

## 范围

- In scope: auth-mini-gateway package pin, Acorn/Axiom NixOS service topology, FRP mappings, Nginx proxy behavior, age secret wiring, targeted evaluation, review evidence, PR, and wiki writeback.
- Out of scope: migrating auth-mini itself off Acorn, adding gateways to other nodes, changing application ports, changing identity policy, preserving existing SQLite sessions, and deploying unrelated upstream documentation changes.

## 设计索引 (Design Index)

> **Design Source of Truth**: .legion/tasks/auth-mini-node-gateway-migration/docs/implementation-note.md

**摘要**:
- Update the gateway pin, keep Acorn's two remaining local gateways unchanged, and move only status/OpenCode gateway services to Axiom.
- Point FRP at Axiom gateway ports and make the two Acorn vhosts stream all traffic to those FRP ports.
- Validate the package, Axiom toplevel, and targeted effective configuration without a live deployment.

## 阶段概览

1. **Contract and design** - Materialize and validate the task contract
2. **Implementation** - Implement package, service, secret, FRP, and Nginx changes
3. **Verification and review** - Validate package and host configuration
4. **Delivery** - Generate walkthrough and durable wiki writeback

---

*创建于: 2026-07-16 | 最后更新: 2026-07-16*

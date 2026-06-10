# Axiom Critical Network Resilience

## Task ID
`axiom-critical-network-resilience`

## Goal
Harden `axiom` so the remote-access and network-control path survives memory pressure and recovers from degraded-but-active states. The critical path is `autossh-reverse-ssh.service`, `cloudflared.service`, `clash-verge.service` with its mihomo core, and the Clash Verge GUI/control process where practical.

## Problem
The recent OOM/reboot incident showed that key network services can either be killed outright or remain `active` while functionally broken. `autossh` stayed active while remote port forwarding failed because a stale remote `sshd` held `127.0.0.1:2223`; `cloudflared` could be active while `/ready` returned unhealthy; and the user-level Clash Verge autostart unit currently has a positive OOM score, making it more killable than ordinary processes. The machine needs explicit service priority, health checks, and workload isolation so access paths are preserved before large desktop or build workloads.

## Acceptance
- `autossh-reverse-ssh.service`, `cloudflared.service`, `clash-verge.service`, and `sshd.service` have declarative OOM/resource protection appropriate for critical network services.
- The Clash Verge GUI/autostart process is no longer penalized with an avoidable high OOM score, without making it more protected than the mihomo/service-mode core.
- `cloudflared` has a declarative health check that detects `/ready` failures and restarts the service after bounded repeated failures.
- `autossh` has a declarative health check that detects active-but-broken reverse forwarding, including remote `127.0.0.1:2223` bind failures where feasible without weakening SSH host-key policy.
- Runtime changes remain scoped to `axiom` and relevant reusable modules; unrelated desktop behavior and existing tunnel hostnames are preserved.
- Verification includes Nix evaluation/build checks and targeted service-shape checks, plus live checks where safe on the current machine.
- Rollback is straightforward by reverting the new service overrides, healthcheck timers, and optional swap/workload isolation changes.

## Scope
- Update `hosts/axiom/default.nix` for host-local critical network service hardening.
- Update `modules/services/cloudflared.nix` only if the health/resource policy belongs in the reusable cloudflared module rather than axiom-specific overrides.
- Update `modules/desktop/apps/clash-verge.nix` only if Clash core or GUI protection can be expressed safely there.
- Add small healthcheck scripts/timers through Nix where they are directly related to `autossh`, `cloudflared`, or Clash resilience.
- Optionally add zram or background workload slice configuration if it is minimal and directly reduces recurrence risk.
- Add Legion design, verification, review, walkthrough, and wiki artifacts for this task.

## Non-goals
- Do not replace autossh with Cloudflare Access, Tailscale, WireGuard, or another remote-access mechanism.
- Do not rotate SSH keys, permanently alter `~/.ssh/known_hosts`, or weaken host-key checking.
- Do not kill or redesign the current ashare data build workload; only define safer future isolation if needed.
- Do not change Cloudflare DNS, Access policy, tunnel credentials, or hostname routing except for local health behavior.
- Do not redesign Clash profiles, proxy rules, or desktop UI behavior.
- Do not deploy with `nixos-rebuild switch` unless explicitly requested after review.

## Assumptions
- `axiom` is a NixOS host with systemd managing `autossh-reverse-ssh.service`, `cloudflared.service`, `clash-verge.service`, and `sshd.service`.
- `clash-verge.service` is the critical Clash service-mode/core path; the generated user autostart unit is primarily GUI/control surface.
- Remote host `8.159.128.125` remains the autossh target and remote `127.0.0.1:2223` remains reserved for `axiom`.
- Temporary SSH host-key trust for health checks must not write into the user's persistent `known_hosts` unless explicitly approved.
- The system has about 46 GiB RAM and existing disk swap; zram can be considered but should not become a large unrelated tuning project.

## Constraints
- Follow Legion workflow end to end.
- For production configuration changes, enter `git-worktree-pr` envelope after contract stabilization.
- Keep the implementation minimal and auditable; prefer systemd/Nix primitives over ad-hoc long-running scripts.
- Do not revert unrelated user or agent changes in the shared checkout.
- Health checks must avoid logging secrets or sensitive SSH material.
- Any remote autossh check must be bounded by timeouts and safe failure behavior.

## Risks
- Over-protecting GUI/WebKit processes could keep memory-heavy desktop components alive at the expense of the actual network core.
- Misconfigured `MemoryMin`/`MemoryLow` values could reserve too much memory and make OOM behavior worse under sustained pressure.
- A remote autossh health check could flap if the remote host is briefly unreachable or host-key trust is not available in the service environment.
- `systemd-xdg-autostart-generator` user units may require a drop-in strategy that must be verified because the generated unit path is not static source code.
- Nix build checks can prove unit shape but cannot fully prove behavior under real global OOM without destructive stress testing.

## Design Summary
- Treat network survivability as a tiered policy: Tier 0 protects `sshd`, `autossh`, `cloudflared`, and Clash service-mode/mihomo; Tier 1 gives Clash GUI moderate protection and restart behavior; Tier 2 makes heavy ad-hoc workloads more killable or easier to isolate.
- Use kernel OOM scoring first because the incident involved global OOM selection; add `MemoryMin`/`MemoryLow` as cgroup-level reinforcement rather than the only defense.
- Add health checks for the two active-but-broken modes already observed: `cloudflared` readiness failure and `autossh` reverse-forward failure.
- Prefer host-local overrides for `axiom` unless a setting is clearly reusable and safe for every host using the module.
- Keep remote checks conservative: bounded timeouts, no persistent known_hosts mutation, and no automatic remote process killing unless explicitly designed and accepted.

## Phases
1. Materialize this Legion task contract and checklist.
2. Produce and review a focused RFC for OOM/resource policy, health checks, rollback, and verification.
3. Implement the approved Nix/systemd changes inside the required worktree/PR envelope.
4. Verify build/eval output and targeted live service behavior where safe.
5. Review the implementation for safety, scope, and operational regressions.
6. Produce reviewer-facing walkthrough/PR artifacts and update the Legion wiki.

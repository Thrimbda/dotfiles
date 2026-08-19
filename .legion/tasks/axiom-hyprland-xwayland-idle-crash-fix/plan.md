# Axiom Hyprland XWayland Idle Crash Fix

## 目标

Keep Axiom's automatic lock and DPMS policy while removing competing idle ownership and making monitor recovery safe after a compositor restart.

## 问题陈述

Axiom has two independent idle owners: Hypridle and Caelestia both issue a 15-minute lock and a 30-minute DPMS transition. Hypridle's legacy DPMS command already fails Lua parsing, while Caelestia uses the current dispatcher form. Recent repeated Hyprland coredumps occur while an XWayland surface maps with all DRM CRTCs unassigned; Hypridle then aborts because Wayland disappeared and the compositor reports the lock client as failed. Hyprland 0.56.1 and 0.56.2 have identical code in the crashing floating-layout function, so upgrading to 0.56.2 is not an evidence-backed fix. After a compositor crash, the custom monitor hotplug watcher also loops against the old socket signature.

## 验收标准

- [x] Caelestia is Axiom's only automatic idle owner: it retains the existing 15-minute lock and 30-minute DPMS policy, while Hypridle has no competing Axiom idle callbacks.
- [x] Caelestia WlSessionLock remains the ordinary lock client, and RustDesk/XWayland remain enabled.
- [x] No automatic idle suspend path is added or restored.
- [x] The monitor hotplug watcher uses the active compositor socket and backs off after a disconnect rather than spinning against a stale signature.
- [x] Focused static/Nix validation proves the single-owner policy and recovery behavior; live DPMS/resume smoke is documented as required post-deploy evidence.

## 假设 / 约束 / 风险

- **假设**: The reported lock-client failure is downstream of the compositor crash rather than evidence that Caelestia alone is the primary fault.
- **假设**: The issue occurs during DPMS-only idle, not system suspend.
- **假设**: Removing simultaneous idle callbacks reduces the unsafe interaction surface even though it cannot prove the upstream XWayland crash root cause.
- **约束**: Preserve automatic DPMS rather than using a permanent display-on workaround.
- **约束**: Preserve Caelestia WlSessionLock, existing lock timings, RustDesk, and XWayland.
- **约束**: Do not run a disruptive live DPMS or suspend test from this session.
- **风险**: The observed XWayland crash may still require an upstream fix after the local interaction and recovery hardening.
- **风险**: Caelestia must remain live for its idle policy to run; its service supervision stays unchanged in this task.
- **风险**: Static evaluation cannot prove a real display wake path.

## 要点

- Crash evidence
- Single idle owner
- Stale socket recovery
- Residual XWayland crash evidence

## 范围

- Axiom-specific idle ownership and relevant shared Hyprland wiring
- monitor hotplug watcher behavior
- config/hypr/hypridle.conf only if needed to prevent Axiom's duplicate callbacks
- task evidence and durable Legion wiki entries

## 设计索引 (Design Index)

> **Design Source of Truth**: .legion/tasks/axiom-hyprland-xwayland-idle-crash-fix/docs/rfc.md

**摘要**:
- Keep Caelestia as the sole Axiom idle owner because it already owns WlSessionLock and uses the current DPMS dispatcher form.
- Prevent Hypridle from running competing Axiom idle callbacks rather than making its legacy DPMS invocation effective.
- Rework the monitor hotplug watcher to discover the current compositor socket and back off after disconnects; retain the upstream crash as an explicit residual for live evidence.

## 非目标

- Do not disable automatic DPMS, RustDesk, XWayland, or Caelestia WlSessionLock.
- Do not make an unsupported Hyprland version upgrade or carry a local compositor-source patch without an identified upstream fix.
- Do not treat static checks as proof that a real long-idle display wake is fixed.

## 阶段概览

1. **Design and RFC review** - Choose and review the single-owner and socket-recovery strategy
2. **Implementation** - Apply the Axiom idle-owner and watcher recovery changes
3. **Verification** - Run focused static and Nix checks
4. **Delivery** - Review, document, and deliver the change through its PR lifecycle

---

*创建于: 2026-08-19 | 最后更新: 2026-08-19*

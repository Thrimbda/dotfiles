# Review Change: Dotfiles Prune and Host Framework Extraction

## Decision

PASS. No blocking correctness, scope, maintainability or security findings remain against `origin/master` at `07816e00`.

## Blocking Findings

None.

## Scope Review

PASS.

- `.legion/tasks/**` contains only this task; all closed raw tasks were removed after their wiki summaries were retained.
- The root `README.md` was removed, while `flake.lock`, encrypted secrets, domains, IPs, host keys and numeric topology remain unchanged.
- Production changes are limited to the approved Axiom/Acorn host split, small shared service mechanics and Charlie's typed Cloudflared tunnel name.
- The package-module inventory is advisory only; it does not remove or inline package modules.

## Correctness Review

PASS.

- Axiom and Acorn defaults are manifest-sized while their generated service, package and host-policy snapshots remain equivalent to the baseline.
- Nix import ordering preserves Axiom user and system package order, including upstream's `antigravity-ide-fhs` rename and the Qwen/RustDesk control packages.
- The latest Qwen selection, 128K service, bounded controller and `/run/wrappers/bin/sudo` behavior remain intact in the Axiom-local module.
- The sole intentional delta disables Acorn's inert Hypridle default; Hyprland and the Hypridle unit remain absent, removing the baseline assertion without changing runtime service ownership.
- Verification evidence is recorded in `docs/test-report.md`.

## Security Lens

Applied because auth gateways, Cloudflare ingress, reverse SSH, secret metadata, RustDesk and a sudo-adjacent Qwen controller moved.

Result: PASS.

- Auth gateways and application backends remain loopback-bound with the same system users, secret modes and systemd hardening.
- Cloudflare credentials, ingress hostnames, ACME recipes and fallback behavior are unchanged.
- Reverse SSH retains remote-loopback forwarding and its service-private host-key pin.
- RustDesk secret ownership, preflights, firewall policy, provisioning and service dependencies are preserved.
- `qwen-model` accepts only fixed commands, model targets and one fixed unit; it uses the NixOS sudo wrapper and adds no sudoers bypass.

## Non-Blocking Notes

- `modules.services.auth-mini-gateway.instances` remains an untyped configuration surface, and `extraEnvironment` can override reserved environment keys. Current callers do not do so; rejecting reserved keys is a future hardening option.
- Focused snapshots normalize Git-source store hashes and compare packages by name. This is appropriate for the mechanical move but is not a committed regression-test suite.

## Residual Verification Gaps

- No live Axiom switch or Cloudflare, FRP, autossh, gateway, Qwen, RustDesk or desktop smoke was performed.
- No Acorn build, switch or deployment was performed.
- Full candidate and baseline flake checks stop at the same existing `apps.install` schema error.

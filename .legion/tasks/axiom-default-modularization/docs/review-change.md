# Review Change: Axiom Default Modularization

## Verdict
PASS

## Blocking Findings
None.

## Scope Review
- In scope: `hosts/axiom/default.nix` cleanup of duplicate/defaulted settings, hardcoded user/home cleanup, and replacement of inline opencode/autossh/healthcheck mechanics with modules.
- In scope: new `modules/services/reverse-ssh.nix`, `opencode-server.nix`, and `healthchecks.nix` because these are the requested high-cohesion boundaries.
- In scope: `modules/services/cloudflared.nix` first-class `ingress` option, `calibre.nix` user/group defaults, and `gnome-keyring.nix` unused binding removal.
- Out of scope avoided: Hyprland color-management workaround, desktop shell/keybinding overhaul, secrets, external Cloudflare/DNS state, live autossh/suspend tests.

## Security Lens
Applied because this change touches SSH service behavior, reverse tunnel wiring, public Cloudflared ingress, and firewall policy.

- Reverse SSH keeps the same remote host, remote port, local target, remote user, and known host key. The service is now module-owned but does not widen the exposed endpoint.
- Cloudflared ingress remains `opencode-axiom`, `status-axiom`, then `http_status:404`; the refactor changes the source of the opencode ingress entry, not the public hostname or target.
- Firewall policy is narrower: the Axiom-specific `7844/udp` and broad ephemeral TCP/UDP ranges are removed. Remaining ports come from enabled service modules plus explicit SSH/local workbench rules.
- User/home paths now come from `config.user.*`, reducing accidental privilege/path drift.

## Verification Evidence
- `docs/test-report.md` records final key facts eval.
- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel` passed after staging the new modules.

## Residual Risks
- No live runtime smoke was performed for Cloudflared, autossh, or graphical Caelestia session behavior; this is intentionally deployment/runtime scope.
- `modules/desktop/hyprland.nix` still contains broader Axiom-flavored desktop defaults. This was identified during audit but intentionally left outside this focused service/host cleanup to avoid a desktop rewrite.

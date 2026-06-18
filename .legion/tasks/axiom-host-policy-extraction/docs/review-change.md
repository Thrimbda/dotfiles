# Review Change: Axiom Host Policy Extraction

## Decision
PASS

## Blocking Findings
None.

## Scope Review
PASS.

本轮只处理 PR #94 后剩余的 Axiom host-local policy extraction：
- Gatus endpoint boilerplate -> `modules.services.gatus` helper options。
- Cloudflared resource/restart policy -> `modules.services.cloudflared.servicePolicy`。
- SSHD resource policy -> `modules.services.ssh.serviceConfig`。
- Clash service policy and GUI autostart drop-in -> `modules.desktop.apps.clash-verge`。
- Workstation zram/logrotate/user-manager/NM profile policy -> `modules.profiles.workstation`。
- LAN-only firewall allow -> `modules.system.firewall.lanTcpAllows`。

没有改 Cloudflare external state、secrets、Hyprland desktop architecture、disk layout 或 healthcheck predicate internals。

## Correctness Review
PASS.

验证证据见 `docs/test-report.md`：
- `git diff --check` passed。
- Focused facts eval confirmed endpoints, ingress, resource policy, firewall rule, NetworkManager profile, zram, and logrotate facts。
- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel` passed。

实现保持行为语义：
- Gatus rendered endpoints 仍为 `opencode-axiom`, `vaultwarden-web`, `status-page`，conditions 和 labels 保持等价。
- Cloudflared ingress 仍包含 `opencode-axiom.0xc1.space`, `status-axiom.0xc1.space`, fallback `http_status:404`。
- `sshd`, `cloudflared`, `clash-verge`, Clash GUI autostart, and `user@1000` resource/OOM values 保持。
- LAN research workbench allow 仍限制到 `192.168.50.0/24` TCP `5173,8765`。
- `enp14s0` NetworkManager profile、zram values、logrotate check behavior 保持。

## Security / Operability Lens
Applied because the change moves firewall, remote-access, restart, and OOM policy.

Result: PASS.

No permission or exposure expansion was found:
- Firewall rule keeps the same source CIDR and ports and remains TCP-only.
- Cloudflared ingress does not add a new public hostname; it moves status ingress ownership to Gatus and keeps the fallback rule.
- Gatus public endpoint inventory is unchanged and continues using public-safe endpoints only.
- Resource/OOM policies are moved to owning modules without weakening critical service priority.
- SSH and Clash service policy movement does not change authentication or TUN/firewall trust behavior.

## Non-Blocking Notes
- `modules.services.ssh.serviceConfig` intentionally remains a raw attrset because OpenSSH systemd service hardening/resource policy is host-specific and already owned by the SSH module boundary.
- No live deployment, firewall packet test, Gatus HTTP probe, Cloudflared browser smoke, Clash GUI smoke, or NetworkManager activation smoke was performed; those remain post-deploy checks.

# RFC: Axiom Critical Network Resilience

> Profile: Standard RFC
> Status: Ready for review
> Task: `axiom-critical-network-resilience`
> Created: 2026-06-10

## Context
`axiom` depends on a small network-control path for emergency access and normal proxying: OpenSSH, autossh reverse SSH, cloudflared tunnel, and Clash Verge service-mode/mihomo. The incident showed two classes of failure: global OOM can kill important processes without priority awareness, and services can remain `active` while their actual access path is broken.

Current evidence shows system services have no explicit OOM or memory protection, while the generated Clash Verge GUI autostart unit reports a positive OOM score. The design therefore needs both OOM priority and health checks; one without the other does not cover the observed failure modes.

## Goals
- Prefer critical network services over large desktop, browser, and ad-hoc build workloads during global OOM selection.
- Restart services that are killed by OOM or become functionally unhealthy.
- Detect `cloudflared` readiness failure through `/ready` instead of relying on `systemctl active`.
- Detect autossh reverse-forward failure by testing the remote `127.0.0.1:2223` endpoint as a usable SSH path, not merely as a bound port.
- Keep Clash service-mode/mihomo more protected than the GUI wrapper.
- Keep all changes declarative, auditable, and reversible through Nix.

## Non-goals
- No replacement of autossh, cloudflared, or Clash Verge.
- No changes to Cloudflare DNS, Access policies, tunnel credentials, or proxy profiles.
- No permanent writes to the user's `~/.ssh/known_hosts`.
- No destructive memory stress testing on the live workstation.
- No redesign of current data-build workloads in this task.

## Options
### Option A: OOM Protection Only
Add `OOMScoreAdjust`, `MemoryMin`, and `MemoryLow` to the key services, but do not add health checks.

Pros:
- Smallest implementation.
- Reduces chance of future OOM kills.

Cons:
- Does not catch `cloudflared active but /ready 503`.
- Does not catch `autossh active but remote forward failing`.
- Does not address the exact active-but-broken modes already observed.

### Option B: Tiered Protection Plus Non-destructive Health Checks
Add OOM/resource protection to critical services, normalize Clash GUI priority, add non-destructive healthcheck timers for cloudflared/autossh/Clash, and add zram as a small memory-pressure buffer.

Pros:
- Covers both observed failure classes.
- Keeps core network services ahead of GUI/control surfaces.
- Is declarative and easy to roll back.
- Avoids mutating user SSH known-host files by pinning the autossh remote host key system-wide.

Cons:
- More moving parts than pure service overrides.
- Autossh remote health check needs careful SSH identity and host-key handling.
- User autostart unit drop-in requires targeted verification because the unit is generator-produced.

### Option C: Full Remote and Workload Re-architecture
Manage the remote SSH server configuration, replace ad-hoc heavy workloads with dedicated workload services/slices, and redesign remote cleanup semantics end to end.

Pros:
- Most comprehensive long-term solution.
- Could prevent stale remote listener incidents at the remote sshd layer.

Cons:
- Much broader than this task.
- Requires remote host configuration ownership and rollout.
- Risks delaying the high-value local hardening.

## Decision
Choose Option B for the first implementation pass, with automatic remote process killing explicitly excluded from enabled timer behavior.

Reasons:
- It directly addresses the incident without changing the remote-access architecture.
- It detects the stale remote listener failure mode without making irreversible remote changes from a timer.
- It leaves automatic remote cleanup, deeper workload isolation, and remote sshd policy as follow-up work if the first pass proves insufficient.

## Proposed Design
### Tier 0: Critical System Services
Apply host-local overrides on `axiom` for these units:

| Unit | OOMScoreAdjust | MemoryMin | MemoryLow | OOMPolicy | Restart |
| --- | ---: | ---: | ---: | --- | --- |
| `sshd.service` | `-900` | `32M` | `128M` | `continue` | keep or set safe restart if compatible |
| `autossh-reverse-ssh.service` | `-900` | `32M` | `128M` | `stop` | `always`, `RestartSec=5s` |
| `cloudflared.service` | `-850` | `128M` | `512M` | `stop` | `always`, `RestartSec=5s` |
| `clash-verge.service` | `-850` | `256M` | `1G` | `stop` | `on-failure`, `RestartSec=5s` |

Rationale:
- `OOMScoreAdjust` handles kernel global OOM victim selection.
- `MemoryMin` is intentionally small and hard-reserved only for the core services.
- `MemoryLow` gives reclaim preference without reserving excessive memory.
- `sshd.service` should not stop the whole listener just because one child session is killed, so it uses a more conservative OOM policy than single-purpose daemons.

### Tier 1: Clash Verge GUI/User Autostart
Add a user-unit drop-in for `app-clash\x2dverge@autostart.service` using `overrideStrategy = "asDropin"`.

Target settings:
- `Restart=on-failure`
- `RestartSec=5s`
- `MemoryLow=256M`
- `OOMScoreAdjust=0` if verified to apply cleanly

Also add a system drop-in for `user@1000.service` to reduce the user manager baseline `OOMScoreAdjust` from `100` to `0`. This is a minimal correction that avoids protecting the entire user session more than system services while allowing the Clash GUI to stop inheriting avoidable positive penalty.

If verification shows the user unit cannot lower the GUI process to `0`, the implementation should keep restart and `MemoryLow`, record the limitation, and avoid broad negative OOM scores for the full user session.

### Cloudflared Health Check
Make the readiness endpoint explicit in the cloudflared config:

- Add `metrics = "127.0.0.1:20241"` to the `axiom` cloudflared `extraConfig` if verification confirms the option shape.

Add `cloudflared-healthcheck.service` and `cloudflared-healthcheck.timer`:

- Timer: start after boot and run every 30 to 60 seconds with a small randomized delay.
- Check: `curl --fail --silent --show-error --max-time 5 http://127.0.0.1:20241/ready`.
- Failure behavior: keep a small counter under `/run`; restart `cloudflared.service` after 3 consecutive failures; clear the counter after a pass.
- Service user: root, because restarting the system service should not require interactive polkit.

### Autossh Health Check
Pin the current remote host key declaratively:

- Add `programs.ssh.knownHosts` entry for `8.159.128.125` using the current ED25519 host key.
- This writes `/etc/ssh/ssh_known_hosts` and does not mutate `/home/c1/.ssh/known_hosts`.

Add `autossh-reverse-ssh-healthcheck.service` and timer:

- Timer: start after network-online and run every 60 seconds.
- SSH command: run the remote check as `c1` or with `c1`'s SSH identity while the root healthcheck service keeps permission to restart local system services.
- Expected endpoint identity: read `axiom`'s local SSH host public key, preferably `/etc/ssh/ssh_host_ed25519_key.pub`, and compare it with the host key exposed by the remote reverse endpoint.
- Primary check: execute `ssh-keyscan -T 5 -p 2223 127.0.0.1` on `8.159.128.125` and pass only if the ED25519 key matches `axiom`'s local host public key.
- Secondary check: if the key check fails, inspect remote `ss -ltnp` for a listener on `127.0.0.1:2223` and log the result as evidence.
- Recovery: after repeated failure, restart `autossh-reverse-ssh.service` locally. Do not kill remote processes from the timer.
- Safety bounds: use `BatchMode=yes`, `ConnectTimeout`, `StrictHostKeyChecking=yes`, bounded remote `timeout`, and no persistent user known-host mutation.

If the remote port remains occupied by a stale listener after local restart, the healthcheck should leave clear journal evidence for manual cleanup. A separate manually triggered cleanup unit can be considered later, but it is not part of this RFC's enabled automated path.

### Clash Core Health Check
Add `clash-verge-healthcheck.service` and timer:

- Check `clash-verge.service` is active.
- Check a mihomo/core child process exists under the service cgroup, or the expected TUN interface exists (`Mihomo` or `Meta`).
- Restart `clash-verge.service` after 2 consecutive failures.
- Do not restart the GUI just because the GUI is closed; service-mode/core is the critical path.

### Zram Buffer
Enable zram swap on `axiom`:

- `zramSwap.enable = true`
- `zramSwap.memoryPercent = 20`
- `zramSwap.memoryMax = 8589934592`
- `zramSwap.priority = 100`
- `zramSwap.algorithm = "zstd"`

Keep existing disk swap as lower-priority fallback. This does not replace OOM policy; it reduces the chance that transient memory spikes immediately reach global OOM.

## Scope of File Changes
Expected files:
- `hosts/axiom/default.nix`
- `modules/services/cloudflared.nix` only if reusable module changes are cleaner than host-local overrides
- `modules/desktop/apps/clash-verge.nix` only if the Clash-specific protection should live with the module
- `.legion/tasks/axiom-critical-network-resilience/docs/*`
- `.legion/wiki/*` during closing writeback

## Rollout
1. Implement in an isolated worktree through `git-worktree-pr`.
2. Build/evaluate the `axiom` NixOS system closure.
3. Inspect generated system and user unit properties before any live switch.
4. If the user approves deployment, run `nixos-rebuild switch` separately and verify live healthcheck behavior.

## Verification
Required pre-deployment checks:
- `nix build --impure --no-link .#nixosConfigurations.axiom.config.system.build.toplevel`
- Evaluate or inspect generated unit configs for `OOMScoreAdjust`, `MemoryMin`, `MemoryLow`, timers, and known host entry.
- Verify the user-unit drop-in is generated for `app-clash\x2dverge@autostart.service`.
- Confirm cloudflared config includes explicit metrics endpoint if used by the healthcheck.
- Run non-destructive script checks for healthcheck failure counters and restart thresholds using fake command inputs where practical.
- Confirm autossh healthcheck compares remote `ssh-keyscan` output against `axiom`'s local host key rather than accepting a generic SSH banner.

Safe live checks after deployment approval:
- `systemctl show autossh-reverse-ssh.service cloudflared.service clash-verge.service sshd.service` for OOM/resource settings.
- `systemctl list-timers '*healthcheck*'`.
- `curl --fail http://127.0.0.1:20241/ready`.
- Remote autossh endpoint key check through `8.159.128.125:2223`.
- `systemctl --user show 'app-clash\x2dverge@autostart.service'` for GUI drop-in effects.

Not required:
- Live OOM stress testing.
- Remote sshd configuration changes.

## Rollback
Rollback is a normal Nix revert of the new host-local blocks and any module additions.

Specific rollback handles:
- Disable or remove healthcheck timers.
- Remove OOM/resource overrides from the four Tier 0 services.
- Remove the user-unit drop-in and `user@1000.service` OOM adjustment.
- Remove the `programs.ssh.knownHosts` entry if it causes SSH policy issues.
- Disable `zramSwap` if it has undesirable runtime impact.

No data migration is involved.

## Residual Risks
- If the remote port is occupied by a stale listener, the first pass detects and logs the condition but may still require manual remote cleanup.
- User manager OOM behavior may vary; the GUI protection must be verified on the generated unit and live system.
- zram improves pressure handling but can still lead to OOM under sustained memory growth.
- Healthcheck timers can restart services during transient network outages; failure counters and timeouts reduce but do not eliminate this risk.

## References
- Plan: `.legion/tasks/axiom-critical-network-resilience/plan.md`
- Research: `.legion/tasks/axiom-critical-network-resilience/docs/research.md`
- Autossh service: `hosts/axiom/default.nix`
- Cloudflared module: `modules/services/cloudflared.nix`
- Clash wrapper module: `modules/desktop/apps/clash-verge.nix`

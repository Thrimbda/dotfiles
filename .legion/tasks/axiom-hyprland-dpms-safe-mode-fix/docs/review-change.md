# Axiom Hyprland DPMS Safe Mode Fix - Review Change

## Verdict

PASS.

## Blocking Findings

None.

## Scope Review

- In scope: `hosts/axiom/default.nix` adds an Axiom-only `render.cm_enabled = false` Hyprland override.
- In scope: `modules/desktop/hyprland.nix` adds an explicit `hypridle.service` PATH for the commands already used by the checked-in `config/hypr/hypridle.conf`.
- In scope: task-local Legion docs record the investigation, design-lite, verification, and residual live-session gap.
- No Caelestia source, upstream Hyprland source, flake lock, polkit permissions, secrets, auth, or remote-access services were changed.

## Correctness Review

- The mitigation targets the observed root failure chain. Runtime evidence shows Hyprland coredumps in `NColorManagement::CImageDescription::id()` before Caelestia reports a broken Wayland connection.
- The Axiom-only `render { cm_enabled = false }` override matches the documented Hyprland 0.53 setting and avoids a broader compositor package override.
- The hypridle PATH change covers `hyprctl`, `hyprlock`, `pidof`, `systemctl`, and `loginctl` through evaluated packages, matching the commands in `hypridle.conf` without rewriting the config to store paths.
- Verification is credible for static readiness: generated-config eval, diff hygiene, toplevel build, and assembled Hyprland parser validation all passed.

## Security Lens

Applied because the task touches session/power-adjacent desktop behavior.

- No privileged service is added or widened; `hypridle.service` remains a user service under the Hyprland session.
- The PATH additions expose fixed Nix store packages already used by the desktop session, not user-controlled directories.
- No polkit action, sudo path, login1 permission, secret, token, or network trust boundary changed.

Security conclusion: no exploitable trust-boundary or privilege-escalation issue found.

## Residual Risk

- `render.cm_enabled = false` may affect HDR/color-managed rendering quality until Hyprland is updated past the upstream fix.
- The strongest remaining proof is live deployment: restart Axiom's graphical session, trigger DPMS off/on or suspend/resume, then confirm no new Hyprland coredump and no `--safe-mode` restart.

## Non-Blocking Suggestions

- After a future Hyprland update includes the upstream color-management hotplug fix, remove the Axiom override and rerun the live DPMS/resume smoke.

# Review Change: Axiom Host Script Extraction

## Decision
PASS

## Blocking Findings
None.

## Scope Review
PASS.

The change stays within the approved follow-up scope:
- Shrinks `hosts/axiom/default.nix` from 667 to 451 lines.
- Moves Caelestia mutable config migration and local-control polkit policy into `modules/desktop/caelestia.nix`.
- Moves HDMI audio readiness into `modules/desktop/audio/hdmi.nix`.
- Moves ToDesk runtime setup into `modules/services/todesk.nix`.
- Adds typed healthcheck predicates to `modules/services/healthchecks.nix` and removes Axiom predicate shell bodies.
- Moves libvirt/virt-manager host policy into `modules/virt/libvirt.nix`.

No Cloudflare IDs, secrets, Hyprland HDR/color-management workaround, or live service behavior outside the scoped module boundaries was changed.

## Correctness Review
PASS.

Evidence:
- `git diff --check` passed.
- Focused facts eval confirmed expected generated services/options.
- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel` passed.

Review notes:
- Caelestia mutable config behavior preserves the previous idle defaults, favourite Feishu launcher ID, and removal of the legacy desktop ID, but the script now lives behind `modules.desktop.caelestia.mutableConfig`.
- HDMI audio behavior preserves the previous card, sink, profile, default-sink setting, PulseAudio autospawn suppression, and EasyEffects ordering, but it now lives behind `modules.desktop.audio.hdmi`.
- ToDesk preserves the package, user, working directory, state dir, restart policy, and network-online ordering through `modules.services.todesk`.
- Autossh, Cloudflared, and Clash healthcheck scripts are still generated with the same core checks, but host config now only declares facts.
- Libvirt/virt-manager keeps `kvm`/`libvirtd` groups, `virt-viewer`, `virtio-win`, virt-manager enablement, libvirtd enablement, and `qemu.swtpm.enable`.

## Security Lens
Applied because the change touches polkit permissions and service boundaries.

Result: PASS.

The polkit action set is not expanded. It is the same login1 and NetworkManager allowlist previously embedded in `hosts/axiom/default.nix`, now guarded by `modules.desktop.caelestia.localControls.polkit.enable`. The option defaults to disabled, and Axiom explicitly enables it for the same local user.

The ToDesk service remains a user service under the configured user and does not gain additional privileges. Healthcheck scripts retain existing SSH options and local key comparison behavior.

## Non-Blocking Notes
- No live deployment, graphical session restart, audio sink smoke, or ToDesk runtime smoke was performed. This is acceptable for this task because the contract requires static Nix validation and build proof.

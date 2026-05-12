# Change Review

## Round 1 Verdict

FAIL

## Blocking Findings

- `hosts/axiom/default.nix`: the first implementation allowed logind power actions for any process running as `c1`, without checking that the polkit subject was local. That exceeded the contract boundary of local desktop shell control and could let a remote SSH process owned by `c1` reboot or power off the workstation without authentication. Minimal fix: require `subject.local == true` in addition to the primary user and fixed action allowlist.
- `hosts/axiom/default.nix`: the first implementation also added `c1` to the `networkmanager` group, which would reuse the broad NixOS `NetworkManager.*` group rule for all `c1` processes. That exceeded the minimum local shell authorization boundary. Minimal fix: remove the group grant and use the same local-subject primary-user fixed-action polkit allowlist for required NetworkManager actions.

## Security Lens

Applied because the change modifies authentication/authorization policy for logind power actions.

## Round 2 Verdict

PASS

## Blocking Findings

No remaining blocking findings.

## Review Notes

- `hosts/axiom/default.nix` now keeps the policy Axiom-local and local-subject-only with `subject.local == true`, `subject.user == "c1"`, and literal allowlists for only the intended NetworkManager and logind actions.
- The broad `networkmanager` group grant was removed; final eval confirms `hasNetworkManagerGroup = false` and `polkitAvoidsNetworkManagerPrefixGrant = true`.
- The logind allowlist does not use a prefix grant and does not include ignore-inhibit, generic login1 manage, or systemd unit management actions.
- Theme changes are in scope: Axiom disables the Fcitx5 Catppuccin override, Rime/Pinyin remain enabled, and Autumnal uses Papirus/Bibata instead of Catppuccin-backed visible assets.
- Verification evidence is adequate for static readiness: targeted eval, `git diff --check`, and the Axiom toplevel build passed. Live Wi-Fi/power/visual checks are correctly recorded as post-deploy smoke tests because they are disruptive or require the switched graphical session.

## Non-Blocking Notes

- If Caelestia's systemd-user service is not considered `subject.local` after deployment, the live smoke will still fail and the next scoped fix should inspect the exact polkit subject classification before widening policy.

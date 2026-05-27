# Axiom Remove Never Sleep - Review Change

## Verdict

PASS

No blocking findings.

## Scope Review

- In scope: `hosts/axiom/default.nix` removes the generated `axiom-caelestia-never-sleep` script and `systemd.user.services.axiom-caelestia-never-sleep` declaration.
- In scope: `config/hypr/hypridle.conf` preserves the user's longer idle timing as 15 minute lock and 30 minute DPMS off/on.
- In scope: `hosts/axiom/README.org` and `.legion/wiki/**` current-truth entries no longer describe the removed service as active Axiom behavior.
- In scope: the old never-sleep wiki task summary is retained only as superseded historical context.
- Out of scope avoided: no `axiom-sleep-mode`, Power Mode launcher, Hypridle suspend listener, replacement inhibitor, logind option, or polkit expansion was added.

## Correctness Review

- The removed Nix binding was only used by the removed user service, so deleting both leaves no dangling reference.
- Caelestia Keep Awake enablement remains in place through the existing `axiom-caelestia-keep-awake` helper.
- Active documentation now matches the evaluated configuration: Hypridle owns idle lock/DPMS, and direct sleep requests are not blocked by a repository-owned inhibitor.
- The previous never-sleep wiki page is explicitly marked superseded, which prevents historical evidence from being mistaken for current policy.

## Verification Review

Verification evidence is sufficient for this scope:

- Active-reference `rg` search passed for host config, Hypridle config, README, and current-truth wiki files.
- Hypridle timeout grep confirmed `timeout = 900 # 15mins` and `timeout = 1800 # 30mins`.
- `git diff --check` passed.
- Targeted Nix eval returned true for service absence, Hypridle values, no suspend command, and preserved Keep Awake helper text.
- `nix build .#nixosConfigurations.axiom.config.system.build.toplevel --no-link` passed.

## Security Lens

Security trigger review: no auth, secret, token, protocol, or user-controlled privileged path changed. The task touches logind-adjacent power behavior by removing an inhibitor, so the trust-boundary check was considered explicitly.

Result: no security blocker. The change removes a default sleep blocker without widening polkit/logind permissions. Existing Axiom logind power-control allowlists are unchanged.

## Residual Risk

- Live Hyprland/Caelestia behavior still requires post-deploy smoke because this tool session cannot inspect the active graphical session or Hypridle runtime logs.

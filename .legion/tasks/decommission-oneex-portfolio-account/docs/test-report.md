# Test Report: Minimal 1Ex Portfolio Adapter Undeployment

> **Result**: PASS for candidate `b1049dbd936191b8a9d4ada8687639fae94b1137` on Axiom; not final delivery approval.

## Verdict

The tracked production delta is exactly the one import deletion. Syntax, no-cache Acorn option evaluation, toplevel `drvPath` evaluation, and the pre-deployment `inactive/dead` check passed. No closure build, deployment, or host mutation was performed.
Delivery is blocked because the candidate is one Acorn-changing commit behind `origin/master`; rebase and complete reverification are required.

## Executed Evidence

Host, diff, and syntax commands on Axiom:
```sh
hostname && hostnamectl --static
test "$(git diff --name-only HEAD)" = "hosts/acorn/default.nix"
test "$(git diff --numstat HEAD)" = $'0\t1\thosts/acorn/default.nix'
git diff --check HEAD
nix-instantiate --parse hosts/acorn/default.nix >/dev/null
```
**PASS:** host output was `axiom` / `axiom`; the diff was `hosts/acorn/default.nix | 1 -` and removed only `./modules/oneex-portfolio-adapter.nix`; syntax checks exited zero.

No-cache evaluation commands on Axiom:
```sh
nix eval --impure --json --option eval-cache false --expr 'let flake = builtins.getFlake (toString ./.); config = flake.nixosConfigurations.acorn.config; in { adapterServicePresent = builtins.hasAttr "oneex-portfolio-adapter" config.systemd.services; adapterVhostPresent = builtins.hasAttr "1ex-portfolio.0xc1.wang" config.services.nginx.virtualHosts; adapterAgeSecretPresent = builtins.hasAttr "oneex-portfolio-adapter-env" config.age.secrets; }'
nix eval --impure --raw --option eval-cache false .#nixosConfigurations.acorn.config.system.build.toplevel.drvPath
```
**PASS:** `{"adapterAgeSecretPresent":true,"adapterServicePresent":false,"adapterVhostPresent":false}`.
**PASS:** toplevel `drvPath` was `/nix/store/y4zngs2cqksv23rkj6yv3dv29iy1paz6-nixos-system-acorn-26.05.7813.0dd31db7e6db.drv`; this evaluated/instantiated but did not build the closure.

Read-only runtime command from Axiom:
```sh
ssh -o BatchMode=yes -o ConnectTimeout=10 c1@8.159.128.125 systemctl show oneex-portfolio-adapter.service --property=LoadState --property=ActiveState --property=SubState --no-pager
```
**PASS:** `LoadState=loaded`, `ActiveState=inactive`, `SubState=dead`. Loaded is expected before undeployment and confirms activation is still pending.

Delivery-base evidence: `git rev-list --left-right --count HEAD...origin/master` returned `0 1`; `HEAD=b1049dbd936191b8a9d4ada8687639fae94b1137`, `origin/master=a291a95b9def6ec3b29d66b8bde3c42973bc63dd`. The upstream Cybion commit changes Acorn's import list, so current evaluation cannot serve as final evidence.

## Pending Gates

- **BLOCKING:** Rebase onto current `origin/master`, preserve upstream Acorn changes, and rerun exact-diff, syntax, both no-cache evaluations, and pre-deployment state checks on Axiom.
- **PENDING:** Merge, refresh Axiom to the merged revision, and run the exact deployment command in `rfc.md`; stop on build, transfer, or activation failure, with no Acorn-local build.
- **PENDING:** Prove post-activation unit/process/TCP `8090`/active-vhost absence, no new failed unit, and unrelated-service health. The retained secret remains expected and unread.

References: `rfc.md`, `research.md`, `review-rfc.md`, `review-change.md`, `../plan.md`, `../log.md`.

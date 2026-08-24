# Test Report: Minimal 1Ex Portfolio Adapter Undeployment

> **Result**: PASS for rebased candidate `da08cfbcca046848bdf09bce85caf3f1ccafd9ef` on Axiom; not final deployment approval.
> **Base**: `origin/master` at `a291a95b9def6ec3b29d66b8bde3c42973bc63dd`

## Verdict

The rebased commit is exactly one commit ahead of `origin/master`, with `origin/master` as its merge base. Its complete production delta is one deleted import in `hosts/acorn/default.nix`; upstream Cybion configuration is preserved, and no prohibited module, package, agenix, or secret path changed.

Syntax, no-cache Acorn option evaluation, toplevel `drvPath` evaluation, and the pre-deployment `inactive/dead` check all pass. The stale-base blocker is cleared. Merge, deployment, and final post-activation runtime checks remain pending; no closure build, deployment, or host mutation was performed.

## Executed Evidence

Host and rebased-base commands on Axiom:
```sh
hostname && hostnamectl --static
git status --short --branch
git rev-parse HEAD origin/master
git merge-base HEAD origin/master
git rev-list --left-right --count origin/master...HEAD
```
**PASS:** host output was `axiom` / `axiom`. The worktree was clean before this report update, the branch was one commit ahead with no reported behind count, and the merge base exactly matched `origin/master`:

```text
HEAD:                       da08cfbcca046848bdf09bce85caf3f1ccafd9ef
origin/master:              a291a95b9def6ec3b29d66b8bde3c42973bc63dd
merge-base:                 a291a95b9def6ec3b29d66b8bde3c42973bc63dd
origin/master...HEAD count: 0 1
```

Production-scope and syntax commands:

```sh
git diff --name-status origin/master...HEAD
git diff --name-status origin/master...HEAD -- . ':(exclude).legion/**'
git diff --numstat origin/master...HEAD -- . ':(exclude).legion/**'
git diff origin/master...HEAD -- hosts/acorn/default.nix
test "$(git diff --name-only origin/master...HEAD -- . ':(exclude).legion/**')" = "hosts/acorn/default.nix"
test "$(git diff --numstat origin/master...HEAD -- . ':(exclude).legion/**')" = $'0\t1\thosts/acorn/default.nix'
git diff --exit-code origin/master...HEAD -- hosts/acorn/modules/oneex-portfolio-adapter.nix packages/oneex-portfolio-adapter hosts/acorn/secrets modules/agenix.nix
git diff --check origin/master...HEAD
nix-instantiate --parse hosts/acorn/default.nix >/dev/null
```

**PASS:** all assertions and exit-code checks returned zero. Excluding task evidence under `.legion`, the complete production diff is:

```text
M	hosts/acorn/default.nix
0	1	hosts/acorn/default.nix
```

The only production hunk retains upstream `./modules/cybion.nix` and removes only:

```diff
-    ./modules/oneex-portfolio-adapter.nix
```

The explicit prohibited-path comparison produced no diff, proving the adapter module, package snapshot, complete Acorn secrets directory, and global agenix module are unchanged versus `origin/master`. `git diff --check` and Nix parsing also exited zero.

No-cache evaluation commands on Axiom:
```sh
nix eval --impure --json --option eval-cache false --expr 'let flake = builtins.getFlake (toString ./.); config = flake.nixosConfigurations.acorn.config; in { adapterServicePresent = builtins.hasAttr "oneex-portfolio-adapter" config.systemd.services; adapterVhostPresent = builtins.hasAttr "1ex-portfolio.0xc1.wang" config.services.nginx.virtualHosts; adapterAgeSecretPresent = builtins.hasAttr "oneex-portfolio-adapter-env" config.age.secrets; }'
nix eval --impure --raw --option eval-cache false .#nixosConfigurations.acorn.config.system.build.toplevel.drvPath
```
**PASS:** `{"adapterAgeSecretPresent":true,"adapterServicePresent":false,"adapterVhostPresent":false}`.
**PASS:** toplevel `drvPath` was `/nix/store/k5j66f3x9c589lpmn5bibakfrn6l6awj-nixos-system-acorn-26.05.7813.0dd31db7e6db.drv`; this evaluated/instantiated but did not build the closure.

Read-only runtime command from Axiom:
```sh
ssh -o BatchMode=yes -o ConnectTimeout=10 c1@8.159.128.125 systemctl show oneex-portfolio-adapter.service --property=LoadState --property=ActiveState --property=SubState --no-pager
```
**PASS:** `LoadState=loaded`, `ActiveState=inactive`, `SubState=dead`. Loaded is expected before undeployment and confirms activation is still pending.

This was the only remote command. No Nix evaluation or build ran on Acorn, and no browser, 1Exchange, auth-mini, nginx endpoint, process, listener, or secret content was accessed.

## Pending Gates

- **PENDING:** Merge, refresh Axiom to the merged revision, and run the exact deployment command in `rfc.md`; stop on build, transfer, or activation failure, with no Acorn-local build.
- **PENDING:** Prove post-activation unit/process/TCP `8090`/active-vhost absence, no new failed unit, and unrelated-service health. The retained secret remains expected and unread.

## Blockers

None for the rebased pre-delivery candidate. Pending merge, deployment, and final runtime checks are required completion gates, not claims made by this report.

References: `rfc.md`, `research.md`, `review-rfc.md`, `review-change.md`, `../plan.md`, `../log.md`.

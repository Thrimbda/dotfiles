# Aliyun Acorn Vaultwarden ACME Staging Fix

## Task ID
`aliyun-acorn-vaultwarden-acme-staging-fix`

## Goal
Diagnose and fix `nixos-rebuild switch` hangs on low-resource `aliyun-acorn` after the Vaultwarden dual-run change, while preserving the staged Vaultwarden service and encrypted secret on the host.

## Problem
PR #111 added Vaultwarden to `aliyun-acorn`, after which `nixos-rebuild switch` appears to hang. Initial local evaluation showed the new `vault.0xc1.space` ACME units would be pulled into `nginx.service`, but live host inspection changed the diagnosis: the active machine has not switched to the Vaultwarden generation yet, so the observed hang is occurring before that activation state is reached.

Live evidence from `aliyun-acorn`:
- `/home/c1/dotfiles` is at `cf945a0c` (`feat(aliyun-acorn): add vaultwarden dual-run (#111)`).
- `/run/current-system` is still an older system path and `vaultwarden.service`, `acme-vault.0xc1.space.service`, and `acme-order-renew-vault.0xc1.space.service` are not present on the active system.
- The only failed unit is `acme-order-renew-status-axiom.0xc1.wang.service`; it fails quickly because Let's Encrypt sees `status-axiom.0xc1.wang` as DNS NXDOMAIN.
- A safe remote `nix build --dry-run --no-link` against the PR #111 checkout produced no output for three minutes and timed out from this client. Subsequent SSH attempts timed out during banner exchange, suggesting the host is resource-constrained or overloaded during Nix evaluation/build/download, rather than blocked inside systemd activation.

## Acceptance
- Root cause is based on live host evidence, not only local Nix evaluation.
- `aliyun-acorn` can build the PR #111 system without exhausting or wedging the host.
- If activation is reached, Vaultwarden service, agenix secret ownership, and local nginx reverse proxy routes remain configured for staged testing.
- If `vault.0xc1.space` ACME is still unsafe during staging, the generated `nginx.service` no longer wants or waits for `acme-vault.0xc1.space.service`.
- Existing `status-axiom.0xc1.wang` ACME behavior is handled explicitly: either left unchanged with rationale or fixed as a separate directly related DNS/ACME readiness issue.
- Development, desktop/media, Docker, and generic graphical compatibility packages are removed from `aliyun-acorn` unless required by the server role.
- SSH remains responsive under load by avoiding socket-activated per-connection `sshd` startup.

## Scope
- Update `hosts/aliyun-acorn/modules/vaultwarden.nix` only, unless validation exposes a directly related blocker.
- Update `hosts/aliyun-acorn/default.nix` if live diagnosis confirms the host needs a smaller server profile or SSH service behavior changes.
- Update Legion task docs, verification, review, walkthrough, and wiki evidence.

## Non-goals
- Do not remove the Vaultwarden service or `vaultwarden-env.age` secret from `aliyun-acorn`.
- Do not change DNS, ACME account settings, Vaultwarden credentials, or data migration behavior.
- Do not deploy or run `nixos-rebuild switch` from this environment.
- Do not alter the existing `acorn` Vaultwarden deployment.
- Do not keep development or desktop/media tooling on `aliyun-acorn`; it is not intended for development or desktop use.

## Assumptions
- `vault.0xc1.space` may not be ready to issue ACME on `aliyun-acorn` yet, but this is not currently proven to be the observed hang source.
- The current hang is more likely in Nix evaluation/build/download or host resource pressure before activation.
- The failed `status-axiom.0xc1.wang` ACME unit is a real configuration problem but failed quickly in live logs; it is not yet proven to be the hang source.

## Constraints
- Follow Legion workflow and use the `git-worktree-pr` envelope for production config changes.
- Keep the fix minimal and reversible.
- Do not expose or modify Vaultwarden secret contents.

## Risks
- Temporarily disabling TLS/ACME on the staged vhost means `vault.0xc1.space` must not be treated as production-ready on `aliyun-acorn` until a cutover task re-enables TLS and validates DNS/ACME.
- If traffic is already pointed at `aliyun-acorn`, HTTP-only exposure would be unsafe; this task assumes staging state and no production traffic cutover.

## Design Summary
- Slim `aliyun-acorn` to the services it actually needs: SSH, fail2ban, frps, nginx, Vaultwarden, and small shell/editor tooling.
- Remove development runtimes/toolchains, media downloader/player tooling, Docker, host-level `nix-ld` graphical compatibility libraries, and local documentation outputs.
- Limit on-host Nix concurrency so accidental local builds/downloads do not saturate the small machine.
- Run `sshd` as a normal daemon instead of socket activation, because live logs showed many per-connection `sshd` units and banner timeouts under load.
- Pause ACME for both staged/unready nginx vhosts until DNS/cutover is ready; this removes activation-time ACME jobs and daily failed certificate attempts.

## Phases
1. Materialize this follow-up contract.
2. Open the required worktree/PR envelope.
3. Confirm whether hang is in build/download/evaluation or activation.
4. Apply the minimal confirmed fix.
5. Review, walkthrough, wiki writeback, PR, and cleanup.
